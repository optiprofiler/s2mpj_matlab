function problem = s2mpj_load(problem_name, varargin)
%S2MPJ_LOAD coverts the S2MPJ problem name to a Problem class instance.
%
%   Users only need to use the following signature to call this function:
%
%   PROBLEM = S2MPJ_LOAD(PROBLEM_NAME) returns a Problem class instance PROBLEM
%   that corresponds to the problem named PROBLEM_NAME in S2MPJ. More details
%   about S2MPJ can be found in the official website:
%   <https://github.com/GrattonToint/S2MPJ>.
%
%   There are two ways to get PROBLEM_NAME you want.
%
%       1. Use the function `s2mpj_select` to get the problem names you want.
%
%       2. Look for a csv file named 'probinfo_matlab.csv' in the same
%          directory as this function. The csv file contains the information of
%          all the problems in S2MPJ.
%
%   Note that problem name may appear in the form of 'problem_name_dim_mcon'
%   where 'problem_name' is the name of the problem, 'dim' is the dimension of
%   the problem, and 'mcon' is the number of linear and nonlinear constraints
%   of the problem. This case only happens when this problem can accept extra
%   arguments to change the dimension or the number of constraints. This
%   information is stored in the 'probinfo_matlab.csv' file as the last few
%   columns.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Some details about S2MPJ.
%
%   Problems in S2MPJ are in the following form.
%       min f(x)
%       s.t. xlower <= x <= xupper  (xlower may be -Inf and xupper may be Inf)
%            ci(x) <= 0, i = 1, ..., nle,
%            ci(x) = 0, i = nle + 1, ..., nle + neq,
%            ci(x) >= 0, i = nle + neq + 1, ..., nle + neq + nge.
%   We call all ci(x) as general constraints, which can be linear or nonlinear.
%
%   The problem is loaded by 'setup' action in the problem function.
%       pb = problem_name('setup');
%   The problem structure pb contains the following main fields which we will
%   use in this function.
%       pb.n: dimension of the problem.
%       pb.nle: number of less-than-or-equal-to constraints.
%       pb.neq: number of equality constraints.
%       pb.nge: number of greater-than-or-equal-to constraints.
%       pb.m: total number of constraints (m = nle + neq + nge).
%       pb.lincons: indices of linear constraints in {1, ..., m}.
%       pb.x0: initial guess.
%       pb.xlower: lower bound.
%       pb.xupper: upper bound.
%       pb.xtype: type of variables
%                 ('r' (real), 'i' (integer), or 'b' (binary)).
%   Only continuous-variable models are supported. An explicit integer or
%   binary xtype raises S2MPJ:NoncontinuousVariables before any evaluation.
%   No variable is fixed, rounded or relaxed. Missing xtype follows the
%   upstream real-variable default; malformed declarations are rejected.
%
%   Invalid native metadata fails closed. A wrong shape, a NaN entry or an
%   impossible or crossed bound raises S2MPJ:InvalidMetadata (or
%   S2MPJ:SetupMetadata, when the setup output is unusable), and a linear constraint
%   whose values or Jacobian cannot be read at x0 raises
%   S2MPJ:LinearConstraintFailure with the original cause. No constraint is
%   dropped and no NaN matrix is built. Problems without linear constraints
%   need no Jacobian at load time.
%
%   The objective function will be evaluated by 'fx' action.
%       fx = problem_name('fx', x);
%   The general constraints and Jacobians will be evaluated by 'cJx' action.
%       [cx, Jx] = problem_name('cJx', x);
%   Note that we need to use Jacobians Jx to get the linear constraints.
%
%   We will use all the above information and functions to create a instance of
%   the Problem class containing the following fields.
%       name: name of the problem, same as problem_name. If there are varargin,
%             then it means that the problem is parameterized. Thus, in this
%             case, the name will be 'problem_name_n_m', where n is the
%             dimension of the problem and m is the number of constraints. When
%             m = 0, the name will be 'problem_name_n'.
%       fun: function handle to evaluate the objective function, which should
%            be a function handle calling the 'fx' action.
%       x0: initial guess, same as pb.x0.
%       xl: lower bound, same as pb.xlower.
%       xu: upper bound, same as pb.xupper.
%       aeq: matrix of equality constraint coefficients, which should be
%            Jx(idx_aeq, :) with idx_aeq = intersect(idx_eq, lincons) and
%            idx_eq = nle + 1 : nle + neq.
%       beq: vector of equality constraint values, which should be bx(idx_aeq)
%            with bx = Jx * x - cx (since we want aeq @ x = beq).
%       aub: matrix of inequality constraint coefficients, which should be
%            [Jx(idx_aub_le, :); -Jx(idx_aub_ge, :)] with
%            idx_aub_le = intersect(idx_le, lincons), idx_le = 1 : nle,
%            idx_aub_ge = intersect(idx_ge, lincons), and
%            idx_ge = nle + neq + 1 : nle + neq + nge.
%       bub: vector of inequality constraint values, which should be
%            [bx(idx_aub_le); -bx(idx_aub_ge)] (since we want aub @ x <= bub).
%       ceq: function handle to evaluate the nonlinear equality constraints,
%            the value of which at x should be cx(idx_ceq) with
%            idx_ceq = intersect(idx_eq, nonlincons) and
%            nonlincons = {1, ..., m} \ lincons.
%       cub: function handle to evaluate the nonlinear inequality constraints,
%            the value of which at x should be [cx(idx_cle), -cx(idx_cge)] with
%            idx_cle = intersect(idx_le, nonlincons),
%            idx_cge = intersect(idx_ge, nonlincons).
%
%   In 's2mpj_load' may receive varargin to load the problem when
%   the problem is parameterized. However, in 'solveOneProblem.m', this will
%   not happen since the selector 's2mpj_select' will first convert the names
%   of parameterized problems to "problem_name_n" and then call 's2mpj_load'
%   without varargin.
%

    % Add the path of the problem to the MATLAB search path.
    try
        addpath(fullfile(fileparts(mfilename('fullpath')), 'src'));
        addpath(fullfile(fileparts(mfilename('fullpath')), 'src', 'matlab_problems'));
    catch
        error('Failed to add the path of MATLAB problems of S2MPJ to the MATLAB search path.');
    end

    % Convert 'problem_name' to a char.
    problem_name = char(problem_name);

    % Check if 'problem_name' has the pattern '_n_m' or '_n_0'.
    [is_problem_parameterized, problem_name, dim, mcon] = isproblem_parameterized(problem_name);

    if is_problem_parameterized
        % Use the absolute path: other libraries ship a file with the same name.
        load(fullfile(fileparts(mfilename('fullpath')), 'probinfo_matlab.mat'), 'probinfo');
        idx_pb = find(strcmp(probinfo(:, 1), problem_name), 1, 'first');
        if isempty(idx_pb)
            error('Problem %s not found in probinfo_matlab.mat.', problem_name);
        end
        % Find the corresponding argins for the specific dimension.
        argins = probinfo{idx_pb, 25};
        dims = probinfo{idx_pb, 26};
        mcons = probinfo{idx_pb, 30};
        idx_dim = find(dims == dim & mcons == mcon, 1, 'first');
        if iscell(argins)
            argin = {argins{1:end-1}, argins{end}(idx_dim)};
        else
            argin = argins(idx_dim);
        end

        % Load the problem with the specific dimension.
        if iscell(argin)
            problem = s2mpj_load(problem_name, argin{:});
        else
            problem = s2mpj_load(problem_name, argin);
        end
        return;
    end

    % List of feasibility problems.
    feasibility_list = {...
        'AIRCRFTA', 'ARGAUSS', 'ARGLALE', 'ARGLBLE', 'ARGTRIG', 'ARTIF', 'BARDNE', 'BAmL1SP', 'BEALENE', 'BENNETT5', 'BIGGS6NE', 'BOOTH', 'BOXBOD', 'BRATU2D', 'BRATU2DT', 'BRATU3D', 'BROWNBSNE', 'BROWNDENE', 'BROYDN3D', 'CBRATU2D', 'CBRATU3D', 'CHANDHEQ', 'CHEMRCTA', 'CHWIRUT2', 'CLUSTER', 'COOLHANS', 'CUBENE', 'CYCLIC3', 'CYCLOOCF', 'CYCLOOCT', 'DANIWOOD', 'DANWOOD', 'DECONVBNE', 'DENSCHNBNE', 'DENSCHNDNE', 'DENSCHNFNE', 'DEVGLA1NE', 'DEVGLA2NE', 'DRCAVTY1', 'DRCAVTY2', 'DRCAVTY3', 'ECKERLE4', 'EGGCRATENE', 'EIGENA', 'EIGENB', 'ELATVIDUNE', 'ENGVAL2NE', 'ENSO', 'ERRINROSNE', 'ERRINRSMNE', 'EXP2NE', 'EXTROSNBNE', 'FLOSP2HH', 'FLOSP2HL', 'FLOSP2HM', 'FLOSP2TH', 'FLOSP2TL', 'FLOSP2TM', 'FREURONE', 'GENROSEBNE', 'GOTTFR', 'GROWTH', 'GULFNE', 'HAHN1', 'HATFLDANE', 'HATFLDBNE', 'HATFLDCNE', 'HATFLDDNE', 'HATFLDENE', 'HATFLDF', 'HATFLDFLNE', 'HATFLDG', 'HELIXNE', 'HIMMELBA', 'HIMMELBC', 'HIMMELBD', 'HIMMELBFNE', 'HS1NE', 'HS25NE', 'HS2NE', 'HS8', 'HYDCAR20', 'HYDCAR6', 'HYPCIR', 'INTEGREQ', 'INTEQNE', 'KOEBHELBNE', 'KOWOSBNE', 'KSS', 'LANCZOS1', 'LANCZOS2', 'LANCZOS3', 'LEVYMONE', 'LEVYMONE10', 'LEVYMONE5', 'LEVYMONE6', 'LEVYMONE7', 'LEVYMONE8', 'LEVYMONE9', 'LIARWHDNE', 'LINVERSENE', 'LSC1', 'LSC2', 'LUKSAN11', 'LUKSAN12', 'LUKSAN13', 'LUKSAN14', 'LUKSAN17', 'LUKSAN21', 'LUKSAN22', 'MANCINONE', 'METHANB8', 'METHANL8', 'MEYER3NE', 'MGH09', 'MGH10', 'MISRA1A', 'MISRA1B', 'MISRA1C', 'MISRA1D', 'MODBEALENE', 'MSQRTA', 'MSQRTB', 'MUONSINE', 'NELSON', 'NONSCOMPNE', 'NYSTROM5', 'OSBORNE1', 'OSBORNE2', 'OSCIGRNE', 'OSCIPANE', 'PALMER1ANE', 'PALMER1BNE', 'PALMER1ENE', 'PALMER1NE', 'PALMER2ANE', 'PALMER2BNE', 'PALMER2ENE', 'PALMER3ANE', 'PALMER3BNE', 'PALMER3ENE', 'PALMER4ANE', 'PALMER4BNE', 'PALMER4ENE', 'PALMER5ANE', 'PALMER5BNE', 'PALMER5ENE', 'PALMER6ANE', 'PALMER6ENE', 'PALMER7ANE', 'PALMER7ENE', 'PALMER8ANE', 'PALMER8ENE', 'PENLT1NE', 'PENLT2NE', 'POROUS1', 'POROUS2', 'POWELLBS', 'POWELLSQ', 'POWERSUMNE', 'PRICE3NE', 'PRICE4NE', 'QINGNE', 'QR3D', 'RAT42', 'RAT43', 'RECIPE', 'REPEAT', 'RES', 'ROSSIMP1NE', 'ROSZMAN1', 'RSNBRNE', 'SANTA', 'SEMICN2U', 'SEMICON1', 'SEMICON2', 'SPECANNE', 'SSBRYBNDNE', 'SSINE', 'THURBER', 'TQUARTICNE', 'VANDERM1', 'VANDERM2', 'VANDERM3', 'VANDERM4', 'VARDIMNE', 'VESUVIA', 'VESUVIO', 'VESUVIOU', 'VIBRBEAMNE', 'WATSONNE', 'WAYSEA1NE', 'WAYSEA2NE', 'YATP1CNE', 'YATP2CNE', 'YFITNE', 'ZANGWIL3', 'n10FOLDTR'...
    };
    is_feasibility = ismember(problem_name, feasibility_list);

    % Bind source identity and original arguments without serializing native
    % persistent state. Each callback activates its own setup configuration.
    oracle = S2mpjOracle(problem_name, varargin);
    funcHandle = @(varargin) oracle.call(varargin{:});
    pb = oracle.setup();
    % problem_name = pb.name;

    if nargin < 2
        name = problem_name;
    else
        name = [problem_name, '_', num2str(pb.n)];
    end

    % Get the objective function.
    fun = @(x) oracle.objective(x, 0, is_feasibility);

    % Get the gradient of the objective function.
    grad = @(x) oracle.objective(x, 1, is_feasibility);

    % Get the Hessian of the objective function.
    hess = @(x) oracle.objective(x, 2, is_feasibility);

    % Validate native metadata before building masks: a mask built on NaN
    % would silently drop the corresponding bound or constraint.
    x0 = native_vector(problem_name, 'initial point', pb.x0, pb.n);
    xl = native_vector(problem_name, 'variable lower bounds', pb.xlower, pb.n);
    xu = native_vector(problem_name, 'variable upper bounds', pb.xupper, pb.n);
    if any(xl >= 1.0e+20) || any(xu <= -1.0e+20) || any(xl > xu)
        error('S2MPJ:InvalidMetadata', 'Impossible variable bounds for S2MPJ problem %s.', problem_name);
    end
    % Replace 1.0e+20 (which represents infinity) bounds with Inf.
    xl(xl <= -1.0e+20) = -Inf;
    xu(xu >= 1.0e+20) = Inf;

    if pb.m > 0
        if ~isfield(pb, 'clower') || ~isfield(pb, 'cupper')
            error('S2MPJ:InvalidMetadata', ...
                'Invalid constraint bounds for S2MPJ problem %s: it declares %d constraints without clower and cupper.', ...
                problem_name, pb.m);
        end
        cl = native_vector(problem_name, 'constraint lower bounds', pb.clower, pb.m);
        cu = native_vector(problem_name, 'constraint upper bounds', pb.cupper, pb.m);
    else
        cl = zeros(0, 1);
        cu = zeros(0, 1);
    end
    if any(cl >= 1.0e+20) || any(cu <= -1.0e+20) || any(cl > cu)
        error('S2MPJ:InvalidMetadata', 'Impossible constraint bounds for S2MPJ problem %s.', problem_name);
    end
    cl(cl <= -1.0e+20) = -Inf;
    cu(cu >= 1.0e+20) = Inf;
    idx_cl_finite = find(isfinite(cl));
    idx_cu_finite = find(isfinite(cu));

    if ~isfield(pb, 'lincons')
        pb.lincons = [];
    end
    if ~isfield(pb, 'nle')
        pb.nle = 0;
    end
    if ~isfield(pb, 'neq')
        pb.neq = 0;
    end
    if ~isfield(pb, 'nge')
        pb.nge = 0;
    end

    idx_native_eq = pb.nle + 1 : pb.nle + pb.neq;
    if any(idx_native_eq > pb.m) || any(cl(idx_native_eq) ~= cu(idx_native_eq)) ...
            || ~all(isfinite(cl(idx_native_eq)))
        error('S2MPJ:InvalidMetadata', ...
            'Invalid equality constraints for S2MPJ problem %s: each needs equal finite bounds.', problem_name);
    end

    nonlincons = setdiff(1:pb.m, pb.lincons);
    idx_eq = intersect(pb.nle + 1 : pb.nle + pb.neq, idx_cl_finite);
    idx_ineq = setdiff(1:pb.m, pb.nle + 1 : pb.nle + pb.neq);
    idx_le = intersect(idx_ineq, idx_cu_finite);
    idx_ge = intersect(idx_ineq, idx_cl_finite);
    idx_aeq = intersect(idx_eq, pb.lincons);
    idx_aub_le = intersect(idx_le, pb.lincons);
    idx_aub_ge = intersect(idx_ge, pb.lincons);
    idx_cle = intersect(idx_le, nonlincons);
    idx_ceq = intersect(idx_eq, nonlincons);
    idx_cge = intersect(idx_ge, nonlincons);

    % The linear constraints are hidden in the cJx method output,
    % cx = Jx @ x - bx. Read them only when needed: many models do not assign
    % those outputs. Fail closed, because NaN matrices would describe a less
    % constrained problem and a dropped row would be silently feasible.
    idx_linear = union(idx_aeq, union(idx_aub_le, idx_aub_ge));
    Jx = sparse(pb.m, numel(x0));
    bx = zeros(pb.m, 1);
    if ~isempty(idx_linear)
        try
            [~] = evalc('[cx, Jx] = funcHandle("cJx", x0)');
            if numel(cx) ~= pb.m || ~isequal(size(Jx), [pb.m, numel(x0)])
                error('S2MPJ:InvalidMetadata', 'Unexpected native constraint/Jacobian shape.');
            end
            cx = cx(:);
            bx = full(Jx * x0 - cx);
            if ~all(isfinite(cx(idx_linear))) || ~all(isfinite(nonzeros(Jx(idx_linear, :)))) ...
                    || ~all(isfinite(bx(idx_linear)))
                error('S2MPJ:InvalidMetadata', 'Non-finite linear constraint data.');
            end
        catch cause
            failure = MException('S2MPJ:LinearConstraintFailure', ...
                'Failed to load linear constraints for S2MPJ problem %s.', problem_name);
            throw(addCause(failure, cause));
        end
    end

    % Note that in S2MPJ, the constraints are defined as:
    %  cl <= c(x) <= cu
    % Thus, the linear equality constraints are:
    %  Jx(idx_aeq, :) @ x = bx(idx_aeq) + cu(idx_aeq)
    % and the linear inequality constraints are:
    %  Jx(idx_aub_le, :) @ x <= bx(idx_aub_le) + cu(idx_aub_le)
    %  -jx(idx_aub_ge, :) @ x <= -bx(idx_aub_ge) - cl(idx_aub_ge)
    aeq = Jx(idx_aeq, :);
    aeq = full(aeq);
    aub = [Jx(idx_aub_le, :); -Jx(idx_aub_ge, :)];
    aub = full(aub);
    beq = bx(idx_aeq) + cu(idx_aeq);
    beq = full(beq);
    bub = [bx(idx_aub_le) + cu(idx_aub_le); -bx(idx_aub_ge) - cl(idx_aub_ge)];
    bub = full(bub);

    % Construct nonlinear constraint functions
    % Remind that in S2MPJ, the constraints are defined as:
    %  cl <= c(x) <= cu
    % Thus, the nonlinear equality constraints are:
    %  ceq(x) = c(x)(idx_ceq) - cu(idx_ceq) = 0
    % and the nonlinear inequality constraints are:
    %  cub(x) = [c(x)(idx_cle) - cu(idx_cle);
    %           -c(x)(idx_cge) + cl(idx_cge)] <= 0
    ineq_indices = [idx_cle(:); idx_cge(:)];
    ineq_signs = [ones(numel(idx_cle),1); -ones(numel(idx_cge),1)];
    ineq_offsets = [-cu(idx_cle); cl(idx_cge)];
    eq_signs = ones(numel(idx_ceq),1);
    eq_offsets = -cu(idx_ceq);
    ceq = @(x) oracle.constraints(x, idx_ceq, eq_signs, eq_offsets, 0);
    cub = @(x) oracle.constraints(x, ineq_indices, ineq_signs, ineq_offsets, 0);
    hceq = @(x) oracle.constraints(x, idx_ceq, eq_signs, eq_offsets, 2);
    hcub = @(x) oracle.constraints(x, ineq_indices, ineq_signs, ineq_offsets, 2);
    jceq = @(x) oracle.constraints(x, idx_ceq, eq_signs, eq_offsets, 1);
    jcub = @(x) oracle.constraints(x, ineq_indices, ineq_signs, ineq_offsets, 1);
    
    problem = Problem(struct('name', name, 'fun', fun, 'grad', grad, 'hess', hess, 'x0', x0, 'xl', xl, 'xu', xu, 'aeq', aeq, 'beq', beq, 'aub', aub, 'bub', bub, 'ceq', ceq, 'cub', cub, 'jceq', jceq, 'jcub', jcub, 'hceq', hceq, 'hcub', hcub));
    
