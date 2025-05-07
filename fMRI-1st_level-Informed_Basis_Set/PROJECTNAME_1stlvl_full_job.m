%-----------------------------------------------------------------------
% Job saved on 20-Jan-2021, updated on 18-Dec-2024, by Valentin Guigon
% Specify and Estimate First-Level Models
%
% For SIEMENS Prisma 3T
%
% ! To avoid issues with cfg_dep (usually resolved by starting spm fmri),
% Use the folder @cfg_dep provided
%-----------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% all models:
%     {'006 - CustomGLMpmodConfidence_TFjudgment' '011 - CustomGLMpmodConfidence_SendRefrain' '012 - CustomGLMpmodCue_SendRefrain'...
%     ...
%     '141 - CustomGLMpmodEvalBayesMode_SendRefrain' '142 - CustomGLMpmodCueBayesMode_SendRefrain' '143 - CustomGLMpmodLearnBayesMode_SendRefrain'...
%     ...
%     '201 - CustomGLMpmodFinalBayesMode_SendRefrain'};
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
close all


%% Initialization

projectName = 'PROJECTNAME';

[projectRoot, FMRI_PROJECT_PATH, ONSETS_PATH, FIRST_LVL_PATH, SUBJ_LIST, BASE_PATH] = get_fmri_settings({...
    'projectRoot', 'FMRI_PROJECT_PATH', 'ONSETS_PATH', 'FIRST_LVL_PATH', 'SUBJ_LIST', 'BASE_PATH'});

ModelList = {
    '001 - BasicGLM_ToyModel_pmodConfidence' ...
    '006 - CustomGLMpmodConfidence_TFjudgment' '011 - CustomGLMpmodConfidence_SendRefrain' '012 - CustomGLMpmodCue_SendRefrain'... 
    ...
    '141 - CustomGLMpmodEvalBayesMode_SendRefrain' '142 - CustomGLMpmodCueBayesMode_SendRefrain' '143 - CustomGLMpmodLearnBayesMode_SendRefrain'...
    ...
    '201 - CustomGLMpmodFinalBayesMode_SendRefrain'
    };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Choose the run settings
% Choose here the folder for the current analysis
%
MODELS_FOLDER = 'Models_folder'; % Folder where GLM will be saved
DATA_FILE = 'Data.mat'; % Behavioral data file
%
% Get modelling data
Modelling_data = load(fullfile(projectRoot, "data/computational_modelling", DATA_FILE));
Modelling_data = Modelling_data.Bayes;
%
% Define steps
STEPS = [{'onsets'};{'specify'};{'estimate'};{'contrast'}];
%
% Model selection
% models_to_run = [006 011 012 141 142 143 201]; % declare the numeric identifiers
models_to_run = [006];
%
% Subjects selection
Subjects = SUBJ_LIST; 
%
% Choose whether using pmod or not
% pmod_to_contrast ~= 0 will use the pmod defined as 'pmod of interest'
pmod_to_contrast = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Map model indices to GLM names
model_ids = arrayfun(@(x) sprintf('%03d', x), models_to_run, 'UniformOutput', false); % Convert model IDs to 3-digit strings
selected_models = ModelList(contains(ModelList, strcat(model_ids, ' - ')));

% Locate directories
SUBJECT_DIRECTORIES = dir(fullfile(FMRI_PROJECT_PATH, '*', projectName, '_*'));
MODELS_PATH = fullfile(ONSETS_PATH, MODELS_FOLDER);
MODEL_DIRECTORIES = dir(fullfile(MODELS_PATH, '*GLM*'));
FIRST_LVL_PATH = fullfile(FIRST_LVL_PATH, MODELS_FOLDER);

% Initialize a cell array to store warnings for all models
all_warnings = {};

