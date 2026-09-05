function test_constraint_hessians()
%TEST_CONSTRAINT_HESSIANS Check the adapter's signs and constraint ordering.
    repo = fileparts(fileparts(mfilename('fullpath')));
    previous_path = path;
    cleanup_path = onCleanup(@() path(previous_path));
    addpath(repo, fullfile(repo, 'tests', 'fixtures'));

    problem = s2mpj_load('HS13');
    H = problem.hcub(problem.x0);
    assert_close(H{1}, diag([-18, 0]));
    check_derivatives(problem, problem.x0);

    problem = s2mpj_load('ADAPTERCONSTRAINTS');
    x = problem.x0;
    [c, ~, H] = ADAPTERCONSTRAINTS('cJHx', x);
    assert_close(problem.cub(x), [c(1)-4; c(2)-5; -c(2)-3; -c(4)+2]);
    expected = {H{1}, H{2}, -H{2}, -H{4}};
    actual = problem.hcub(x);
    assert(numel(actual) == 4);
    for k = 1:4
        assert_close(actual{k}, expected{k});
    end
    equality = problem.hceq(x);
    assert_close(equality{1}, H{3});
    assert_close(problem.aub, [1, -2]);
    assert_close(problem.bub, 7);
    check_derivatives(problem, x);
    check_derivatives(problem, x + [0.2; -0.1]);

    problem = s2mpj_load('ROSENBR');
    assert(isempty(problem.hcub(problem.x0)));
    assert(isempty(problem.hceq(problem.x0)));
    disp('S2MPJ constraint Hessian signs, ordering and multipliers: PASS');
end

function check_derivatives(problem, x)
    assert_close(problem.jcub(x), central_jacobian(@(y) problem.cub(y), x));
    H = problem.hcub(x);
    assert(numel(H) == numel(problem.cub(x)));
    weights = 2:(numel(H) + 1);
    weights(2:2:end) = -weights(2:2:end);
    weighted = zeros(numel(x));
    for k = 1:numel(H)
        assert_close(H{k}, central_jacobian(@(y) jacobian_row(problem, y, k), x));
        weighted = weighted + weights(k) * H{k};
    end
    assert_close(weighted, central_jacobian(@(y) weights * problem.jcub(y), x));
end

function row = jacobian_row(problem, x, k)
    J = problem.jcub(x);
    row = J(k, :);
end

function J = central_jacobian(fun, x)
    step = 1e-6;
    basis = eye(numel(x));
    columns = cell(1, numel(x));
    for j = 1:numel(x)
        delta = (fun(x + step * basis(:, j)) - fun(x - step * basis(:, j))) / (2 * step);
        columns{j} = delta(:);
    end
    J = [columns{:}];
end

function assert_close(actual, expected)
    assert(isequal(size(actual), size(expected)));
    assert(all(isfinite(actual(:))) && all(isfinite(expected(:))));
    assert(max(abs(actual(:) - expected(:))) < 1e-7, 'Constraint derivative mismatch.');
end