end

function vector = native_vector(problem_name, label, values, expected)
    % Return native metadata as a column, rejecting a wrong shape or NaN.
    if ~isnumeric(values) && ~islogical(values)
        error('S2MPJ:InvalidMetadata', ...
            'Invalid %s for S2MPJ problem %s: the values are not numeric.', label, problem_name);
    end
    vector = full(double(values));
    if numel(vector) ~= expected || ~isvector(vector)
        error('S2MPJ:InvalidMetadata', ...
            'Invalid %s for S2MPJ problem %s: expected %d entries, found size [%s].', ...
            label, problem_name, expected, num2str(size(vector)));
    end
    if any(isnan(vector))
        error('S2MPJ:InvalidMetadata', ...
            ['Invalid %s for S2MPJ problem %s: NaN entries leave a bound undefined, ' ...
             'and it must not silently disappear.'], label, problem_name);
    end
    vector = vector(:);
end

% Preserve these local names/signatures for anonymous callbacks saved by the
% pre-oracle loader. Such objects do not contain enough setup information to
% restore native state automatically; rebuild them with the original arguments.
function fx = getfun(problem_name, is_feasibility, x)
    
    if is_feasibility && ~strcmp(problem_name, 'HS8')
        % For feasibility problems, we set the objective function value to 0.
        % Note that 'HS8' has a constant objective function (-1).
        fx = 0;
        return;
    end

    funcHandle = str2func(problem_name);
    try
        evalc("fx = funcHandle('fx', x)");
        fx = full(fx);
    catch ME
        warn_s2mpj_evaluation_failure(problem_name, 'the objective function', ME);
        fx = NaN;
    end
