function test_state_lifecycle(stage, filename)
%TEST_STATE_LIFECYCLE Use separate MATLAB sessions for save/restore stages.
% A legacy fixture must be generated with the actual pre-oracle loader.
    cases = {{'ROSENBR'}, {'BDQRTIC',6}, {'BDQRTIC',10}, {'HS13'}, {'HS68'}, {'HELIX'}};
    switch stage
        case {'save','save_legacy'}
            problems = cell(size(cases)); expected = cell(size(cases));
            for k = 1:numel(cases)
                problems{k} = s2mpj_load(cases{k}{:});
                expected{k} = snapshot(problems{k});
            end
            save(filename,'problems','expected','cases');
            if strcmp(stage,'save')
                oracle=S2mpjOracle('ROSENBR',{}); oracle.setup();
                save(filename,'oracle','-append');
                record=oracle.saveobj();
                save([filename,'.record.mat'],'record');
            end
        case 'restore'
            data = load(filename);
            for k = [2,3,2,1,4,5,6]
                assert_same(snapshot(data.problems{k}),data.expected{k});
            end
            record=data.oracle.saveobj();
            root=fileparts(which('S2mpjOracle'));
            assert(startsWith(record.source_paths{1},[root,filesep]));
        case 'legacy'
            data = load(filename);
            % Missing setup arguments are not reconstructed from old closures.
            % Explicitly rebuilding with the known original fixture arguments
            % verifies old callback names/signatures, not automatic recovery.
            for k = 1:numel(data.cases)
                s2mpj_load(data.cases{k}{:});
                assert_same(snapshot(data.problems{k}),data.expected{k});
            end
        case 'worker'
            data = load(filename);
            pool = gcp('nocreate');
            created = isempty(pool);
            if created, pool = parpool('Processes',2); end
            cleanup = onCleanup(@() close_owned_pool(pool,created)); %#ok<NASGU>
            a = parfeval(pool,@worker_snapshots,1,data.problems(2:3));
            b = parfeval(pool,@worker_snapshots,1,data.problems(4:6));
            assert_same(fetchOutputs(a),data.expected(2:3));
            assert_same(fetchOutputs(b),data.expected(4:6));
        otherwise
            error('S2MPJ:TestStage','Unknown lifecycle test stage.');
    end
    fprintf('S2MPJ lifecycle %s: PASS\n',stage);
end

function values = worker_snapshots(problems)
    values = cell(size(problems));
    for k=1:numel(problems), values{k}=snapshot(problems{k}); end
    for k=numel(problems):-1:1, assert_same(snapshot(problems{k}),values{k}); end
end
function values = snapshot(p)
    x=p.x0;
    values={p.fun(x),p.grad(x),p.hess(x),p.cub(x),p.ceq(x),p.jcub(x),p.jceq(x),p.hcub(x),p.hceq(x)};
end
function assert_same(actual,expected)
    assert(isequal(size(actual),size(expected)));
    if iscell(actual)
        for k=1:numel(actual), assert_same(actual{k},expected{k}); end
    else
        assert(all(isfinite(actual(:))) && all(isfinite(expected(:))));
        assert(all(abs(actual(:)-expected(:))<=1e-11*(1+abs(expected(:)))));
    end
end
function close_owned_pool(pool,created)
    if created && isvalid(pool), delete(pool); end
end
