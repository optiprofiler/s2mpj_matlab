function s_getInfo()
%S_GETINFO Collect problem information from S2MPJ MATLAB problem set.
%
%   This script scans all problems in the S2MPJ MATLAB collection and extracts
%   various metrics including dimensions, constraint counts, and function values.
%   The results are saved to CSV and MAT files for later use by OptiProfiler.

    % Set the timeout (seconds) for each problem to be loaded
    timeout = 50;

    % Get the repository root directory (three levels up from this script)
    current_path = fileparts(mfilename('fullpath'));
    repo_root = fullfile(current_path, '..', '..', '..');
    repo_root = char(java.io.File(repo_root).getCanonicalPath());

    % Add optiprofiler paths (checked out by GitHub Actions)
    addpath(fullfile(repo_root, 'optiprofiler'));
    addpath(fullfile(repo_root, 'optiprofiler', 'problems'));
    addpath(fullfile(repo_root, 'optiprofiler', 'problems', 's2mpj'));

    % Read problem list from src directory
    filename = fullfile(repo_root, 'src', 'list_of_matlab_problems');
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end
    problem_names = textscan(fid, '%s');
    fclose(fid);
    problem_names = problem_names{1};

    % Exclude problematic problems that are known to cause issues
    problem_exclude = {
        'SPARCO10LS.m'; 'SPARCO10.m'; 'SPARCO11LS.m'; 'SPARCO11.m';
        'SPARCO12LS.m'; 'SPARCO12.m'; 'SPARCO2LS.m'; 'SPARCO2.m';
        'SPARCO3LS.m'; 'SPARCO3.m'; 'SPARCO5LS.m'; 'SPARCO5.m';
        'SPARCO7LS.m'; 'SPARCO7.m'; 'SPARCO8LS.m'; 'SPARCO8.m';
        'SPARCO9LS.m'; 'SPARCO9.m'; 'ROSSIMP3_mp.m';
        'HS67.m'; 'HS68.m'; 'HS69.m'; 'HS85.m';
        'HS88.m'; 'HS89.m'; 'HS90.m'; 'HS91.m'; 'HS92.m'
    };
    problem_names = setdiff(problem_names, problem_exclude);

    % List of known feasibility problems (objective function is not meaningful)
    known_feasibility = {
        'AIRCRFTA', 'ARGAUSS', 'ARGLALE', 'ARGLBLE', 'ARGTRIG', 'ARTIF',
        'BARDNE', 'BAmL1SP', 'BEALENE', 'BENNETT5', 'BIGGS6NE', 'BOOTH',
        'BOXBOD', 'BRATU2D', 'BRATU2DT', 'BRATU3D', 'BROWNBSNE', 'BROWNDENE',
        'BROYDN3D', 'CBRATU2D', 'CBRATU3D', 'CHANDHEQ', 'CHANDHEU', 'CHEMRCTA',
        'CHWIRUT2', 'CLUSTER', 'COOLHANS', 'CUBENE', 'CYCLIC3', 'CYCLOOCF',
        'CYCLOOCT', 'DANIWOOD', 'DANWOOD', 'DECONVBNE', 'DENSCHNBNE',
        'DENSCHNDNE', 'DENSCHNFNE', 'DEVGLA1NE', 'DEVGLA2NE', 'DIAMON2D',
        'DIAMON3D', 'DMN15102', 'DMN15103', 'DMN15332', 'DMN15333',
        'DMN37142', 'DMN37143', 'DRCAVTY1', 'DRCAVTY2', 'DRCAVTY3',
        'ECKERLE4', 'EGGCRATENE', 'EIGENA', 'EIGENB', 'ELATVIDUNE',
        'ENGVAL2NE', 'ENSO', 'ERRINROSNE', 'ERRINRSMNE', 'EXP2NE',
        'EXTROSNBNE', 'FLOSP2HH', 'FLOSP2HL', 'FLOSP2HM', 'FLOSP2TH',
        'FLOSP2TL', 'FLOSP2TM', 'FREURONE', 'GENROSEBNE', 'GOTTFR',
        'GROWTH', 'GULFNE', 'HAHN1', 'HATFLDANE', 'HATFLDBNE', 'HATFLDCNE',
        'HATFLDDNE', 'HATFLDENE', 'HATFLDF', 'HATFLDFLNE', 'HATFLDG',
        'HELIXNE', 'HIMMELBA', 'HIMMELBC', 'HIMMELBD', 'HIMMELBFNE',
        'HS1NE', 'HS25NE', 'HS2NE', 'HS8', 'HYDCAR20', 'HYDCAR6', 'HYPCIR',
        'INTEGREQ', 'INTEQNE', 'KOEBHELBNE', 'KOWOSBNE', 'KSS', 'LANCZOS1',
        'LANCZOS2', 'LANCZOS3', 'LEVYMONE', 'LEVYMONE10', 'LEVYMONE5',
        'LEVYMONE6', 'LEVYMONE7', 'LEVYMONE8', 'LEVYMONE9', 'LIARWHDNE',
        'LINVERSENE', 'LSC1', 'LSC2', 'LUKSAN11', 'LUKSAN12', 'LUKSAN13',
        'LUKSAN14', 'LUKSAN17', 'LUKSAN21', 'LUKSAN22', 'MANCINONE',
        'METHANB8', 'METHANL8', 'MEYER3NE', 'MGH09', 'MGH10', 'MISRA1A',
        'MISRA1B', 'MISRA1C', 'MISRA1D', 'MODBEALENE', 'MSQRTA', 'MSQRTB',
        'MUONSINE', 'NELSON', 'NONSCOMPNE', 'NYSTROM5', 'OSBORNE1',
        'OSBORNE2', 'OSCIGRNE', 'OSCIPANE', 'PALMER1ANE', 'PALMER1BNE',
        'PALMER1ENE', 'PALMER1NE', 'PALMER2ANE', 'PALMER2BNE', 'PALMER2ENE',
        'PALMER3ANE', 'PALMER3BNE', 'PALMER3ENE', 'PALMER4ANE', 'PALMER4BNE',
        'PALMER4ENE', 'PALMER5ANE', 'PALMER5BNE', 'PALMER5ENE', 'PALMER6ANE',
        'PALMER6ENE', 'PALMER7ANE', 'PALMER7ENE', 'PALMER8ANE', 'PALMER8ENE',
        'PENLT1NE', 'PENLT2NE', 'POROUS1', 'POROUS2', 'POWELLBS', 'POWELLSQ',
        'POWERSUMNE', 'PRICE3NE', 'PRICE4NE', 'QINGNE', 'QR3D', 'RAT42',
        'RAT43', 'RECIPE', 'REPEAT', 'RES', 'ROSSIMP1NE', 'ROSZMAN1',
        'RSNBRNE', 'SANTA', 'SEMICN2U', 'SEMICON1', 'SEMICON2', 'SPECANNE',
        'SSBRYBNDNE', 'SSINE', 'THURBER', 'TQUARTICNE', 'VANDERM1',
        'VANDERM2', 'VANDERM3', 'VANDERM4', 'VARDIMNE', 'VESUVIA', 'VESUVIO',
        'VESUVIOU', 'VIBRBEAMNE', 'WATSONNE', 'WAYSEA1NE', 'WAYSEA2NE',
        'YATP1CNE', 'YATP2CNE', 'YFITNE', 'ZANGWIL3', 'n10FOLDTR'
    };

    % To store discovered feasibility problems and timeout problems
    feasibility = {};
    timeout_problems = {};

    % Output path (repository root)
    saving_path = repo_root;

    % Initialize the structure to store data (header row + data rows)
    probinfo = cell(length(problem_names) + 1, 24);
    probinfo{1, 1} = 'name';
    probinfo{1, 2} = 'ptype';
    probinfo{1, 3} = 'xtype';
    probinfo{1, 4} = 'dim';
    probinfo{1, 5} = 'mb';
    probinfo{1, 6} = 'ml';
    probinfo{1, 7} = 'mu';
    probinfo{1, 8} = 'mcon';
    probinfo{1, 9} = 'mlcon';
    probinfo{1, 10} = 'mnlcon';
    probinfo{1, 11} = 'm_ub';
    probinfo{1, 12} = 'm_eq';
    probinfo{1, 13} = 'm_linear_ub';
    probinfo{1, 14} = 'm_linear_eq';
    probinfo{1, 15} = 'm_nonlinear_ub';
    probinfo{1, 16} = 'm_nonlinear_eq';
    probinfo{1, 17} = 'f0';
    probinfo{1, 18} = 'isfeasibility';
    probinfo{1, 19} = 'isgrad';
    probinfo{1, 20} = 'ishess';
    probinfo{1, 21} = 'isjcub';
    probinfo{1, 22} = 'isjceq';
    probinfo{1, 23} = 'ishcub';
    probinfo{1, 24} = 'ishceq';

    % Start parallel pool for timeout handling
    pool = gcp();

    % Record the log
    diary(fullfile(saving_path, 'log_matlab.txt'));

    % Process each problem
    for i_problem = 2:length(problem_names) + 1

        tmp = cell(1, 24);
        problem_name = problem_names{i_problem - 1};
        problem_name = strrep(problem_name, '.m', '');

        fprintf('\nLoading problem %i: %s\n', i_problem - 1, problem_name);

        try
            % Use parfeval with timeout to load the problem
            f = parfeval(pool, @get_init_info, 1, problem_name, known_feasibility);
            [idx, info_init] = fetchNext(f, timeout);
            if isempty(idx)
                cancel(f);
                timeout_problems = [timeout_problems, problem_name];
                fprintf('Timeout loading problem %i: %s\n', i_problem - 1, problem_name);
                probinfo(i_problem, :) = [];
                continue
            end
            fprintf('Problem %s loaded successfully\n\n', problem_name);
        catch
            tmp{1} = [problem_name, ' (error loading)'];
            fprintf('Error loading problem %i: %s\n', i_problem - 1, problem_name);
            probinfo(i_problem, :) = tmp;
            continue
        end

        % Record the information
        tmp(1:24) = info_init;

        if info_init{18} == 1
            feasibility = [feasibility, problem_name];
        end

        probinfo(i_problem, :) = tmp;
    end

    % Remove the empty rows
    probinfo = probinfo(~cellfun('isempty', probinfo(:, 1)), :);

    % Save feasibility problems to txt file
    fid = fopen(fullfile(saving_path, 'feasibility_matlab.txt'), 'w');
    if fid == -1
        error('Cannot open file: feasibility_matlab.txt');
    end
    fprintf(fid, '%s', strjoin(feasibility, ' '));
    fclose(fid);

    % Save timeout problems to txt file
    fid = fopen(fullfile(saving_path, 'timeout_problems_matlab.txt'), 'w');
    if fid == -1
        error('Cannot open file: timeout_problems_matlab.txt');
    end
    fprintf(fid, '%s', strjoin(timeout_problems, ' '));
    fclose(fid);

    % Save the data to a .mat file
    save(fullfile(saving_path, 'probinfo_matlab.mat'), 'probinfo');

    % Save the data to a .csv file
    T = cell2table(probinfo(2:end, :), 'VariableNames', probinfo(1, :));
    writetable(T, fullfile(saving_path, 'probinfo_matlab.csv'));

    fprintf('Task completed\n');
    diary off;
