%-----------------------------------------------------------------------
% Job saved on 09-Mar-2021, updated on 06_Dec_2024, by Valentin Guigon
% STEP 2: SPECIFY MODELS AND ESTIMATE
%
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
% Additional informations on spm_spec here: https://github.com/neurodebian/spm12/blob/master/config/spm_cfg_fmri_spec.m
%-----------------------------------------------------------------------

clear
close all


%% Initialization
projectName = 'PROJECTNAME';

[FMRI_DATA_PATH, SUBJ_LIST] = get_fmri_settings({...
    'FMRI_DATA_PATH', 'SUBJ_LIST'});
subjects_dir = dir(fullfile(FMRI_DATA_PATH,  projectName, '_*'));


%% Normalize grey and white matter mask - suite from preprocessing
% Create mean binary mask

disp('Step 1: Creating mean binary mask for grey matter...');
files = spm_select('FPListRec', FMRI_DATA_PATH, '^swc1.*\.nii$');

% Define batch for calculating the mean mask
clear matlabbatch;
matlabbatch{1}.spm.util.imcalc.input = cellstr(files);
matlabbatch{1}.spm.util.imcalc.output = 'ExplicitMaskGrey_Mean';
matlabbatch{1}.spm.util.imcalc.outdir = {fullfile(FMRI_DATA_PATH, 'MaskMean')};
matlabbatch{1}.spm.util.imcalc.expression = 'mean(X)';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 1;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
spm_jobman('run', matlabbatch);

% Thresholding the mean mask
disp('Step 2: Applying threshold to the mean mask...');
files = spm_select('FPList', fullfile(FMRI_DATA_PATH, 'MaskMean'), '^ExplicitMaskGrey_Mean\.nii$');

clear matlabbatch;
matlabbatch{1}.spm.util.imcalc.input = cellstr(files);
matlabbatch{1}.spm.util.imcalc.output = 'ExplicitMaskGrey_MeanThr_015';
matlabbatch{1}.spm.util.imcalc.outdir = {fullfile(FMRI_DATA_PATH, 'MaskMean')};
matlabbatch{1}.spm.util.imcalc.expression = 'i1>0.15';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
spm_jobman('run', matlabbatch);

disp('Mask creation and thresholding completed.');
