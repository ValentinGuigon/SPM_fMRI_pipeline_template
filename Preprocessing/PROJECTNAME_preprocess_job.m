%-----------------------------------------------------------------------
% Job saved on 20-Jan-2021, updated on 06-Dec-2024, by Valentin Guigon
% Modular Preprocessing Pipeline with ART Repair and Normalization
%-----------------------------------------------------------------------

clear
close all


%% Initialization

projectName = 'PROJECTNAME';

[FMRI_PROJECT_PATH, ONSETS_PATH, FIRST_LVL_PATH, SUBJ_LIST, BASE_PATH, SPM_PATH] = get_fmri_settings({...
    'FMRI_PROJECT_PATH', 'ONSETS_PATH', 'FIRST_LVL_PATH', 'SUBJ_LIST', 'BASE_PATH', 'SPM_PATH'});

STEPS = [{'motion_correction'};{'segmentation'};{'dartel'};{'normalise'};{'normalise RC'};{'normalise_grey_white'}];
% STEPS = [{'ART'}];
normalize_white_matter = 0;

subjects_dir = dir(fullfile(FMRI_PROJECT_PATH, '*', projectName, '_*'));
subjects_list_norm = SUBJ_LIST;


%% Preprocessing Steps
for subject = SUBJ_LIST
    disp(['Processing Subject: ', num2str(subject)]);
    subject_path = fullfile(FMRI_PROJECT_PATH, subjects_dir(subject).name);

    % ===== Motion Correction Step =====
    if any(strcmp(STEPS, 'motion_correction') == 1)
        spm('defaults','fmri');
        spm_jobman('initcfg');
        clear matlabbatch;
        
        % =====================
        %% Field map
        
        % Locate subject directories
        fieldmap_dir = dir(fullfile(subject_path, 'gre*'));
        runs_dir = dir(fullfile(subject_path, 'RUN*_PA_00*'));
        T1_dir = dir(fullfile(subject_path, 'T1*'));

        % Locate subject files
        phase_file = dir(fullfile(subject_path, fieldmap_dir(2).name, 'sFAKENEWS*'));
        magn_file = dir(fullfile(subject_path, fieldmap_dir(1).name, 'sFAKENEWS*'));
        run1_files = dir(fullfile(subject_path, runs_dir(1).name, 'f*')); % Discard scans we won't use?
        run2_files = dir(fullfile(subject_path, runs_dir(2).name, 'f*')); % Discard scans we won't use?
        T1_file = dir(fullfile(T1_dir(2).folder, T1_dir(2).name, 'sFAKENEWS*.nii'));
        
        % Configure Fieldmap batch
        %matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsfile = {default_fieldmap_path};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.et = [5.2 7.66];
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.maskbrain = 0;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.blipdir = 1;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.tert = 23.2;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.epifm = 0;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.ajm = 0;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.method = 'Mark3D';
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.fwhm = 10;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.pad = 0;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.ws = 1;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.template = ...
            {fullfile(SPM_PATH, 'toolbox', 'FieldMap', 'T1.nii')};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.fwhm = 5;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.nerode = 2;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.ndilate = 4;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.thresh = 0.5;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.reg = 0.02;
        
        % Input files for fieldmap
        % PHASE = 0010 & MAGNITUDE = 0009(1st file = short echo time ; 2nd file = long echo time)
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = ...
            {fullfile(phase_file.folder, phase_file.name)};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = ...
            {fullfile(magn_file.folder, magn_file.name)};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session(1).epi = ...
            {fullfile(run1_files(1).folder, run1_files(1).name)};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session(2).epi = ...
            {fullfile(run2_files(1).folder, run2_files(1).name)};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 0;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'session';
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 1;
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.anat = ...
            {fullfile(T1_file(1).folder, T1_file(1).name)};
        matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 1;
        
        % =====================
        %% Slice Timing
        matlabbatch{2}.spm.temporal.st.scans = {
            fullfile(run1_files(1).folder, {run1_files.name})';
            fullfile(run2_files(1).folder, {run2_files.name})';
        };
        
        matlabbatch{2}.spm.temporal.st.nslices = 52;
        matlabbatch{2}.spm.temporal.st.tr = 1.6;
        matlabbatch{2}.spm.temporal.st.ta = 1.56923076923077;
        % Slice oder taken from slice 2 in run 1. Attention: run 2, each so is shifted by 25 units. E.g.:
        %     run 1:
        %     hdr = spm_dicom_headers('1.3.12.2.1107.5.2.43.66012.30000021011108221132200000013-12-2-19o3bmp.dcm');
        %     slice_times = hdr{1}.Private_0019_1029
        %     slice_times = typecast(uint8(slice_times), 'double')
        %     [~, slice_order] = sort(slice_times);
        %     run 2:
        %     hdr = spm_dicom_headers('1.3.12.2.1107.5.2.43.66012.30000021011108221132200000013-15-2-thqtp.dcm');
        %     slice_times = hdr{1}.Private_0019_1029
        %     slice_times = typecast(uint8(slice_times), 'double')
        %     [~, slice_order] = sort(slice_times);
        % Thus, we use the order of slices instead of time
        matlabbatch{2}.spm.temporal.st.so = [0 1155 729.99999998,...
            304.99999999 1459.99999999 1034.99999997 607.49999998 182.5,...
            1337.49999999 912.49999998 487.49999999 62.5 1217.5 789.99999998,...
            364.99999999 1519.99999999 1094.99999997 669.99999998 245,...
            1397.49999999 972.49999997 547.49999999 122.5 1277.5 852.49999998,...
            427.49999999 0 1155 729.99999998 304.99999999 1459.99999999,...
            1034.99999997 607.49999998 182.5 1337.49999999 912.49999998,...
            487.49999999 62.5 1217.5 789.99999998 364.99999999 1519.99999999,...
            1094.99999997 669.99999998 245 1397.49999999 972.49999997,...
            547.49999999 122.5 1277.5 852.49999998 427.49999999];
        matlabbatch{2}.spm.temporal.st.refslice = 0;
        matlabbatch{2}.spm.temporal.st.prefix = 'a';
        
        % =====================
        %% Realign & Unwarp
        matlabbatch{3}.spm.spatial.realignunwarp.data(1).scans = cfg_dep('Slice Timing: Slice Timing Corr. Images (Sess 1)', ...
            substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        matlabbatch{3}.spm.spatial.realignunwarp.data(1).pmscan = cfg_dep('Calculate VDM: Voxel displacement map (Subj 1, Session 1)', ...
            substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','vdmfile', '{}',{1}));
        matlabbatch{3}.spm.spatial.realignunwarp.data(2).scans = cfg_dep('Slice Timing: Slice Timing Corr. Images (Sess 2)', ...
            substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{2}, '.','files'));
        matlabbatch{3}.spm.spatial.realignunwarp.data(2).pmscan = cfg_dep('Calculate VDM: Voxel displacement map (Subj 1, Session 2)', ...
            substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','vdmfile', '{}',{2}));
        matlabbatch{3}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
        matlabbatch{3}.spm.spatial.realignunwarp.eoptions.sep = 4;
        matlabbatch{3}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
        matlabbatch{3}.spm.spatial.realignunwarp.eoptions.rtm = 0;
        matlabbatch{3}.spm.spatial.realignunwarp.eoptions.einterp = 2;
        matlabbatch{3}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
        matlabbatch{3}.spm.spatial.realignunwarp.eoptions.weight = '';
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.jm = 0;
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.sot = [];
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.rem = 1;
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.noi = 5;
        matlabbatch{3}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
        matlabbatch{3}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
        matlabbatch{3}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
        matlabbatch{3}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
        matlabbatch{3}.spm.spatial.realignunwarp.uwroptions.mask = 1;
        matlabbatch{3}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';
        
        % =====================
        %% Coregistration: Estimate
        matlabbatch{4}.spm.spatial.coreg.estimate.ref = cfg_dep('Realign & Unwarp: Unwarped Mean Image', ...
            substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','meanuwr'));
        matlabbatch{4}.spm.spatial.coreg.estimate.source = ...
            {fullfile(T1_file.folder, T1_file.name)};
        matlabbatch{4}.spm.spatial.coreg.estimate.other = {''};
        matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
        matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
        matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
        
        % =====================
        %% Execute batch
        spm_jobman('run',matlabbatch);
    end
end


% =====================
%% Segmentation
%%%%%%%%%%%%%%%%%%%%%%%

if any(strcmp(STEPS, 'segmentation') == 1)
    spm('defaults', 'fmri');
    spm_jobman('initcfg');

    for subject = SUBJ_LIST
        disp(['Segmenting Subject: ', num2str(subject)]);
        clear matlabbatch;

        % Define subject T1 directory and file
        subject_path = fullfile(FMRI_PROJECT_PATH, subjects_dir(subject).name);
        T1_dir = dir(fullfile(subject_path, 'T1*'));
        T1_file = dir(fullfile(subject_path, T1_dir(2).name, 'sFAKENEWS*.nii'));
        
        % Configure Segmentation batch
        matlabbatch{1}.spm.spatial.preproc.channel.vols = ...
            {fullfile(T1_file.folder, T1_file.name)};
        matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];

        % Tissue-specific parameters
        for tpm_idx = 1:6
            matlabbatch{1}.spm.spatial.preproc.tissue(tpm_idx).tpm = ...
                {fullfile(DEFAULT_SEG_PATH, ['TPM.nii,', num2str(tpm_idx)])};
        end
        matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 1];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 1];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 1];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];

        % Warping parameters
        matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];

        % Run segmentation
        spm_jobman('run',matlabbatch);
    end
