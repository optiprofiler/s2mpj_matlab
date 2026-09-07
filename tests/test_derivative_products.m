function test_derivative_products()
%TEST_DERIVATIVE_PRODUCTS Compare native products, Jacobians and differences.
    repo = fileparts(fileparts(mfilename('fullpath')));
    previous_path = path;
    cleanup = onCleanup(@() path(previous_path));
    addpath(fullfile(repo, 'src'), fullfile(repo, 'src', 'matlab_problems'), ...
        fullfile(repo, 'tests', 'fixtures'));
    pbm = struct('name', 'GROUPEDPRODUCTS', 'congrps', [1, 2], ...
        'has_globs', [false, false], ...
        'conderlvl', [2, 2], 'A', sparse([1, 2; -2, 1]), ...
        'gconst', [0.5; -1], 'gscale', [2; 3], 'grftype', {{'square', 'square'}});
    x = [0.7; -0.2];
    check_products(@(action, varargin) s2mpjlib(action, pbm, varargin{:}), x, 2);
    [~, J] = s2mpjlib('cIJx', pbm, x, [2, 1]);
    weights = [1.3; -0.4];
    assert_close(s2mpjlib('cIJtxv', pbm, x, weights, [2, 1]), J' * weights);
    for entry = {'HS65', 'HS71'}
        name = entry{1};
        pb = feval(name, 'setup');
        check_products(@(action, varargin) feval(name, action, varargin{:}), pb.x0, pb.m);
    end
    disp('S2MPJ MATLAB native Jacobian products and differences: PASS');
end

function check_products(call, x, m)
    [~, J] = call('cJx', x);
    v = linspace(0.2, 0.8, numel(x))';
    weights = linspace(-0.7, 1.3, m)';
    assert_close(call('cJxv', x, v), J * v);
    actual = call('cJtxv', x, weights);
    assert_close(actual, J' * weights);
    h = 1e-6;
    basis = eye(numel(x));
    difference = zeros(numel(x), 1);
    for k = 1:numel(x)
        difference(k) = weights' * (call('cx', x+h*basis(:,k)) ...
            - call('cx', x-h*basis(:,k))) / (2*h);
    end
    assert_close(actual, difference);
end

function assert_close(actual, expected)
    assert(isequal(size(actual), size(expected)));
    assert(all(isfinite(actual(:))) && all(isfinite(expected(:))));
    assert(all(abs(actual(:)-expected(:)) <= 1e-7 * (1+abs(expected(:)))), ...
        'Native constraint product mismatch.');
end
