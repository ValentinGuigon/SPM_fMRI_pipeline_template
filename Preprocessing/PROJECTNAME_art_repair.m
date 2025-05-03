%-----------------------------------------------------------------------
% Pre-processing pipeline for GF experiment
% V.Guigon 17_Mar_2021 - updated 06_Dec_2024
% Use files art_global_modified because in art_global, an error in script for generating graphs causes end of execution
%
%-----------------------------------------------------------------------

clear
close all


%% Initialization

projectName = 'PROJECTNAME';

[FMRI_DATA_PATH, SUBJ_LIST] = get_fmri_settings({...
    'FMRI_DATA_PATH', 'SUBJ_LIST'});
subject_dir = dir(fullfile(FMRI_DATA_PATH, '*', projectName, '_*'));


%% ==========
% Art Repair
% ===========
%repare bad volume data (after preprocessing)
for subject = SUBJ_LIST
    disp(['Processing subject ', num2str(subject)]);
    runs = dir(fullfile(FMRI_DATA_PATH,subject_dir(subject).name,'/RUN*'));

    % Select runs "RUN1_PA_0012" and "RUN2_PA_0015"
    run1 = dir(fullfile(FMRI_DATA_PATH, subject_dir(subject).name, 'RUN1_PA_00*', 'f*'));
    run2 = dir(fullfile(FMRI_DATA_PATH, subject_dir(subject).name, 'RUN2_PA_00*', 'f*'));

    % Process each run
    for session = 1:2
        switch session
            case 1, run_path = run1.folder;
            case 2, run_path = run2.folder;
        end
        % Select files for Art Repair
        [files,dirs]=spm_select('List',run_path,'^swuaf.*');
        Images=strcat(run_path,'\',files);
        [files,dirs]=spm_select('List',run_path,'^rp.*');
        Rp_file=strcat(run_path,'\',files);

        %c lance la reparation
        art_global_modified(Images,Rp_file,4,2); % ATTENTION: RepairType=2 for motion adjusted images (=> not motion clipping nor margins=deweigthing)
        %             end                                      % RepairType=1 for non motion adjusted images (=> motion clipping for further use of motion regressors)
        % Modified = line 432 = legend('x mvmt', 'y mvmt', 'z mvmt','pitch','roll','yaw'); ( '0' has been deleted)
    end
end