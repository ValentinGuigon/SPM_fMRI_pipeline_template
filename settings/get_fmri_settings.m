function varargout = get_fmri_settings(requestedVars)
    % Configuration for the fMRI analysis pipeline

projectName = 'PROJECTNAME';

    if ~exist('server', 'var') || server == 0
        % Local paths
        projectRoot = matlab.project.rootProject().RootFolder; % Root of the sendingNews project
        BASE_PATH = projectRoot;
        FMRI_PROJECT_PATH = fullfile('D:', 'ISC', projectName); % fMRI data location
        SPM_PATH = fullfile('D:', 'ISC', 'matlab', 'R2019b', 'Release', 'toolbox', 'spm12'); % SPM location
        ART_REPAIR_PATH = fullfile(projectRoot, 'scripts', 'fMRI_analysis', 'fMRI Preprocess'); % Script for Art repair, relative to project root
        PHYSIOLOGS_PATH = fullfile(FMRI_PROJECT_PATH, 'Physiologs'); 
        DEFAULT_SEG_PATH = fullfile(SPM_PATH, 'spm12', 'tpm');
        FIRST_LVL_PATH = fullfile(FMRI_PROJECT_PATH, 'Analysis', 'First_level');
        SECOND_LVL_PATH = fullfile(FMRI_PROJECT_PATH, 'Analysis', 'Second_level');
        ONSETS_PATH = fullfile(FMRI_PROJECT_PATH, 'Onsets');

    else
        % Server paths
        projectRoot = fullfile('/home/common/vguigon/', projectName)'; % Root of the project
        BASE_PATH = projectRoot;
        FMRI_PROJECT_PATH = fullefile('/home/common/vguigon/IRM_', projectName); % fMRI data location
        SPM_PATH = '/home/common/vguigon/matlab/R2019b/Release/toolbox/spm12'; % SPM location
        ART_REPAIR_PATH = '/home/common/vguigon/art_repair'; % Script for Art repair, relative to project root
        PHYSIOLOGS_PATH = fullfile(FMRI_PROJECT_PATH, 'RAW', 'DICOM', 'physiologs');
        DEFAULT_SEG_PATH = fullfile(SPM_PATH, 'spm12', 'tpm');
        FIRST_LVL_PATH = fullfile(FMRI_PROJECT_PATH, 'Analysis', 'First_level');
        SECOND_LVL_PATH = fullfile(FMRI_PROJECT_PATH, 'Analysis', 'Second_level');
        ONSETS_PATH = fullfile(FMRI_PROJECT_PATH, 'Onsets');
    end

    % Task parameters
    SUBJ_LIST = [1 2 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 32 33 34];
    SendRefrain_subject_to_ignore = [33]; % Subject 33 removed for lack of unique onsets
    N_TOTAL_TRIALS = 96;
    N_TRIALS_PER_COND = 48;

    % Store all variables in a struct
    settings = struct();
    settings.projectRoot = projectRoot;
    settings.BASE_PATH = BASE_PATH;
    settings.FMRI_PROJECT_PATH = FMRI_PROJECT_PATH;
    settings.SPM_PATH = SPM_PATH;
    settings.ART_REPAIR_PATH = ART_REPAIR_PATH;
    settings.PHYSIOLOGS_PATH = PHYSIOLOGS_PATH;
    settings.DEFAULT_SEG_PATH = DEFAULT_SEG_PATH; 
    settings.FIRST_LVL_PATH = FIRST_LVL_PATH;
    settings.SECOND_LVL_PATH = SECOND_LVL_PATH;
    settings.ONSETS_PATH = ONSETS_PATH;
    settings.SUBJ_LIST = SUBJ_LIST;
    settings.SendRefrain_subject_to_ignore = SendRefrain_subject_to_ignore;
    settings.N_TOTAL_TRIALS = N_TOTAL_TRIALS;
    settings.N_TRIALS_PER_COND = N_TRIALS_PER_COND;

    % If no input arguments, return the entire struct
    if nargin == 0
        varargout{1} = settings;
        return;
    end

    % If specific variables are requested, return them in the order requested
    varargout = cell(1, numel(requestedVars));
    for i = 1:numel(requestedVars)
        if isfield(settings, requestedVars{i})
            varargout{i} = settings.(requestedVars{i});
        else
            error('Requested variable "%s" does not exist in settings.', requestedVars{i});
        end
    end
end