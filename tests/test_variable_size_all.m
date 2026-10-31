function test_variable_size_all()
%TEST_VARIABLE_SIZE_ALL 'all' returns every satisfying version, as config.txt says.
    root = fileparts(fileparts(mfilename('fullpath')));
    old_path = path;
    cleanup_path = onCleanup(@() path(old_path)); %#ok<NASGU>
    addpath(root);
    temporary = tempname;
    mkdir(temporary);
    cleanup_files = onCleanup(@() rmdir(temporary, 's')); %#ok<NASGU>
    copyfile(fullfile(root, 's2mpj_select.m'), temporary);
    copyfile(fullfile(root, 'probinfo_matlab.mat'), temporary);
    % The current folder takes precedence over the path, and CI runs in the root.
    original_folder = cd(temporary);
    cleanup_folder = onCleanup(@() cd(original_folder)); %#ok<NASGU>
    clear s2mpj_select
    assert(startsWith(which('s2mpj_select'), temporary), 'The temporary selector is not in use.');
    options = struct('ptype', 'n', 'mindim', 1, 'maxdim', 100, 'maxb', 400, ...
        'maxlcon', 400, 'maxnlcon', 400, 'maxcon', 400);
    default_names = selected(temporary, options, 'default');
    all_names = selected(temporary, options, 'all');
    assert(isempty(setdiff(default_names, all_names)), 'The default selection must be a subset.');
    assert(numel(all_names) == numel(unique(all_names)), 'An instance was selected twice.');
    assert(all(ismember({'ALJAZZAF', 'ALJAZZAF_3_1', 'ALJAZZAF_100_1'}, all_names)));
    options.mindim = 11;
    all_names = selected(temporary, options, 'all');
    assert(~ismember('ALJAZZAF', all_names), 'The criteria must still apply to the default instance.');
    assert(ismember('ALJAZZAF_100_1', all_names));
    clear s2mpj_select
    disp('S2MPJ variable_size=all: PASS');
end

function names = selected(folder, options, variable_size)
    fid = fopen(fullfile(folder, 'config.txt'), 'w');
    assert(fid >= 0);
    fprintf(fid, 'variable_size=%s\ntest_feasibility_problems=0\n', variable_size);
    fclose(fid);
    names = s2mpj_select(options);
end
