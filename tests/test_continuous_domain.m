function test_continuous_domain()
%TEST_CONTINUOUS_DOMAIN Reject discrete native models without changing them.
    root = fileparts(fileparts(mfilename('fullpath')));
    old_path = path;
    cleanup_path = onCleanup(@() path(old_path)); %#ok<NASGU>
    addpath(root, fullfile(root, 'tests', 'fixtures'));
    addpath(fullfile(root, 'src'), fullfile(root, 'src', 'matlab_problems'));
    native = NOZZLEfp('setup');
    assert(isequal(native.xtype(:)', 'rrrrb'));
    assert_error(@() s2mpj_load('NOZZLEfp'), 'S2MPJ:NoncontinuousVariables');
    for types = {'rb', 'ii', 'br', 'ri', "rb"}
        assert_error(@() s2mpj_load('VARIABLETYPE', types{1}), ...
            'S2MPJ:NoncontinuousVariables');
    end
    for types = {'r', 'r?', [], 1}
        assert_error(@() s2mpj_load('VARIABLETYPE', types{1}), 'S2MPJ:SetupMetadata');
    end
    for types = {'rr', ['r';'r'], "rr", 'absent'}
        p = s2mpj_load('VARIABLETYPE', types{1});
        assert(isequal(p.x0, [0;1]) && p.fun(p.x0) == 1);
    end
    p = s2mpj_load('ROSENBR');
    assert(isfinite(p.fun(p.x0)));

    data = load(fullfile(root, 'probinfo_matlab.mat'), 'probinfo');
    row = find(strcmp(data.probinfo(:,1), 'NOZZLEfp'));
    assert(isscalar(row) && strcmp(data.probinfo{row,3}, 'rrrrb'));
    csv = readtable(fullfile(root, 'probinfo_matlab.csv'), 'TextType', 'string');
    assert(csv.xtype(csv.name == "NOZZLEfp") == "rrrrb");

    % Exercise metadata filtering without modifying the installed provider.
    temporary = tempname;
    mkdir(temporary);
    cleanup_files = onCleanup(@() rmdir(temporary, 's')); %#ok<NASGU>
    copyfile(fullfile(root, 's2mpj_select.m'), temporary);
    copyfile(fullfile(root, 'config.txt'), temporary);
    probinfo = data.probinfo;
    real_row = find(strcmp(probinfo(:,1), 'ROSENBR'));
    base = probinfo(real_row,:);
    for types = {'i', 'b', 'ri', 'rb', '', 'unknown'}
        test_row = base;
        test_row{1} = ['DOMAIN_', types{1}];
        test_row{3} = types{1};
        probinfo(end+1,:) = test_row; %#ok<AGROW>
    end
    save(fullfile(temporary, 'probinfo_matlab.mat'), 'probinfo');
    addpath(temporary, '-begin');
    clear s2mpj_select
    for variable_size = {'default', 'min', 'max', 'all'}
        for feasibility = 0:2
            fid = fopen(fullfile(temporary, 'config.txt'), 'w');
            assert(fid >= 0);
            fprintf(fid, 'variable_size=%s\ntest_feasibility_problems=%d\n', ...
                variable_size{1}, feasibility);
            fclose(fid);
            for oracle = 0:2
                names = s2mpj_select(struct('ptype', 'ubln', 'mindim', 1, ...
                    'maxdim', 10, 'oracle', oracle));
                assert(~ismember('NOZZLEfp', names));
                assert(~any(startsWith(names, 'DOMAIN_')));
                if feasibility ~= 1, assert(ismember('ROSENBR', names)); end
            end
        end
    end
    rmpath(temporary);
    clear s2mpj_select
    disp('S2MPJ continuous variable domain: PASS');
end

function assert_error(callback, identifier)
    try
        callback();
    catch ME
        assert(strcmp(ME.identifier, identifier), '%s: %s', ME.identifier, ME.message);
        return
    end
    error('S2MPJ:MissingRejection', 'Expected %s.', identifier);
end
