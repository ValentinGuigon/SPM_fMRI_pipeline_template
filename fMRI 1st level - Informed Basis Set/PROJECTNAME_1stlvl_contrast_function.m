function subject_vectors = PROJECTNAME_1stlvl_contrast_function(model_name, subject_idx, contrast_params, glm_path, subject_dirs, varargin)
% GENERIC_CONTRAST_FUNCTION - Creates first-level fMRI contrasts
%
% Inputs:
%   model_name      : Name of the analysis model
%   subject_idx     : Index of current subject
%   contrast_params : Parameters for contrast creation
%   glm_path        : Path to GLM results
%   subject_dirs    : Subject directories
%   varargin        : Optional parameters (see parseInputs below)
%
% Outputs:
%   subject_vectors : Structure containing contrast vectors
%
% Key Features:
%   - Supports multiple model types (Basic/Advanced/Custom)
%   - Handles parametric modulations if specified
%   - Generates HRF derivatives
%   - Configurable through input parameters

%% Parse optional inputs
params = parseInputs(varargin);

%% Initialize
% Load SPM.mat for this subject
subject_path = fullfile(glm_path, subject_dirs(subject_idx).name);
spm_file = load(fullfile(subject_path, 'SPM.mat'));
spm_struct = spm_file.SPM;

% Initialize SPM batch
batch = init_spm_batch(subject_path);

% Process session data
[session_data, param_names, miss_trials] = process_sessions(spm_struct);

% Determine relevant session and contrast flag
[relevant_session, contrast_flag] = select_relevant_session(model_name, session_data, contrast_params);

% Get events and their names for contrasts
[event_names, events] = get_contrast_events(model_name, session_data, contrast_flag);

% Generate contrast names to perform
contrasts_to_perform = generate_contrast_names(model_name, events, params);

% Create contrast vectors
[batch, subject_vectors] = create_contrast_vectors(...
    batch, subject_idx, model_name, contrasts_to_perform, ...
    event_names, contrast_flag, param_names, events, params);

% Create HRF contrasts if requested
if params.generate_hrf
    batch = create_hrf_contrasts(batch, subject_vectors);
end

% Save and execute contrasts
save_contrast_data(glm_path, batch);

if ~params.dry_run
    spm_jobman('run', {batch.matlabbatch});
end
end

%% Helper Functions
function params = parseInputs(inputs)
% Set default parameters
params = struct();
params.generate_hrf = true;       % Generate HRF derivatives
params.dry_run = false;           % Don't execute SPM job if true
params.custom_events = {};        % Custom event names if needed
params.contrast_patterns = struct(); % Custom contrast patterns
params.miss_trial_handling = 'default'; % How to handle missed trials

% Process varargin
for i = 1:2:length(inputs)
    param_name = inputs{i};
    param_value = inputs{i+1};
    params.(param_name) = param_value;
end
end

function batch = init_spm_batch(subject_path)
batch.matlabbatch{1}.spm.stats.con.spmmat = {fullfile(subject_path,'SPM.mat')};
batch.matlabbatch{1}.spm.stats.con.delete = 1;
end

function [session_data, param_names, miss_trials] = process_sessions(spm_struct)
for sess = 1:length(spm_struct.Sess)
    session_data(sess).all_names = arrayfun(@(x) x.name, spm_struct.Sess(sess).U, 'UniformOutput', false);
    session_data(sess).all_names = [session_data(sess).all_names{:}];
    
    param_names = spm_struct.xX.name;
    
    % Handle missed trials based on presence of certain events
    miss_trials(sess).miss_vec = zeros(1, 10 + ...
        2*any(contains(session_data(sess).all_names, 'Event2_presTimeout')));
end
end

function [relevant_session, contrast_flag] = select_relevant_session(model_name, session_data, contrast_params)
if contains(model_name, 'Condition2') 
    relevant_session = 2; % Models with session-specific effects
else
    relevant_session = 1; 
end

