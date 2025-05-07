function PROJECTNAME_2ndlvl_full_job(varargin)
% RUN_SECOND_LEVEL_ANALYSIS - Configures and runs second-level fMRI analysis
%
% Inputs (optional name-value pairs):
%   'model_names'       : Cell array of model names to analyze
%   'model_ids'         : Numeric IDs of models to run
%   'analysis_folder'   : Name for output folder
%   'project_settings'  : Function handle to get project settings
%   'excluded_subjects' : Subjects to exclude for specific models
%   'dry_run'           : If true, only setup without running SPM

%% Parse inputs
params = parse_inputs(varargin{:});

%% Initialize
% Get project settings
[project_settings, project_paths] = initialize_project(params);

% Select models to process
selected_models = select_models(params, project_settings.model_list);

%% Process Models
for model_idx = 1:length(selected_models)
    current_model = selected_models{model_idx};
    fprintf('Processing Model: %s\n', current_model);
    
    % Handle subject exclusions
    subject_list = handle_subject_exclusions(params, current_model, project_settings.subj_list);
    
    % Set up model paths
    model_paths = setup_model_paths(project_paths, current_model);
    
    % Load contrast names
    contrast_names = load_contrast_names(model_paths.first_level);
    
    % Process each contrast
    process_contrasts(params, model_paths, contrast_names, subject_list);
end
end

%% Helper Functions
function params = parse_inputs(varargin)
p = inputParser;
addParameter(p, 'model_names', {}, @iscell);
addParameter(p, 'model_ids', [], @isnumeric);
addParameter(p, 'analysis_folder', 'analysis', @ischar);
addParameter(p, 'project_settings', @get_fmri_settings, @(x) isa(x, 'function_handle'));
addParameter(p, 'excluded_subjects', struct(), @isstruct);
addParameter(p, 'dry_run', false, @islogical);
parse(p, varargin{:});
params = p.Results;
end

function [settings_func, paths] = initialize_project(params)
% Get project settings using provided function
[paths.root, paths.fmri, paths.first_lvl_base, paths.second_lvl_base, ...
    settings_func.model_list, settings_func.subj_list] = ...
    params.project_settings({'projectRoot', 'FMRI_PROJECT_PATH', ...
    'FIRST_LVL_PATH', 'SECOND_LVL_PATH', 'ModelList', 'SUBJ_LIST'});

% Set analysis paths
paths.first_level = fullfile(paths.first_lvl_base, params.analysis_folder);
paths.second_level = fullfile(paths.second_lvl_base, params.analysis_folder);

% Create directories if needed
if ~exist(paths.first_level, 'dir')
    mkdir(paths.first_level);
end
if ~exist(paths.second_level, 'dir')
    mkdir(paths.second_level);
end
end

function selected_models = select_models(params, model_list)
if ~isempty(params.model_names)
    selected_models = params.model_names;
elseif ~isempty(params.model_ids)
    model_ids = arrayfun(@(x) sprintf('%03d', x), params.model_ids, 'UniformOutput', false);
    selected_models = model_list(contains(model_list, strcat(model_ids, ' - ')));
else
    selected_models = model_list;
end
end

function subject_list = handle_subject_exclusions(params, model_name, full_list)
subject_list = full_list;
if isfield(params.excluded_subjects, model_name)
    subject_list = full_list(~ismember(full_list, params.excluded_subjects.(model_name)));
end
end

function model_paths = setup_model_paths(project_paths, model_name)
model_paths.first_level = fullfile(project_paths.first_level, model_name);
model_paths.second_level = fullfile(project_paths.second_level, model_name);

if ~exist(model_paths.second_level, 'dir')
    mkdir(model_paths.second_level);
end
end

function contrast_names = load_contrast_names(first_level_path)
contrast_file = fullfile(first_level_path, 'Name_ct_full.mat');
if exist(contrast_file, 'file')
    load(contrast_file, 'Name_ct_full');
    contrast_names = Name_ct_full;
else
    error('Contrast names file not found: %s', contrast_file);
end
end

function process_contrasts(params, model_paths, contrast_names, subject_list)
subject_dirs = get_subject_directories(params.project_settings);