end


function info_init = get_init_info(problem_name, known_feasibility)
%GET_INIT_INFO Extract information about a single problem.
%
%   Returns a cell array containing problem metrics such as dimensions,
%   constraint counts, and function availability flags.

    info_init = cell(1, 24);
    info_init{1} = problem_name;

    % Load the problem using s2mpj_load from repository root
    p = s2mpj_load(problem_name);

    % Problem type
    try
        info_init{2} = p.ptype;
    catch
        info_init{2} = 'unknown';
    end

    % Variable type (all S2MPJ problems are real-valued)
    try
        info_init{3} = p.xtype;
    catch
        info_init{3} = 'r';
    end

    % Dimension
    try
        info_init{4} = p.n;
    catch
        info_init{4} = 'unknown';
    end

    % Bound constraints
    try
        info_init{5} = p.mb;
    catch
        info_init{5} = 'unknown';
    end

    try
        info_init{6} = sum(~isinf(-p.xl));
    catch
        info_init{6} = 'unknown';
    end

    try
        info_init{7} = sum(~isinf(p.xu));
    catch
        info_init{7} = 'unknown';
    end

    % Constraint counts
    try
        info_init{8} = p.mcon;
    catch
        info_init{8} = 'unknown';
    end

    try
        info_init{9} = p.mlcon;
    catch
        info_init{9} = 'unknown';
    end

    try
        info_init{10} = p.mnlcon;
    catch
        info_init{10} = 'unknown';
    end

    try
        info_init{11} = p.m_linear_ub + p.m_nonlinear_ub;
    catch
        info_init{11} = 'unknown';
    end

    try
        info_init{12} = p.m_linear_eq + p.m_nonlinear_eq;
    catch
        info_init{12} = 'unknown';
    end

    try
        info_init{13} = p.m_linear_ub;
    catch
        info_init{13} = 'unknown';
    end

    try
        info_init{14} = p.m_linear_eq;
    catch
        info_init{14} = 'unknown';
    end

    try
        info_init{15} = p.m_nonlinear_ub;
    catch
        info_init{15} = 'unknown';
    end

    try
        info_init{16} = p.m_nonlinear_eq;
    catch
        info_init{16} = 'unknown';
    end

    % Objective function value and feasibility check
    try
        info_init{17} = p.fun(p.x0);
        if strcmp(problem_name, 'LIN')
            info_init{18} = 0;
        elseif isempty(info_init{17}) || isnan(info_init{17}) || ismember(problem_name, known_feasibility)
            info_init{18} = 1;
        else
            info_init{18} = 0;
        end
        if strcmp(problem_name, 'LIN')
            info_init{17} = NaN;
        elseif isempty(info_init{17}) || isnan(info_init{17}) || (ismember(problem_name, known_feasibility) && ~strcmp(problem_name, 'HS8'))
            info_init{17} = 0;
        end
    catch
        info_init{17} = 0;
        info_init{18} = 1;
    end

    % Check gradient availability
    try
        g = p.grad(p.x0);
        info_init{19} = ~isempty(g);
    catch
        info_init{19} = 0;
    end

    % Check Hessian availability
    try
        h = p.hess(p.x0);
        info_init{20} = ~isempty(h);
    catch
        info_init{20} = 0;
    end

    % Check constraint Jacobians
    try
        J = p.jcub(p.x0);
        info_init{21} = ~isempty(J);
    catch
        info_init{21} = 0;
    end

    try
        J = p.jceq(p.x0);
        info_init{22} = ~isempty(J);
    catch
        info_init{22} = 0;
    end

    % Check constraint Hessians
    try
        H = p.hcub(p.x0);
        info_init{23} = ~isempty(H);
    catch
        info_init{23} = 0;
    end

    try
        H = p.hceq(p.x0);
        info_init{24} = ~isempty(H);
    catch
        info_init{24} = 0;
    end
end