if any(contains(session_data(relevant_session).all_names, 'ParametricMod')) && contrast_params ~= 0
    contrast_flag = 'ParametricMod'; 
else
    contrast_flag = ''; 
end
end

function [event_names, events] = get_contrast_events(model_name, session_data, contrast_flag)
if contains(model_name, 'Basic')
    events = {
        'Fixation'; 'Event1_presentation'; 'Event1_response';
        'Event2_presentation'; 'Event2_response'; 'Feedback';
    };
elseif contains(model_name, 'Custom')
    if contains(model_name, 'FeedbackTypes')
        events = {'TypeA', 'TypeB'};
    elseif contains(model_name, 'JudgmentTypes')
        events = {'Type1', 'Type2'};
    elseif contains(model_name, 'ChoiceTypes')
        events = {'ChoiceA', 'ChoiceB'};
    end
end

if contains(model_name, 'Parametric') && ~contains(model_name, 'Condition2')
    event_names = get_parametric_event_names(session_data, events, contrast_flag);
else
    event_names = events;
end
end

function event_names = get_parametric_event_names(session_data, events, contrast_flag)
event_names = [];
for ii = 1:length(events)
    idx = find(contains(session_data(1).all_names, events{ii}) & ...
          contains(session_data(1).all_names, contrast_flag));
    event_names = [event_names, session_data(1).all_names(idx(1))];
end
end

function contrasts_to_perform = generate_contrast_names(model_name, events, params)
if contains(model_name, 'Basic')
    contrasts_to_perform = generate_basic_contrasts(events);
elseif contains(model_name, 'Custom')
    event1 = lower(events{1}); 
    event2 = lower(events{2});
    
    if isfield(params.contrast_patterns, model_name)
        contrasts_to_perform = params.contrast_patterns.(model_name);
    else
        contrasts_to_perform = generate_default_custom_contrasts(event1, event2);
    end
end
end