for contrast_num = 1:3:length(contrast_names)
    current_contrast = contrast_names{contrast_num};
    fprintf('  Processing contrast: %s\n', current_contrast);
    
    % Setup contrast directory
    contrast_dir = setup_contrast_directory(model_paths.second_level, current_contrast);
    
    % Get contrast files
    contrast_files = get_contrast_files(...
        subject_dirs, model_paths.first_level, subject_list, contrast_num);
    
    if params.dry_run
        fprintf('    Dry run - would process %d subjects\n', length(subject_list));
        continue;
    end
    
    % Configure and run SPM job
    try
        matlabbatch = configure_spm_job(contrast_dir, current_contrast, contrast_files);
        spm_jobman('run', matlabbatch);
    catch ME
        fprintf('Error processing contrast %s: %s\n', current_contrast, ME.message);
    end
end
end

function subject_dirs = get_subject_directories(settings_func)
[~, fmri_path] = settings_func({'FMRI_PROJECT_PATH'});
subject_dirs = dir(fullfile(fmri_path, '*_*')); % Pattern for subject directories
end

function contrast_dir = setup_contrast_directory(base_path, contrast_name)
contrast_dir = fullfile(base_path, contrast_name);
if exist(contrast_dir, 'dir')
    rmdir(contrast_dir, 's');
end
mkdir(contrast_dir);
end

function contrast_files = get_contrast_files(subject_dirs, first_level_path, subject_list, contrast_num)
contrast_files.HRF1 = cell(length(subject_list), 1);
contrast_files.HRF2 = cell(length(subject_list), 1);
contrast_files.HRF3 = cell(length(subject_list), 1);

for subj_idx = 1:length(subject_list)
    subj_dir = subject_dirs(subject_list(subj_idx)).name;
    subj_path = fullfile(first_level_path, subj_dir);
    
    contrast_files.HRF1{subj_idx} = fullfile(subj_path, sprintf('con_%04d.nii', contrast_num));
    contrast_files.HRF2{subj_idx} = fullfile(subj_path, sprintf('con_%04d.nii', contrast_num + 1));
    contrast_files.HRF3{subj_idx} = fullfile(subj_path, sprintf('con_%04d.nii', contrast_num + 2));
end
end

function matlabbatch = configure_spm_job(contrast_dir, contrast_name, contrast_files)
% Factorial design specification
matlabbatch{1}.spm.stats.factorial_design.dir = {contrast_dir};
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.name = contrast_name;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.levels = 3;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.dept = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.ancova = 0;

% Cell specifications for each HRF
for hrf = 1:3
    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(hrf).levels = hrf;
    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(hrf).scans = ...
        contrast_files.(sprintf('HRF%d', hrf));
end
matlabbatch{1}.spm.stats.factorial_design.des.fd.contrasts = 1;

% Model estimation
matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(contrast_dir, 'SPM.mat')};
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

% Contrast manager
matlabbatch{3}.spm.stats.con.spmmat = {fullfile(contrast_dir, 'SPM.mat')};

% Define standard contrasts
contrasts = {
    {'F_test', eye(3), 'fcon'}, ...
    {contrast_name, [1 1 1], 'tcon'}, ...
    {['Inv_' contrast_name], [-1 -1 -1], 'tcon'}, ...
    {['canonHRF_' contrast_name], [1 0 0], 'tcon'}, ...
    {['Inv_canonHRF_' contrast_name], [-1 0 0], 'tcon'}
};

for j = 1:length(contrasts)
    if strcmp(contrasts{j}{3}, 'fcon')
        matlabbatch{3}.spm.stats.con.consess{j}.fcon.name = contrasts{j}{1};
        matlabbatch{3}.spm.stats.con.consess{j}.fcon.weights = contrasts{j}{2};
    else
        matlabbatch{3}.spm.stats.con.consess{j}.tcon.name = contrasts{j}{1};
        matlabbatch{3}.spm.stats.con.consess{j}.tcon.weights = contrasts{j}{2};
    end
    matlabbatch{3}.spm.stats.con.consess{j}.tcon.sessrep = 'none';
end
matlabbatch{3}.spm.stats.con.delete = 1;
end