function test_native_metadata()
%TEST_NATIVE_METADATA Native metadata and load-time probes fail closed.
%   The fixture is a controlled native-compatible model, so this does not
%   claim that a shipped problem contains malformed metadata.
    root = fileparts(fileparts(mfilename('fullpath')));
    old_path = path;
    cleanup_path = onCleanup(@() path(old_path)); %#ok<NASGU>
    addpath(root, fullfile(root, 'tests', 'fixtures'));
    addpath(fullfile(root, 'src'), fullfile(root, 'src', 'matlab_problems'));

    p = s2mpj_load('NATIVEMETADATA', 'control');
    assert(isequal(p.aub, [1, 2]) && isequal(p.bub, 4));
    assert(p.mlcon == 1 && p.mnlcon == 1);
    assert(p.maxcv([1; 1]) == 0);

    for scenario = {'nan-cupper', 'nan-clower', 'nan-xlower', 'nan-xupper', 'nan-x0', ...
            'short-cupper', 'matrix-cupper', 'text-cupper', 'missing-cupper', ...
            'impossible-xlower', 'impossible-xupper', 'impossible-clower', ...
            'impossible-cupper', 'sentinel-xlower', 'sentinel-cupper', ...
            'crossed-variable-bounds', 'crossed-constraint-bounds', ...
            'unequal-equality', 'free-equality', 'equality-out-of-range'}
        assert_error(scenario{1}, 'S2MPJ:InvalidMetadata');
    end
    for scenario = {'jacobian-error', 'jacobian-nan', 'jacobian-shape', 'value-nan'}
        assert_error(scenario{1}, 'S2MPJ:LinearConstraintFailure');
    end
    try
        s2mpj_load('NATIVEMETADATA', 'jacobian-error');
    catch failure
        assert(strcmp(failure.cause{1}.identifier, 'NATIVEMETADATA:Jacobian'));
    end

    % Native bounds may be rows; only the metadata content matters.
    p = s2mpj_load('NATIVEMETADATA', 'row-bounds');
    assert(p.mlcon == 1 && p.mnlcon == 1);
    % An undefined nonlinear row does not invalidate the linear rows.
    p = s2mpj_load('NATIVEMETADATA', 'nonlinear-row-nan');
    assert(isequal(p.bub, 4));
    % Models without linear rows need no Jacobian at load time.
    p = s2mpj_load('NATIVEMETADATA', 'no-linear-rows');
    assert(p.mlcon == 0 && p.mnlcon == 2);
    % A free row is legitimate: it constrains nothing.
    p = s2mpj_load('NATIVEMETADATA', 'free-row');
    assert(p.mlcon == 0 && p.mnlcon == 1);

    % Shipped models that this validation rejects, and that selection must not offer.
    % HS67: upstream line 395 overwrites the upper bounds of its 7 <= constraints.
    assert_shipped('HS67', 'S2MPJ:InvalidMetadata');
    % ROSSIMP1NE: two equality constraints without clower and cupper.
    assert_shipped('ROSSIMP1NE', 'S2MPJ:InvalidMetadata');
    % Include feasibility problems: ROSSIMP1NE is one, so the default hides it anyway.
    temporary = tempname;
    mkdir(temporary);
    cleanup_files = onCleanup(@() rmdir(temporary, 's')); %#ok<NASGU>
    copyfile(fullfile(root, 's2mpj_select.m'), temporary);
    copyfile(fullfile(root, 'probinfo_matlab.mat'), temporary);
    fid = fopen(fullfile(temporary, 'config.txt'), 'w');
    assert(fid >= 0);
    fprintf(fid, 'variable_size=default\ntest_feasibility_problems=2\n');
    fclose(fid);
    original_folder = cd(temporary);
    cleanup_folder = onCleanup(@() cd(original_folder)); %#ok<NASGU>
    clear s2mpj_select
    assert(startsWith(which('s2mpj_select'), pwd), 'The temporary selector is not in use.');
    names = s2mpj_select(struct('ptype', 'ubln', 'mindim', 1, 'maxdim', 10, 'maxb', 20, ...
        'maxlcon', 20, 'maxnlcon', 20, 'maxcon', 20));
    assert(ismember('HS21', names) && ~any(ismember({'HS67', 'ROSSIMP1NE'}, names)));
    clear s2mpj_select
    disp('S2MPJ native metadata: PASS');
end

function assert_shipped(name, identifier)
    try
        s2mpj_load(name);
    catch failure
        assert(strcmp(failure.identifier, identifier), '%s: %s', name, failure.identifier);
        return
    end
    error('S2MPJ:MissingRejection', '%s was accepted.', name);
end

function assert_error(scenario, identifier)
    try
        s2mpj_load('NATIVEMETADATA', scenario);
    catch failure
        assert(strcmp(failure.identifier, identifier), '%s: %s: %s', scenario, failure.identifier, failure.message);
        return
    end
    error('S2MPJ:MissingRejection', '%s was accepted; expected %s.', scenario, identifier);
end