%% Process Models
for Model_idx = 1:length(selected_models)
    Model_name = selected_models{Model_idx};
    disp(['Processing Model: ', Model_name]);

    % Exception for SendRefrain models: 
    if contains(Model_name, 'SendRefrain')
        SendRefrain_subject_to_ignore = get_fmri_settings({'SendRefrain_subject_to_ignore'});
        SUBJ_LIST_Corrected = SUBJ_LIST(SUBJ_LIST ~= SendRefrain_subject_to_ignore); 
        Subjects = SUBJ_LIST_Corrected; 
    else, SUBJ_LIST_Corrected = Subjects; 
    end

    %% Create Onsets
    if any(strcmp(STEPS, 'onsets') == 1)
        disp('Creating onsets');

        % Create a specific save path for the current model
        SavePath = fullfile(ONSETS_PATH, MODELS_FOLDER);
        ModelSavePath = fullfile(SavePath, Model_name);
        if ~exist(ModelSavePath, 'dir')
            mkdir(ModelSavePath);
        end

        % Subject directories
        SUBJECT_DIRECTORIES = dir(fullfile(FMRI_PROJECT_PATH, '*', projectName, '_*')); 

        for SubjectIdx = 1:length(Subjects)
            Subject_id = Subjects(SubjectIdx);
            disp(['Creating onsets for model: ', selected_models{Model_idx}, ' for Subject: ' SUBJECT_DIRECTORIES(Subject_id).name]);

            % Declare variables
            SubjectID = Subjects(SubjectIdx);
            SubjectDir = SUBJECT_DIRECTORIES(SubjectID).name;

            % Create onset file
            PROJECTNAME_1stlvl_onsets_function(Model_name, SubjectIdx, Modelling_data, SubjectDir, ModelSavePath, FMRI_PROJECT_PATH);
        end
    end

    %% Specify and/or Estimate GLM
    if any(strcmp(STEPS, 'specify')) || any(strcmp(STEPS, 'estimate'))
        disp('Creating GLM batches');

        for SubjectIdx = 1:length(Subjects)

            %% Define Data
            Subject_id = Subjects(SubjectIdx);
            subject_path = fullfile(SUBJECT_DIRECTORIES(Subject_id).folder, SUBJECT_DIRECTORIES(Subject_id).name);

            % Locate runs dynamically
            run_directories = dir(fullfile(subject_path, 'RUN*_PA_00*'));
            run1_directory = fullfile(subject_path, run_directories(1).name);
            run2_directory = fullfile(subject_path, run_directories(2).name);

            % File patterns
            run1_files = dir(fullfile(run1_directory, 'vswuaf*'));
            run1_motion_params = dir(fullfile(run1_directory, 'rp*'));
            run2_files = dir(fullfile(run2_directory, 'vswuaf*'));
            run2_motion_params = dir(fullfile(run2_directory, 'rp*'));

            % Onsets
            onsets_directory = fullfile(MODELS_PATH, Model_name);
            subject_onset_file_pattern = sprintf('*%s_RUN*.mat', SUBJECT_DIRECTORIES(Subject_id).name);
            subject_onset_files = dir(fullfile(onsets_directory, subject_onset_file_pattern));
            run1_onsets_file = fullfile(onsets_directory, subject_onset_files(1).name);
            run2_onsets_file = fullfile(onsets_directory, subject_onset_files(2).name);

            %% Specify First-Level GLM
            if any(strcmp(STEPS, 'specify'))
                % First-level analysis directory
                first_level_directory = fullfile(FIRST_LVL_PATH, Model_name, SUBJECT_DIRECTORIES(Subject_id).name);
                if exist(first_level_directory, 'dir')
                    rmdir(first_level_directory, 's');
                end
                mkdir(first_level_directory);

                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.dir = {first_level_directory};
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 1.6;
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 52;
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;

                % RUN 1
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = fullfile(run1_directory, {run1_files.name})';
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {run1_onsets_file};
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress = struct('name', {}, 'val', {});
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {fullfile(run1_directory, run1_motion_params.name)};
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128;

                % RUN 2
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(2).scans = fullfile(run2_directory, {run2_files.name})';
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi = {run2_onsets_file};
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(2).regress = struct('name', {}, 'val', {});
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = {fullfile(run2_directory, run2_motion_params.name)};
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.sess(2).hpf = 128;

                % Model Options
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [1 1];
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
            end

            %% Estimate GLM
            if any(strcmp(STEPS, 'estimate'))
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = ...
                    cfg_dep('fMRI model specification: SPM.mat File', ...
                    substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
                analysis_batches(SubjectIdx, Model_idx).matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
            end


            %% Run GLM Batches
            disp(['Running model: ', selected_models{Model_idx}, ' for Subject: ' SUBJECT_DIRECTORIES(Subject_id).name]);
            try
                spm('defaults', 'fmri');
                spm_jobman('initcfg');
                spm_jobman('run', analysis_batches(SubjectIdx, Model_idx).matlabbatch);
            catch ME
                warning(['Error processing subject ', num2str(Subjects(SubjectIdx)), ' for model ', selected_models{Model_idx}, ': ', ME.message]);
            end
        end
    end

    %% Run First-level Contrasts
    %% Create Onsets
    if any(strcmp(STEPS, 'contrast') == 1)
        disp('Creating first level contrasts');

        % Subject directories
        SUBJECT_DIRECTORIES = dir(fullfile(FMRI_PROJECT_PATH, '*', projectName, '_*')); 
        GLM_PATH = fullfile(FIRST_LVL_PATH, Model_name);

        % In case we want to check it,
        % We create a structure to store subject_vectors 
        for i = 1:length(Subjects)
            field_name = sprintf('Subject_%d', Subjects(i));
            all_subjects_vectors.(field_name) = [];
        end

        for SubjectIdx = 1:length(Subjects)
            Subject_id = Subjects(SubjectIdx);
            field_name = sprintf('Subject_%d', Subject_id);
            disp(['Creating first level contrasts for model: ', selected_models{Model_idx}, ' for Subject: ' SUBJECT_DIRECTORIES(Subject_id).name]);

            % Create 1st lvl contrast
            subject_vectors = PROJECTNAME_1stlvl_contrast_function(Model_name, Subject_id, pmod_to_contrast, GLM_PATH, SUBJECT_DIRECTORIES);

            % Store subject_vectors
            all_subjects_vectors.(field_name) = subject_vectors;
        end

        % Check that contrast .vec & .activation predict the contrast vectors
        is_coherent = check_coherence(all_subjects_vectors);

        % Capture warnings generated by check_coherence
        lastwarn(''); % Reset the warning state
        [warnMsg, warnId] = lastwarn; % Get the last warning
        if ~isempty(warnMsg)
            % Store the warning for this model
            all_warnings{end+1} = struct('Model', Model_name, 'WarningMessage', warnMsg, 'WarningID', warnId);
        end

        % Save the contrast vectors IFF we ran all the subjects from SUBJ_LIST
        if isequal(Subjects, SUBJ_LIST_Corrected)
            save(fullfile(GLM_PATH, "contrast_vectors_structure.mat"), "all_subjects_vectors")
        end
    end
end

% Generate a summary warning at the end of the model loop
if ~isempty(all_warnings)
    warning('Recap of all warnings encountered during the model loop:');
    for i = 1:length(all_warnings)
        warning('Model: %s\nWarning: %s\nID: %s\n', ...
                all_warnings{i}.Model, ...
                all_warnings{i}.WarningMessage, ...
                all_warnings{i}.WarningID);
    end
else
    warning('No warnings were generated during the model loop.');
end

%% Helper functions

function is_coherent = check_coherence(all_subjects_vectors)
    % Initialize a flag to track coherence
    is_coherent = true;

    % Get the list of all subjects
    subject_fields = fieldnames(all_subjects_vectors);

    % Loop through each subject
    for i = 1:length(subject_fields)
        subject = all_subjects_vectors.(subject_fields{i});
        
        % Loop through each contrast in the subject
        contrast_fields = fieldnames(subject);
        for j = 1:length(contrast_fields)
            contrast = subject.(contrast_fields{j});
            
            % Extract relevant fields
            vec = contrast.vec;
            k = contrast.k;
            activation = contrast.activation;
            
            % Ensure k and activation are row vectors
            k = k(:)';
            activation = activation(:)';
            
            % Check if the specified columns in vec match the activation values
            if ~isequal(vec{1, k}, activation)
                warning('Incoherence found in %s.%s: .vec does not match .k and .activation.', ...
                        subject_fields{i}, contrast_fields{j});
                is_coherent = false;
            end
            
            % Check if the rest of the columns in vec are zeros
            non_k_columns = setdiff(1:size(vec, 2), k);
            if any(vec{1, non_k_columns} ~= 0)
                warning('Incoherence found in %s.%s: Non-active columns in .vec are not zeros.', ...
                        subject_fields{i}, contrast_fields{j});
                is_coherent = false;
            end
        end
    end

    % Display final result using warning
    if is_coherent
        warning('All subjects contrasts are coherent.');
    else
        warning('Incoherences found in some subjects.');
    end
end