end

function gx = getgrad(problem_name, is_feasibility, x)

    if is_feasibility
        % For feasibility problems, we set the gradient to 0.
        gx = zeros(size(x));
        return;
    end
    
    funcHandle = str2func(problem_name);
    try
        evalc("[~, gx] = funcHandle('fgx', x)");
        gx = full(gx);
    catch ME
        warn_s2mpj_evaluation_failure(problem_name, 'the gradient of the objective function', ME);
        gx = NaN(size(x));
    end
end

function Hx = gethess(problem_name, is_feasibility, x)

    if is_feasibility
        % For feasibility problems, we set the Hessian to 0.
        Hx = zeros(numel(x));
        return;
    end
    
    funcHandle = str2func(problem_name);
    try
        evalc("[~, ~, Hx] = funcHandle('fgHx', x)");
        Hx = full(Hx);
    catch ME
        warn_s2mpj_evaluation_failure(problem_name, 'the Hessian of the objective function', ME);
        Hx = NaN(numel(x));
    end
end

function cx = getcx(problem_name, mcon, x)

    if mcon == 0
        cx = NaN(0, 1);
        return;
    end
    
    funcHandle = str2func(problem_name);
    try
        evalc("cx = funcHandle('cx', x)");
        cx = full(cx);
        % Check if cx is a row vector, if yes, transpose it to a column vector.
        if size(cx, 1) == 1
            cx = cx';
        end
    catch ME
        warn_s2mpj_evaluation_failure(problem_name, 'the nonlinear constraint function', ME);
        cx = NaN(mcon, 1);
    end
