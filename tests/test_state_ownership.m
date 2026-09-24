function test_state_ownership()
%TEST_STATE_OWNERSHIP Public loader regressions for native persistent state.
    root = fileparts(fileparts(mfilename('fullpath')));
    old_path = path;
    cleanup = onCleanup(@() path(old_path)); %#ok<NASGU>
    addpath(root, fullfile(root, 'tests', 'fixtures'));

    a = s2mpj_load('BDQRTIC', 6);
    expected = snapshot(a);
    assert(a.fun(a.x0) == 452);
    b = s2mpj_load('BDQRTIC', 10);
    assert(b.fun(b.x0) == 1356);
    assert_same(snapshot(a), expected);
    assert(b.fun(b.x0) == 1356);
    assert(strcmp(class(a), 'Problem'));

    % Setup writes persistent state before it fails. A stale cache hit must
    % not allow the failed state to be observed by an existing valid object.
    a = s2mpj_load('STATEFAIL', 3);
    assert(a.fun(a.x0) == 6);
    for k = 1:2
        failed = false;
        try
            s2mpj_load('STATEFAIL', -1);
        catch ME
            failed = strcmp(ME.identifier, 'S2MPJ:FixtureSetupFailure');
        end
        assert(failed);
        assert(a.fun(a.x0) == 6);
    end

    for name = {'ROSENBR', 'HS13', 'HS68', 'HELIX'}
        p = s2mpj_load(name{1});
        before = snapshot(p);
        s2mpj_load('BDQRTIC', 10);
        assert_same(snapshot(p), before);
    end
    disp('S2MPJ state ownership: PASS');
end

function values = snapshot(p)
    x = p.x0;
    values = {p.fun(x), p.grad(x), p.hess(x), p.cub(x), p.ceq(x), ...
        p.jcub(x), p.jceq(x), p.hcub(x), p.hceq(x)};
end

function assert_same(actual, expected)
    assert(isequal(size(actual), size(expected)));
    if iscell(actual)
        for k = 1:numel(actual), assert_same(actual{k}, expected{k}); end
    else
        assert(all(isfinite(actual(:))) && all(isfinite(expected(:))));
        assert(all(abs(actual(:)-expected(:)) <= 1e-11*(1+abs(expected(:)))));
    end
end
