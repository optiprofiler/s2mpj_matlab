function test_state_paths()
%TEST_STATE_PATHS Check path shadowing and source/serialization identity.
    repo=fileparts(fileparts(mfilename('fullpath')));
    original_path=path; original_dir=pwd;
    directory=tempname; mkdir(directory);
    cleanup=onCleanup(@() restore_environment(original_path,original_dir,directory)); %#ok<NASGU>
    addpath(repo);
    p=s2mpj_load('ROSENBR'); expected=p.fun(p.x0);
    oracle=S2mpjOracle('ROSENBR',{}); oracle.setup();
    saved=oracle.saveobj();
    foreign=saved;
    foreign.relative_files=cellfun(@(p) strrep(p,'/',char(92)),saved.relative_files,'UniformOutput',false);
    restored=S2mpjOracle.loadobj(foreign);
    assert(restored.call('fx',p.x0)==expected);
    changed=saved; changed.digests{2}=repmat('0',1,64);
    assert_error(@() S2mpjOracle.loadobj(changed),'S2MPJ:SourceChanged');
    fid=fopen(fullfile(directory,'ROSENBR.m'),'w');
    fprintf(fid,'function varargout=ROSENBR(varargin)\nerror(''S2MPJ:ShadowExecuted'',''Wrong source executed.'');\nend\n'); fclose(fid);
    addpath(directory,'-begin');
    assert(abs(p.fun(p.x0)-expected)<1e-12);
    % pwd takes priority even when the MATLAB path string is unchanged.
    cd(directory);
    assert_error(@() oracle.call('fx',p.x0),'S2MPJ:SourceShadowed');
    cd(original_dir);
    assert(abs(p.fun(p.x0)-expected)<1e-12);
    clear functions
    assert(abs(p.fun(p.x0)-expected)<1e-12);
    % External raw-native setup/clear requires a new explicit adapter load.
    a=s2mpj_load('BDQRTIC',6);
    BDQRTIC('setup',10);
    clear BDQRTIC
    a=s2mpj_load('BDQRTIC',6);
    assert(a.fun(a.x0)==452);
    disp('S2MPJ path and identity: PASS');
end
function assert_error(fun,identifier)
    caught=false;
    try, fun(); catch ME, caught=strcmp(ME.identifier,identifier); end
    assert(caught,'Expected %s.',identifier);
end
function restore_environment(old_path,old_dir,directory)
    cd(old_dir); path(old_path);
    if isfolder(directory), rmdir(directory,'s'); end
end