end

function Jx = getJx(problem_name, mcon, nvar, x)

    if mcon == 0
        Jx = NaN(0, nvar);
        return;
    end
    
    funcHandle = str2func(problem_name);
    try
        evalc("[~, Jx] = funcHandle('cJx', x)");
        Jx = full(Jx);
    catch ME
        warn_s2mpj_evaluation_failure(problem_name, 'the Jacobian of the nonlinear constraint function', ME);
        Jx = NaN(mcon, nvar);
    end
end

function Hx = getHx(problem_name, mcon, nvar, x)

    if mcon == 0
        Hx = cell(0, 1);
        return;
    end
    
    funcHandle = str2func(problem_name);
    try
        evalc("[~, ~, Hx] = funcHandle('cJHx', x)");
        for i = 1:size(Hx, 2)
            Hx{i} = full(Hx{i});
        end
    catch ME
        warn_s2mpj_evaluation_failure(problem_name, 'the Hessian of the nonlinear constraint function', ME);
        Hx = cell(1, mcon);
        for i = 1:mcon
            Hx{i} = NaN(nvar, nvar);
        end
    end
end

function ceqx = getceq(problem_name, mcon, x, idx_ceq, cu)
    if isempty(idx_ceq)
        ceqx = NaN(0, 1);
        return;
    end
    cx = getcx(problem_name, mcon, x);
    ceqx = cx(idx_ceq) - cu(idx_ceq);
