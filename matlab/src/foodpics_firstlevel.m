function foodpics_firstlevel(varargin)
% Takes fmriprep results as input

%% Just quit, if requested - needed for Singularity build?
% if numel(varargin)==1 && strcmp(varargin{1},'quit') && isdeployed
% 	disp('Exiting as requested')
% 	exit
% end

%% Parse inputs
P = inputParser;

% Functional image 1 (.nii)
addOptional(P,'fmri1_nii','');

% Functional image 2 (.nii)
addOptional(P,'fmri2_nii','');

% fmriprep confounds for functional image 1 (confounds*.tsv)
addOptional(P,'confounds1','');

% fmriprep confounds for functional image 2 (confounds*.tsv)
addOptional(P,'confounds2','');

% Multiple conditions file for functional image 1
addOptional(P,'multi_conds1','');

% Multiple conditions file for functional image 2
addOptional(P,'multi_conds2','');

% Repetition time
addOptional(P,'tr','');

% Number of volumes
addOptional(P,'n_vols','');

% Spatial smoothing kernel fwhm
addOptional(P,'fwhm','');

% SPM masking threshold, default=0.8
addOptional(P,'mthresh','0.8');

% Highpass filter, default=128
addOptional(P,'hpf','128');

% Where to store outputs
addOptional(P,'out_dir','/OUTPUTS');

% Parse and display command line arguments
parse(P,varargin{:});
disp(P.Results)


%% Process
foodpics_firstlevel_main(P.Results);


%% Exit if running compiled executable
if isdeployed
	exit
end
