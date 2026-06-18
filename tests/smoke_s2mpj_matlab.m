repo_dir = fileparts(fileparts(mfilename('fullpath')));
restoredefaultpath;
addpath(repo_dir);
addpath(fullfile(repo_dir, 'src'));
addpath(fullfile(repo_dir, 'src', 'matlab_problems'));

local_op_src = fullfile(fileparts(fileparts(repo_dir)), ...
    'optiprofiler', 'matlab', 'optiprofiler', 'src');
ci_op_src = fullfile(repo_dir, 'optiprofiler', ...
    'matlab', 'optiprofiler', 'src');
if exist(ci_op_src, 'dir') == 7
    addpath(ci_op_src);
elseif exist(local_op_src, 'dir') == 7
    addpath(local_op_src);
else
    error('S2MPJ:SmokeTest', 'Could not find OptiProfiler MATLAB source path.');
end

config_path = fullfile(repo_dir, 'config.txt');
original_config = fileread(config_path);
cleanup_config = onCleanup(@() write_text(config_path, original_config));

representative = {'ALLINITU', 'ALLINIT', 'ALSOTAME', 'ALLINITA'};
selected = s2mpj_select(struct('ptype', 'ubln', 'maxdim', 5, ...
    'maxb', 20, 'maxlcon', 20, 'maxnlcon', 20, 'maxcon', 20));
for i = 1:numel(representative)
    assert(ismember(representative{i}, selected));
end

for i = 1:numel(representative)
    assert_problem_contract(representative{i});
end

seed_text = getenv('OP_RANDOM_SEED');
if isempty(seed_text)
    seed_text = datestr(datetime('today'), 'yyyymmdd');
end
seed = str2double(seed_text);
if isnan(seed)
    seed = 1;
end
rng(seed);
sample_size = min(4, numel(selected));
sample_indices = randperm(numel(selected), sample_size);
sample = selected(sample_indices);
fprintf('S2MPJ MATLAB random sample seed=%d:', seed);
for i = 1:numel(sample)
    fprintf(' %s', sample{i});
end
fprintf('\n');
for i = 1:numel(sample)
    assert_problem_contract(sample{i});
end

assert_config_behavior(config_path);

disp('s2mpj_matlab adapter smoke ok');

function assert_config_behavior(config_path)
    options = struct('ptype', 'ubln', 'maxdim', 5, ...
        'maxb', 20, 'maxlcon', 20, 'maxnlcon', 20, 'maxcon', 20);

    write_s2mpj_config(config_path, 'default', '0');
    default_names = s2mpj_select(options);
    write_s2mpj_config(config_path, 'all', '0');
    all_names = s2mpj_select(options);
    assert(numel(all_names) > numel(default_names));
    assert(ismember('CHEBYQAD_2', all_names));
    assert(~ismember('CHEBYQAD_2', default_names));

    write_s2mpj_config(config_path, 'default', '1');
    feasibility_names = s2mpj_select(options);
    write_s2mpj_config(config_path, 'default', '2');
    all_feasibility_modes = s2mpj_select(options);
    assert(ismember('ARGAUSS', feasibility_names));
    assert(~ismember('ALLINITU', feasibility_names));
    assert(ismember('ARGAUSS', all_feasibility_modes));
    assert(ismember('ALLINITU', all_feasibility_modes));

    write_s2mpj_config(config_path, 'not-a-mode', '0');
    assert_raises(@() s2mpj_select(options));
    write_s2mpj_config(config_path, 'default', '3');
    assert_raises(@() s2mpj_select(options));
end

function assert_problem_contract(problem_name)
    p = s2mpj_load(problem_name);
    assert(p.n >= 1);
    assert(numel(p.x0) == p.n);
    fx0 = p.fun(p.x0);
    assert(isfinite(fx0) || isnan(fx0));
    cub0 = p.cub(p.x0);
    ceq0 = p.ceq(p.x0);
    assert(isvector(cub0));
    assert(isvector(ceq0));
    fx1 = p.fun(p.x0);
    assert(isfinite(fx1) || isnan(fx1));
end

function write_s2mpj_config(config_path, variable_size, test_feasibility_problems)
    write_text(config_path, sprintf('variable_size=%s\ntest_feasibility_problems=%s\n', ...
        variable_size, test_feasibility_problems));
end

function write_text(path, text)
    fid = fopen(path, 'w');
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', text);
end

function assert_raises(callback)
    did_raise = false;
    try
        callback();
    catch
        did_raise = true;
    end
    assert(did_raise);
end