end

function cubx = getcub(problem_name, mcon, x, idx_cle, idx_cge, cu, cl)
    if isempty(idx_cle) && isempty(idx_cge)
        cubx = NaN(0, 1);
        return;
    end
    cx = getcx(problem_name, mcon, x);
    cubx = [cx(idx_cle) - cu(idx_cle); -cx(idx_cge) + cl(idx_cge)];
end

function jceqx = getjceq(problem_name, mcon, nvar, x, idx_ceq)
    if isempty(idx_ceq)
        jceqx = NaN(0, nvar);
        return;
    end
    Jx = getJx(problem_name, mcon, nvar, x);
    jceqx = Jx(idx_ceq, :);
end

function jcubx = getjcub(problem_name, mcon, nvar, x, idx_cle, idx_cge)
    if isempty(idx_cle) && isempty(idx_cge)
        jcubx = NaN(0, nvar);
        return;
    end
    Jx = getJx(problem_name, mcon, nvar, x);
    jcubx = [Jx(idx_cle, :); -Jx(idx_cge, :)];
end

function hceqx = gethceq(problem_name, mcon, nvar, x, idx_ceq)
    if isempty(idx_ceq)
        hceqx = cell(0, 1);
        return;
    end
    Hx = getHx(problem_name, mcon, nvar, x);
    hceqx = Hx(idx_ceq);