function contrasts = generate_basic_contrasts(events)
contrasts = {};
for ct_type = {'main', '2v1', '1v2'} 
    new_ct = arrayfun(@(x) sprintf('%s_%s', x{1}, ct_type{1}), events, 'UniformOutput', false);
    contrasts = [contrasts; new_ct'];
end
end

function contrasts = generate_default_custom_contrasts(event1, event2)
contrasts = {
    sprintf('%s_main', event1); sprintf('%s_main', event2);
    sprintf('%s_ctrl', event1); sprintf('%s_ctrl', event2);
    sprintf('%s_cond2', event1); sprintf('%s_cond2', event2);
    sprintf('%s%s_main', event1, event2);
    sprintf('%s%s_ctrl', event1, event2); sprintf('%s%s_cond2', event1, event2); 
    sprintf('%s%s_1v2', event1, event2); sprintf('%s%s_2v1', event1, event2)
    sprintf('%s_2v1', event1); sprintf('%s_2v1', event2);
    sprintf('%s_1v2', event1); sprintf('%s_1v2', event2);
    sprintf('%sVS%s_main', event1, event2); sprintf('%sVS%s_main', event2, event1);
    sprintf('%sVS%s_ctrl', event1, event2); sprintf('%sVS%s_ctrl', event2, event1);
    sprintf('%sVS%s_cond2', event1, event2); sprintf('%sVS%s_cond2', event2, event1);
};
end

function [batch, subject_vectors] = create_contrast_vectors(...
    batch, subject_idx, model_name, contrasts_to_perform, ...
    event_names, contrast_flag, param_names, events, params)

event_param_names = get_event_parameters(param_names, event_names, contrast_flag);
param_indices = find_parameter_indices(param_names, event_param_names, event_names);

for ct_idx = 1:length(contrasts_to_perform)
    ct_name = contrasts_to_perform{ct_idx};
    
    subject_vectors.contrast(ct_idx).vec = array2table(...
        zeros(1, length(param_names)), 'VariableNames', param_names);
    subject_vectors.contrast(ct_idx).k = [];
    
    subject_vectors = fill_contrast_vector(...
        subject_vectors, subject_idx, model_name, ct_name, ...
        events, param_indices, ct_idx, params);
    
    batch.matlabbatch{1}.spm.stats.con.consess{ct_idx}.tcon.name = ct_name;
    batch.matlabbatch{1}.spm.stats.con.consess{ct_idx}.tcon.weights = ...
        table2array(subject_vectors.contrast(ct_idx).vec);
    batch.matlabbatch{1}.spm.stats.con.consess{ct_idx}.tcon.sessrep = 'none';
end
end

function event_param_names = get_event_parameters(param_names, event_names, contrast_flag)
event_param_names = {};
for sess = 1:2
    sess_params = param_names(contains(param_names, ['Sn(', num2str(sess), ')']));
    
    if any(contains(sess_params, contrast_flag))
        conditions = contains(sess_params, event_names) & ...
                    contains(sess_params, 'bf(1)') & ...
                    contains(sess_params, contrast_flag);
    else
        conditions = contains(sess_params, event_names) & ...
                    contains(sess_params, 'bf(1)') & ...
                    ~contains(sess_params, '^');
    end
    
    event_param_names = [event_param_names, sess_params(conditions)];
end
end

function param_indices = find_parameter_indices(param_names, event_param_names, event_names)
patterns = {'Sn(1)', 'Sn(2)', event_names{1}, event_names{2}};
fields = {'ctrl', 'cond2', 'event1', 'event2'};
param_indices = struct();

for i = 1:length(fields)
    param_indices.(fields{i}) = find(...
        contains(param_names, event_param_names) & ...
        contains(param_names, patterns{i}));
end

for i = 1:2
    for j = 1:2
        field_name = sprintf('event%d_%s', i, fields{j});
        param_indices.(field_name) = intersect(...
            param_indices.(sprintf('event%d', i)), ...
            param_indices.(fields{j}));
    end
end
end

function subject_vectors = fill_contrast_vector(...
    subject_vectors, subject_idx, model_name, ct_name, ...
    events, param_indices, ct_idx, params)

if contains(model_name, 'Basic')
    match_idx = cellfun(@(x) contains(ct_name, x), events);
    event = events(match_idx);
    contrast_patterns = get_basic_contrast_patterns(event);
    
    param_indices = rmfield(param_indices, setdiff(...
        fieldnames(param_indices), {'ctrl', 'cond2'}));
    param_indices = structfun(@(x) x(find(match_idx)), ...
        param_indices, 'UniformOutput', false); 
elseif contains(model_name, 'Custom')
    event1 = lower(events{1}); 
    event2 = lower(events{2});
    contrast_patterns = get_custom_contrast_patterns(event1, event2);
end

contrast_vec = subject_vectors.contrast(ct_idx).vec;
activated_events = {};
activation_values = [];

subject_vectors.contrast(ct_idx).contrast_name = ct_name;

for jj = 1:size(contrast_patterns, 1)
    if contains(ct_name, contrast_patterns{jj, 1})
        [contrast_vec, vector_events, values] = ...
            apply_contrast_pattern(...
                contrast_vec, param_indices, contrast_patterns{jj, 2});
        activated_events = [activated_events, vector_events];
        activation_values = [activation_values, values];
        break;
    end
end

subject_vectors.contrast(ct_idx).vec = contrast_vec;
subject_vectors.contrast(ct_idx).k = find(table2array(contrast_vec) ~= 0);
subject_vectors.contrast(ct_idx).events = strjoin(activated_events, ', ');
subject_vectors.contrast(ct_idx).activation = activation_values;
end

function [vec, events, values] = apply_contrast_pattern(vec, params_idx, pattern)
fields = pattern{1};
values = pattern{2};
events = strings(1, numel(fields));

for i = 1:length(fields)
    vec{1, params_idx.(fields{i})} = values(i);
    events(i) = fields{i};
end
end

function contrast_patterns = get_basic_contrast_patterns(event)
contrast_patterns = {
    strcat(event, '_main'),       {{'ctrl', 'cond2'}, [1, 1]};
    strcat(event, '_2v1'),        {{'ctrl', 'cond2'}, [-1, 1]};
    strcat(event, '_1v2'),        {{'ctrl', 'cond2'}, [1, -1]};
};
end

function contrast_patterns = get_custom_contrast_patterns(event1, event2)
contrast_patterns = {
    strcat(event1, 'VS', event2, '_main'), {{'event1', 'event2'}, [1, -1]};
    strcat(event2, 'VS', event1, '_main'), {{'event1', 'event2'}, [-1, 1]};
    strcat(event1, 'VS', event2, '_ctrl'), {{'event1_ctrl', 'event2_ctrl'}, [1, -1]};
    strcat(event2, 'VS', event1, '_ctrl'), {{'event1_ctrl', 'event2_ctrl'}, [-1, 1]};
    strcat(event1, 'VS', event2, '_cond2'), {{'event1_cond2', 'event2_cond2'}, [1, -1]};
    strcat(event2, 'VS', event1, '_cond2'), {{'event1_cond2', 'event2_cond2'}, [-1, 1]};
    strcat(event1, event2, '_main'), {{'event1_ctrl', 'event1_cond2', 'event2_ctrl', 'event2_cond2'}, [1, 1, 1, 1]};
    strcat(event1, event2, '_ctrl'), {{'event1_ctrl', 'event2_ctrl'}, [1, 1]};
    strcat(event1, event2, '_cond2'), {{'event1_cond2', 'event2_cond2'}, [1, 1]};
    strcat(event1, '_main'), {{'event1_ctrl', 'event1_cond2'}, [1, 1]};
    strcat(event2, '_main'), {{'event2_ctrl', 'event2_cond2'}, [1, 1]};
    strcat(event1, '_ctrl'), {{'event1_ctrl'}, 1};
    strcat(event2, '_ctrl'), {{'event2_ctrl'}, 1};
    strcat(event1, '_cond2'), {{'event1_cond2'}, 1};
    strcat(event2, '_cond2'), {{'event2_cond2'}, 1};
    strcat(event1, '_2v1'), {{'event1_ctrl', 'event1_cond2'}, [-1, 1]};
    strcat(event2, '_2v1'), {{'event2_ctrl', 'event2_cond2'}, [-1, 1]};
    strcat(event1, '_1v2'), {{'event1_ctrl', 'event1_cond2'}, [1, -1]};
    strcat(event2, '_1v2'), {{'event2_ctrl', 'event2_cond2'}, [1, -1]};
};
end

function batch = create_hrf_contrasts(batch, subject_vectors)
i = length(batch.matlabbatch{1}.spm.stats.con.consess) + 1;
for ii = 1:length(subject_vectors.contrast)
    contrast_vec = table2array(subject_vectors.contrast(ii).vec);
    contrast_name = subject_vectors.contrast(ii).contrast_name;
    idx = find(contrast_vec ~= 0);
    
    hrf = zeros(3, length(contrast_vec));
    hrf(1, :) = contrast_vec;
    if ~isempty(idx)
        hrf(2, idx + 1) = contrast_vec(idx);
        hrf(3, idx + 2) = contrast_vec(idx);
    end
    
    for hrf_idx = 1:3
        batch.matlabbatch{1}.spm.stats.con.consess{i}.tcon.name = ...
            sprintf('%s_HRF%d', contrast_name, hrf_idx);
        batch.matlabbatch{1}.spm.stats.con.consess{i}.tcon.weights = hrf(hrf_idx, :);
        batch.matlabbatch{1}.spm.stats.con.consess{i}.tcon.sessrep = 'none';
        i = i + 1;
    end
end
end

function save_contrast_data(glm_path, batch)
contrast_names = arrayfun(@(x) x.tcon.name, ...
    batch.matlabbatch{1}.spm.stats.con.consess, 'UniformOutput', false);
save(fullfile(glm_path, 'ContrastNames.mat'), 'contrast_names');
end