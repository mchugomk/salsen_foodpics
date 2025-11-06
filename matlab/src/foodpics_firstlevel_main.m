function foodpics_firstlevel_main(inp)

multi_fmri=0;   % set this to 1 if more than one run being modeled
ss=0;           % set this to 1 if spatial smoothing 

% Setup file lists for spm
[fmri1_path,fmri1_name,fmri1_ext]=fileparts(inp.fmri1_nii);                      	% fmri1 file parts
onsets1=inp.multi_conds1;                                                           % onsets file for fmri1
if ~strcmp(inp.fmri2_nii, '')
    multi_fmri=1;
    [fmri2_path,fmri2_name,fmri2_ext]=fileparts(inp.fmri2_nii);                     % fmri2 file parts
    onsets2=inp.multi_conds2;                                                       % onsets file for fmri2
end
tr=str2num(inp.tr);                                                                 % repetition time in seconds
n_vols=str2num(inp.n_vols);                                                         % number of volumes in fmri.nii
if ~strcmp(inp.fwhm, '')                                                            % fwhm of spatial smoothing kernel
    ss=1;
    fwhm=str2num(inp.fwhm);
end
mthresh=str2num(inp.mthresh);   % default should be 0.8
hpf=str2num(inp.hpf);           % default should be 128
batchfile_ss=fullfile(inp.out_dir,'foodpics_smooth_batch.mat');                     % save batch job for smoothing here
batchfile=fullfile(inp.out_dir,'foodpics_firstlevel_batch.mat');                    % save batch job here


% Extract motion parameters
[rp_file1, dvars_file1, fd_file1]=get_mot_params(inp.confounds1);
if ~strcmp(inp.confounds2, '')
    [rp_file2, dvars_file2, fd_file2]=get_mot_params(inp.confounds2);
end


% Get spm defaults and start
spm('defaults', 'FMRI');
spm_get_defaults('cmdline',false);
spm_jobman('initcfg');
F=spm_figure('GetWin','Graphics');

                                 
% Setup batch structure for spatial smoothing
if ss
    clear matlabbatch;

    if multi_fmri
        matlabbatch{1}.spm.spatial.smooth.data = [
                                                    cellstr(spm_select('ExtFPList', fmri1_path, ['^' fmri1_name fmri1_ext],1:n_vols));
                                                    cellstr(spm_select('ExtFPList', fmri2_path, ['^' fmri2_name fmri2_ext],1:n_vols));
                                            ];                                 
    else
        matlabbatch{1}.spm.spatial.smooth.data = cellstr(spm_select('ExtFPList', fmri1_path, ['^' fmri1_name fmri1_ext],1:n_vols));
    end
    matlabbatch{1}.spm.spatial.smooth.fwhm = [fwhm fwhm fwhm];
    matlabbatch{1}.spm.spatial.smooth.dtype = 0;
    matlabbatch{1}.spm.spatial.smooth.im = 0;
    matlabbatch{1}.spm.spatial.smooth.prefix = 's';

    save(batchfile_ss, 'matlabbatch');
    spm_jobman('run', matlabbatch);
end

cd(inp.out_dir); 

% Setup batch structure for first level model
clear matlabbatch;

% Create spm batch
matlabbatch{1}.spm.stats.fmri_spec.dir = {inp.out_dir}; 
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = tr;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;

% setup fmri1
matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = cellstr(fullfile(fmri1_path, ['s' fmri1_name fmri1_ext]));
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {inp.multi_conds1};
matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress = struct('name', {}, 'val', {});
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {rp_file1};
matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = hpf;

% setup fmri2
if multi_fmri   
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).scans = cellstr(fullfile(fmri2_path, ['s' fmri2_name fmri2_ext]));
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi = {inp.multi_conds2};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = {rp_file2};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).hpf = 128;
end

% design options
matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = mthresh;
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

% estimate model
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 1;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

% contrasts
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'highcaloric vs lowcaloric';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 -1 0];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'food vs nonfood';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0.5 0.5 -1];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'highcaloric vs nonfood';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [1 0 -1];
matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'lowcaloric vs nonfood';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [0 1 -1];
matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'highcaloric';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [1 0 0];
matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'lowcaloric';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [0 1 0];
matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = 'nonfood';
matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = [0 0 1];
matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.delete = 1;


% Save and run batch
save(batchfile, 'matlabbatch');
spm_jobman('run', matlabbatch);

spm_figure('Print',F)

end