end

function hcubx = gethcub(problem_name, mcon, nvar, x, idx_cle, idx_cge)
    if isempty(idx_cle) && isempty(idx_cge)
        hcubx = cell(0, 1);
        return;
    end
    Hx = getHx(problem_name, mcon, nvar, x);
    % Lower bounds use cl - c(x), so both derivative orders change sign.
    lower_Hx = cellfun(@(H) -H, Hx(idx_cge), 'UniformOutput', false);
    hcubx = [Hx(idx_cle), lower_Hx];
end

function warn_s2mpj_evaluation_failure(problem_name, what, ME)
    print_s2mpj_warning(sprintf( ...
        'Failed to evaluate %s of problem %s: %s', what, problem_name, shorten_exception_message(ME)));
end

function msg = shorten_exception_message(ME)
    msg = strtrim(ME.message);
    if isempty(msg)
        msg = strtrim(ME.identifier);
    elseif ~isempty(ME.identifier)
        msg = sprintf('%s: %s', ME.identifier, msg);
    end
    msg = regexprep(msg, '[\f\n\r\t\v]+', ' ');
    max_len = 180;
    if numel(msg) > max_len
        msg = [msg(1:max_len - 3), '...'];
    end
end

function print_s2mpj_warning(message)
    width = 104;
    prefix = sprintf('[%-7s] ', 'WARNING');
    message = strtrim(regexprep(char(message), '[\f\n\r\t\v]+', ' '));
    if isempty(message)
        return;
    end
    body_width = max(20, width - numel(prefix));
    lines = wrap_s2mpj_text(message, body_width);
    fprintf('%s%s\n', prefix, lines{1});
    continuation_prefix = repmat(' ', 1, numel(prefix));
    for i_line = 2:numel(lines)
        fprintf('%s%s\n', continuation_prefix, lines{i_line});
    end