end

% =====================
%% Dartel
%%%%%%%%%%%%%%%%%%%%%%%

if any(strcmp(STEPS, 'dartel') == 1)
    spm('defaults','fmri');
    spm_jobman('initcfg');
    clear matlabbatch;

    % Prepare input for DARTEL
    RC1 = cell(1, length(subjects_list_norm)); RC2 = cell(1, length(subjects_list_norm)); RC3 = cell(1, length(subjects_list_norm));
    for subject_idx = 1:length(subjects_list_norm)
        subject = subjects_list_norm(subject_idx);
        subject_path = fullfile(FMRI_PROJECT_PATH, subjects_dir(subject).name);

        T1_dir = dir(fullfile(subject_path, 'T1*'));
        T1_files = dir(fullfile(subject_path, T1_dir(2).name, 'rc*.nii'));
        T1_folder = T1_files.folder;

        % Collect RC images
        RC1{subject_idx} = fullfile(T1_folder, T1_files(contains({T1_files.name}, 'rc1')).name);
        RC2{subject_idx} = fullfile(T1_folder, T1_files(contains({T1_files.name}, 'rc2')).name);
        RC3{subject_idx} = fullfile(T1_folder, T1_files(contains({T1_files.name}, 'rc3')).name);
    end
    
    % Configure DARTEL batch
    matlabbatch{1}.spm.tools.dartel.warp.images = {
        RC1(:)'
        RC2(:)'
        RC3(:)'
    };
    matlabbatch{1}.spm.tools.dartel.warp.settings.template = 'Template';
    matlabbatch{1}.spm.tools.dartel.warp.settings.rform = 0;

    % Define DARTEL parameters
    for param_idx = 1:6
        matlabbatch{1}.spm.tools.dartel.warp.settings.param(param_idx).its = 3;
        matlabbatch{1}.spm.tools.dartel.warp.settings.param(param_idx).slam = 16 / (2^(param_idx - 1)); %16, 8, 4, 2, 1, 0.5
    end
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).rparam = [4 2 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).K = 0;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).rparam = [2 1 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).K = 0;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).rparam = [1 0.5 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).K = 1;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).rparam = [0.5 0.25 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).K = 2;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).rparam = [0.25 0.125 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).K = 4;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).rparam = [0.25 0.125 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).K = 6;

    % Optimization settings
    matlabbatch{1}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;
    matlabbatch{1}.spm.tools.dartel.warp.settings.optim.cyc = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.optim.its = 3;

    % Run the DARTEL step
    spm_jobman('run',matlabbatch);
