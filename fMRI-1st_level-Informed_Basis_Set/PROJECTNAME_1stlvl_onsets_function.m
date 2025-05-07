function PROJECTNAME_1stlvl_onsets_function(model_name, subject_idx, modelling_data, subject_dir, save_path, project_path, varargin)
% GENERIC_FMRI_ONSETS_FUNCTION - Creates onsets for fMRI analysis
%
% Inputs:
%   model_name      : Name of the model (determines onset structure)
%   subject_idx     : Index of current subject
%   modelling_data  : Behavioral/modeling data for parametric modulations
%   subject_dir     : Directory for subject data
%   save_path       : Path to save onset files
%   project_path    : Root path of the project
%   varargin        : Optional parameters (see parseInputs below)
%
% Outputs:
%   Saves onset files for each run/block in specified directory
%
% Key Features:
%   - Supports multiple model types (Basic/Advanced/Custom)
%   - Handles successful and missed trials
%   - Allows for parametric modulations
%   - Configurable through input parameters

%% Parse optional inputs
params = parseInputs(varargin);

%% Initialize
[all_time_events, all_data] = loadSubjectData(subject_dir, project_path, params);

% Define onset names based on model configuration
onset_names = defineOnsetNames(params);

%% Process each block/run
for block_idx = 1:params.num_blocks
    time_events = all_time_events(block_idx).block;
    data = all_data(block_idx).block;
    
    % Select which onsets to process based on model type
    onset_indices = selectOnsetIndices(model_name, params);
    
    % Process trials (successful and missed)
    [onsets, durations, names] = processTrials(time_events, onset_names, onset_indices, params);
    
    % Initialize orthogonalization array
    orth = repmat({0}, 1, length(names));
    
    % Handle custom model variations
    [onsets, durations, names] = processCustomOnsets(...
        model_name, time_events, data, onsets, durations, names, params);
    
    % Calculate parametric modulations if needed
    if params.include_pmods
        pmod = calculateParametricModulations(...
            model_name, modelling_data, data, time_events, ...
            subject_idx, block_idx, names, params);
    else
        pmod = struct([]);
    end
    
    % Save onset file
    saveOnsetFile(save_path, subject_dir, block_idx, onsets, durations, pmod, names, orth);
end
end

%% Helper Functions
function params = parseInputs(inputs)
% Set default parameters
params = struct();
params.num_blocks = 2;                  % Default number of blocks/runs
params.include_pmods = true;            % Include parametric modulations
params.success_onset_names = {};        % Will be set in defineOnsetNames
params.missed_onset_names = {};         % Will be set in defineOnsetNames
params.custom_onset_handlers = struct(); % For custom model variations
params.data_file_pattern = '*.csv';     % Pattern for behavioral data files
params.time_events_pattern = '*.txt';   % Pattern for timing files

% Process varargin
for i = 1:2:length(inputs)
    param_name = inputs{i};
    param_value = inputs{i+1};
    params.(param_name) = param_value;
end
end

function [all_time_events, all_data] = loadSubjectData(subject_dir, project_path, params)
for block = 1:params.num_blocks
    % Find and load timing data
    time_events_file = dir(fullfile(project_path, subject_dir, ...
        sprintf('*_block%d_%s', block, params.time_events_pattern)));
    time_events = readtable(fullfile(time_events_file.folder, time_events_file.name), ...
        'Delimiter', '\t', 'ReadVariableNames', true);
    
    % Find and load behavioral data
    data_file = dir(fullfile(project_path, subject_dir, ...
        sprintf('*_block%d_%s', block, params.data_file_pattern)));
    data = readtable(fullfile(data_file.folder, data_file.name), ...
        'PreserveVariableNames', true);
    
    % Store in output structure
    all_time_events(block).block = time_events;
    all_data(block).block = data;
end
end

function onset_names = defineOnsetNames(params)
% Define names for successful trials
if isempty(params.success_onset_names)
    % Default names if not provided
    onset_names.success = {'Fixation', 'Event1_presentation', 'Event1_response', ...
        'Event2_presentation', 'Event2_response', 'Feedback'};
else
    onset_names.success = params.success_onset_names;
end

