%-----------------------------------------------------------------------
% Job saved on 09-Mar-2021, updated on 06_Dec_2024, by Valentin Guigon
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
% additional infos here: https://github.com/CMRR-C2P/MB
%-----------------------------------------------------------------------

%% Initialization

[PHYSIOLOGS_PATH, SUBJ_LIST] = get_fmri_settings({...
    'PHYSIOLOGS_PATH', 'SUBJ_LIST'});

subjects_dir = dir(fullfile(PHYSIOLOGS_PATH));
subjects_dir = subjects_dir(~ismember({subjects_dir.name}, {'.', '..'})); % Exclude '.' and '..'

%% Extraction

for subject = SUBJ_LIST
    disp(['Processing Subject: ', num2str(subject)]);
    subject_path = fullfile(PHYSIOLOGS_PATH, subjects_dir(subject).name);
    physio_path{1} = fullfile(subject_path, '*RUN1_PA_PhysioLog', 'secondary');
    physio_path{2} = fullfile(subject_path, '*RUN2_PA_PhysioLog', 'secondary');
    
    % Process runs for the current subject
    for run_idx = 1:2
        % List files in the physiological path
        run_files = dir(fullfile(physio_path{run_idx}, '*')); % Adjust filter if needed
        run_files = run_files(~[run_files.isdir]); % Exclude directories
        
        if isempty(run_files)
            warning(['No files found in ', physio_path{run_idx}, '. Skipping.']);
            continue;
        end
        
        DICOM_filename = fullfile(physio_path{run_idx}, run_files(1).name);
        output_path = physio_path{run_idx};
        
        % Call extraction function
        FAKENEWS_extractCMRRPhysio(DICOM_filename, output_path);
    end
end