end

function lines = wrap_s2mpj_text(message, width)
    lines = {};
    remaining = message;
    while numel(remaining) > width
        chunk = remaining(1:width);
        break_idx = find(isspace(chunk), 1, 'last');
        if isempty(break_idx) || break_idx < 1
            break_idx = width;
        end
        lines{end + 1} = strtrim(remaining(1:break_idx)); %#ok<AGROW>
        remaining = strtrim(remaining(break_idx + 1:end));
    end
    lines{end + 1} = remaining;
end

function [result, problem_name, dim, mcon] = isproblem_parameterized(problem_name)
    % Check if 'problem_name' has the pattern '_n_m' or 'n'. If it has, find
    % the position of the pattern and return the dimension 'n' and the number
    % of constraints 'm'.

    % Find the position of the pattern '_n_m' or '_n'.
    [match, idx] = regexp(problem_name, '_\d+_\d+', 'match', 'start');
    if isempty(match)
        [match, idx] = regexp(problem_name, '_\d+', 'match', 'start');
        if isempty(match)
            result = false;
            dim = 0;
            mcon = 0;
        else
            problem_name = problem_name(1:idx-1);
            results = sscanf(match{1}, '_%d');
            dim = results(1);
            mcon = 0;
            result = true;
        end
        return;
    end

    % Find the dimension 'n' and the number of constraints 'm'.
    problem_name = problem_name(1:idx-1);
    results = sscanf(match{1}, '_%d_%d');
    dim = results(1);
    mcon = results(2);
    result = true;
end