% Define names for missed trials
if isempty(params.missed_onset_names)
    % Default names if not provided
    onset_names.miss_type1 = {'FixationTimeout', 'Event1_presTimeout', ...
        'Event1_RespTimeout', 'FeedbackTimeout'};
    onset_names.miss_type2 = {'FixationTimeout', 'Event1_presTimeout', ...
        'Event1_RespTimeout', 'Event2_presTimeout', 'Event2_respTimeout', 'FeedbackTimeout'};
else
    onset_names.missed = params.missed_onset_names;
end
end

function onset_indices = selectOnsetIndices(model_name, params)
% Determine which onsets to include based on model type
if contains(model_name, 'Basic') || contains(model_name, 'Custom')
    onset_indices = 1:6; % Full set of onsets
else
    onset_indices = [1 2 4 6]; % Reduced set (e.g., without responses)
end
end

function [onsets, durations, names] = processTrials(time_events, onset_names, onset_indices, params)
% Process successful trials
[onsets, durations, names] = processSuccessfulTrials(time_events, onset_names, onset_indices, params);

% Process missed trials
[onsets, durations, names] = processMissedTrials(time_events, onset_names, onset_indices, onsets, durations, names, params);
end

function [onsets, durations, names] = processSuccessfulTrials(time_events, onset_names, onset_indices, params)
time_event_fields = time_events.Properties.VariableNames(onset_indices);
onsets = cell(1, length(time_event_fields));
durations = cell(1, length(time_event_fields));
names = onset_names.success(1:length(time_event_fields));

for i = 1:length(time_event_fields)
    field_name = time_event_fields{i};
    valid_indices = ~isnan(time_events.(field_name));
    onsets{i} = time_events.(field_name)(valid_indices) / 1000; % Convert ms to s
    
    % Calculate duration based on event type
    durations{i} = calculateEventDuration(time_events, field_name, i, length(time_event_fields), params);
end
end

function duration = calculateEventDuration(time_events, field_name, current_idx, total_events, params)
% This should be customized based on your specific timing structure
% Here's a generic implementation that can be adapted

if isfield(params, 'fixed_durations') && isfield(params.fixed_durations, field_name)
    % Use predefined fixed duration
    duration = params.fixed_durations.(field_name) * ones(sum(~isnan(time_events.(field_name))), 1);
else
    % Calculate duration based on next event
    if current_idx < total_events
        next_field = time_events.Properties.VariableNames{current_idx + 1};
        duration = (time_events.(next_field) - time_events.(field_name)) / 1000;
    else
        % Last event - use default duration
        duration = 0;
    end
end
end

function [onsets, durations, names] = processMissedTrials(time_events, onset_names, onset_indices, onsets, durations, names, params)
% Identify missed trial fields
missed_fields = setdiff(time_events.Properties.VariableNames, time_events.Properties.VariableNames(onset_indices), 'stable');

if ~isempty(missed_fields)
    if length(missed_fields) == 4
        [onsets, durations, names] = processSpecificMissedTrials(...
            time_events, onset_names.miss_type1, missed_fields, onsets, durations, names, params);
    elseif length(missed_fields) == 6
        [onsets, durations, names] = processSpecificMissedTrials(...
            time_events, onset_names.miss_type2, missed_fields, onsets, durations, names, params);
    end
end
end

function [onsets, durations, names] = processSpecificMissedTrials(time_events, miss_names, miss_fields, onsets, durations, names, params)
for i = 1:length(miss_fields)
    field_name = miss_fields{i};
    valid_indices = ~isnan(time_events.(field_name));
    
    if any(valid_indices)
        onsets{end+1} = time_events.(field_name)(valid_indices) / 1000;
        
        % Calculate duration - this should be customized based on your timing structure
        switch i
            case 1
                duration = (time_events.(miss_fields{2})(valid_indices) - ...
                    time_events.(field_name)(valid_indices)) / 1000;
            case 2
                duration = (time_events.(miss_fields{3})(valid_indices) - ...
                    time_events.(field_name)(valid_indices)) / 1000;
            otherwise
                duration = 0;
        end
        
        durations{end+1} = duration;
        names{end+1} = miss_names{i};
    end
end
end