end

% =====================
%% Normalise (functional)
%%%%%%%%%%%%%%%%%%%%%%%

if any(strcmp(STEPS, 'normalise') == 1)
    spm('defaults','fmri');
    spm_jobman('initcfg');
    clear matlabbatch

    % Locate the normalization template
    T1_dir_template = dir(fullfile(FMRI_PROJECT_PATH, subjects_dir(1).name, 'T1*'));
    matlabbatch{1}.spm.tools.dartel.mni_norm.template = ...
        {fullfile(T1_dir_template(2).folder, T1_dir_template(2).name, 'Template_6.nii')};
    
    % Process each subject
    for subject_idx = 1:length(subjects_list_norm)
        subject = subjects_list_norm(subject_idx);
        subject_path = fullfile(FMRI_PROJECT_PATH, subjects_dir(subject).name);

        % Locate runs
        runs_dir = dir(fullfile(subject_path, 'RUN*_PA_00*'));
        run1_files = dir(fullfile(subject_path, runs_dir(1).name, 'uaf*'));
        run2_files = dir(fullfile(subject_path, runs_dir(2).name, 'uaf*'));

        % Locate T1 and flowfield file
        T1_dir = dir(fullfile(subject_path, 'T1*'));
        flowfield_file = dir(fullfile(subject_path, T1_dir(2).name, 'u_rc*.nii'));

        % Configure DARTEL normalization for the subject
        matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(subject_idx).flowfield = ...
            {fullfile(flowfield_file.folder, flowfield_file.name)};
        matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(subject_idx).images = ...
            [fullfile(run1_files(1).folder, {run1_files.name})'; 
             fullfile(run2_files(1).folder, {run2_files.name})'];
    end

    % Normalization parameters
    matlabbatch{1}.spm.tools.dartel.mni_norm.vox = [3 3 3];
    matlabbatch{1}.spm.tools.dartel.mni_norm.bb = [NaN NaN NaN; NaN NaN NaN];
    matlabbatch{1}.spm.tools.dartel.mni_norm.preserve = 0;
    matlabbatch{1}.spm.tools.dartel.mni_norm.fwhm = [8 8 8];

    % Run the batch
    spm_jobman('run', matlabbatch);
end

% =====================
%% Normalise RC (anat)
%%%%%%%%%%%%%%%%%%%%%%%

if any(strcmp(STEPS, 'normalise RC'))
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    clear matlabbatch;

    % Locate the normalization template
    T1_dir_template = dir(fullfile(FMRI_PROJECT_PATH, subjects_dir(subjects_list_norm(1)).name, 'T1*'));
    matlabbatch{1}.spm.tools.dartel.mni_norm.template = ...
        {fullfile(T1_dir_template(2).folder, T1_dir_template(2).name, 'Template_6.nii')};

    % Process each subject
    for subject_idx = 1:length(subjects_list_norm)
        subject = subjects_list_norm(subject_idx);
        subject_path = fullfile(FMRI_PROJECT_PATH, subjects_dir(subject).name);

        % Locate T1 and flowfield files
        T1_dir = dir(fullfile(subject_path, 'T1*'));
        flowfield_file = dir(fullfile(subject_path, T1_dir(2).name, 'u_rc*.nii'));
        RC_file = dir(fullfile(subject_path, T1_dir(2).name, 'c1*.nii')); % Grey matter RC file

        % Configure DARTEL normalization for the subject
        matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(subject_idx).flowfield = ...
            {fullfile(flowfield_file.folder, flowfield_file.name)};
        matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(subject_idx).images = ...
            {fullfile(RC_file.folder, RC_file.name)};
    end

    % Normalization parameters
    matlabbatch{1}.spm.tools.dartel.mni_norm.vox = [1 1 1];
    matlabbatch{1}.spm.tools.dartel.mni_norm.bb = [NaN NaN NaN; NaN NaN NaN];
    matlabbatch{1}.spm.tools.dartel.mni_norm.preserve = 0;
    matlabbatch{1}.spm.tools.dartel.mni_norm.fwhm = [1 1 1];

    % Run the batch
    spm_jobman('run', matlabbatch);
end

% =====================
%% Normalize grey and white matter mask
%%%%%%%%%%%%%%%%%%%%%%%

if any(strcmp(STEPS, 'normalise_grey_white') == 1)
    spm('defaults','fmri');
    spm_jobman('initcfg');
    clear matlabbatch
    
    % Locate the normalization template
    T1_dir_template = dir(fullfile(FMRI_PROJECT_PATH, subjects_dir(subjects_list_norm(1)).name, 'T1*'));
    matlabbatch{1}.spm.tools.dartel.mni_norm.template = ...
        {fullfile(T1_dir_template(2).folder, T1_dir_template(2).name, 'Template_6.nii')};
    
    % Normalize Grey and White Matter
    for subject_idx = 1:length(subjects_list_norm)
        subject = subjects_list_norm(subject_idx);
        subject_path = fullfile(FMRI_PROJECT_PATH, subjects_dir(subject).name);

        % Locate T1, Grey, and White masks
        T1_dir = dir(fullfile(subject_path, 'T1*'));
        grey_mask = dir(fullfile(subject_path, T1_dir(2).name, 'c1*.nii'));
        white_mask = dir(fullfile(subject_path, T1_dir(2).name, 'c2*.nii'));
        flowfield_file = dir(fullfile(subject_path, T1_dir(2).name, 'u_rc*.nii'));

        % Configure normalization for grey matter
        matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(subject_idx).flowfield = ...
            {fullfile(flowfield_file.folder, flowfield_file.name)};
        matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj(subject_idx).images = ...
            {fullfile(grey_mask.folder, grey_mask.name)};

        % Configure normalization for white matter
        if normalize_white_matter == 1
            matlabbatch{2}.spm.tools.dartel.mni_norm.data.subj(Subject).flowfield = ...
                {fullfile(flowfield_file.folder, flowfield_file.name)};
            matlabbatch{2}.spm.tools.dartel.mni_norm.data.subj(Subject).images =...
                {fullfile(white_mask.folder, white_mask.name)};
        end
    end

    % Normalization parameters for grey matter
    matlabbatch{1}.spm.tools.dartel.mni_norm.vox = [1 1 1];
    matlabbatch{1}.spm.tools.dartel.mni_norm.bb = [NaN NaN NaN NaN NaN NaN];
    matlabbatch{1}.spm.tools.dartel.mni_norm.preserve = 0;
    matlabbatch{1}.spm.tools.dartel.mni_norm.fwhm = [8 8 8];

    % Normalization parameters for white matter
    if normalize_white_matter == 1
        matlabbatch{2}.spm.tools.dartel.mni_norm.template = template_path;
        matlabbatch{2}.spm.tools.dartel.mni_norm.vox = [1 1 1];
        matlabbatch{2}.spm.tools.dartel.mni_norm.bb = [NaN NaN NaN NaN NaN NaN];
        matlabbatch{2}.spm.tools.dartel.mni_norm.preserve = 0;
        matlabbatch{2}.spm.tools.dartel.mni_norm.fwhm = [8 8 8];
    end
    
    % Run the normalization batch
    spm_jobman('run',matlabbatch);

% Create binary mask
    for subject_idx = 1:length(subjects_list_norm)
        subject = subjects_list_norm(subject_idx);
        subject_path = fullfile(FMRI_PROJECT_PATH, subjects_dir(subject).name);

        % Locate T1 directory and grey matter mask
        T1_dir = dir(fullfile(subject_path, 'T1*'));
        grey_mask = dir(fullfile(subject_path, T1_dir(2).name, 'swc1*.nii'));

        % Configure binary mask creation
        clear matlabbatch;
        matlabbatch{1}.spm.util.imcalc.input = ...
            {fullfile(grey_mask.folder, grey_mask.name)};
        matlabbatch{1}.spm.util.imcalc.output = 'ExplicitMaskGrey';
        matlabbatch{1}.spm.util.imcalc.outdir = ...
            {fullfile(T1_dir(2).folder, T1_dir(2).name)};
        matlabbatch{1}.spm.util.imcalc.expression = 'i1>0.2';
        matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
        matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
        matlabbatch{1}.spm.util.imcalc.options.mask = 0;
        matlabbatch{1}.spm.util.imcalc.options.interp = 1;
        matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

        % Run binary mask creation
        spm_jobman('run', matlabbatch);
    end
end



%% ART
% https://cibsr.stanford.edu/content/dam/sm/cibsr/documents/tools/methods/artrepair-software/ArtRepairOverview.pdf
% Preview the data before any preprocessing                             -> art_global to locate unusual scans in the time series
% Repair bad slices and voxel spike noise, before preprocessing         -> art_slice automatically locates bad slices, or suppresses all spike noise
% Repair bad volume data just before estimation, after preprocessing    -> art_global, using realignment files, finds large scan-to-scan motion
% Review quality of estimation results for each subject                 -> art_summary measures distribution of contrasts and noise over the head

if any(strcmp(STEPS, 'ART') == 1)
    addpath 'D:\ISC\matlab\R2019b\Release\toolbox\ART repair v5b3'
    run('C:\Users\vguigon\Dropbox (Personnelle)\Neuroeconomics Lab\FAKE NEWS\Scripts\fMRI Preprocess\Fake-News\FAKENEWS_Art_repair.m')
end