function [onsets, durations, names] = processCustomOnsets(model_name, time_events, data, onsets, durations, names, params)
% Check if custom handlers are provided for this model
if isfield(params.custom_onset_handlers, model_name)
    handler = params.custom_onset_handlers.(model_name);
    [onsets, durations, names] = handler(time_events, data, onsets, durations, names);
    return;
end

% Default custom onset handlers (can be overridden through params)
if contains(model_name, 'Custom')
    % Example: Handle feedback differentiation
    if contains(model_name, 'FeedbackTypes')
        feedback_onset = time_events.Feedback(~isnan(time_events.Feedback)) / 1000;
        feedback_type = data.feedback_type; % Assuming this field exists
        
        % Replace generic feedback with specific types
        names{end} = 'Feedback_TypeA';
        onsets{end} = feedback_onset(feedback_type == 1);
        durations{end} = params.fixed_durations.Feedback * ones(sum(feedback_type == 1), 1);
        
        names{end+1} = 'Feedback_TypeB';
        onsets{end+1} = feedback_onset(feedback_type == 2);
        durations{end+1} = params.fixed_durations.Feedback * ones(sum(feedback_type == 2), 1);
    end
    
    % Add more custom handlers as needed
end
end

function pmod = calculateParametricModulations(model_name, modelling_data, data, time_events, subject_idx, block_idx, names, params)
if ~params.include_pmods
    pmod = struct([]);
    return;
end

% Preallocate pmod structure
pmod(length(names)) = struct('name', [], 'param', [], 'poly', []);

% Get behavioral and model metrics
[behavior, model_params] = getBehavioralMetrics(data, time_events, params);
model_metrics = getModelMetrics(modelling_data, subject_idx, block_idx, params);

% Apply parametric modulations based on model type
if contains(model_name, 'Basic')
    pmod = applyBasicModulations(pmod, behavior, model_metrics, params);
elseif contains(model_name, 'Custom')
    pmod = applyCustomModulations(pmod, behavior, model_metrics, model_name, params);
end
end

function [behavior, model_params] = getBehavioralMetrics(data, time_events, params)
% Extract relevant behavioral metrics
behavior = struct();

% Example metrics - should be customized based on your data
if isfield(data, 'response_value')
    behavior.response = data.response_value;
    behavior.response_time = (time_events.ResponseEnd - time_events.ResponseStart) / 1000;
end

% Add more behavioral metrics as needed
end

function model_metrics = getModelMetrics(modelling_data, subject_idx, block_idx, params)
% Extract model-based metrics
model_metrics = struct();

% Example metrics - should be customized based on your modelling data
if isfield(modelling_data, 'block1') && isfield(modelling_data, 'block2')
    block_field = sprintf('block%d', block_idx);
    model_metrics.param1 = modelling_data.(block_field).param1(subject_idx, :);
    model_metrics.param2 = modelling_data.(block_field).param2(subject_idx, :);
end

% Add more model metrics as needed
end

function pmod = applyBasicModulations(pmod, behavior, model_metrics, params)
% Apply basic parametric modulations
% This should be customized based on your specific needs

% Example: Modulate first event with response values
if isfield(behavior, 'response')
    pmod(2).name = {'response'};
    pmod(2).param = {behavior.response};
    pmod(2).poly = {1};
end

% Add more basic modulations as needed
end

function pmod = applyCustomModulations(pmod, behavior, model_metrics, model_name, params)
% Apply custom parametric modulations based on model type

% Example: Different modulations for different event types
if contains(model_name, 'FeedbackTypes')
    pmod(end-1).name = {'param1'}; % For Feedback_TypeA
    pmod(end-1).param = {model_metrics.param1};
    pmod(end-1).poly = {1};
    
    pmod(end).name = {'param2'}; % For Feedback_TypeB
    pmod(end).param = {model_metrics.param2};
    pmod(end).poly = {1};
end

% Add more custom modulation patterns as needed
end

function saveOnsetFile(save_path, subject_dir, block_idx, onsets, durations, pmod, names, orth)
run_file_name = sprintf('%s_RUN%d.mat', subject_dir, block_idx);
save_file_path = fullfile(save_path, run_file_name);
save(save_file_path, 'onsets', 'durations', 'pmod', 'names', 'orth');
end