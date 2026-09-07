# S2MPJ MATLAB Subset

This repository provides a specialized MATLAB-only subset of the [S2MPJ](https://github.com/GrattonToint/S2MPJ) collection.

## Contents

This repository preserves only the files relevant to MATLAB users from the original source. These files are located in the `src/` directory:

- **`src/matlab_problems/`**: Directory containing the optimization problems converted to MATLAB.
- **`src/list_of_matlab_problems`**: A listing of all available problems.
- **`src/s2mpjlib.m`**: Supporting library script.

## OptiProfiler Lifecycle

S2MPJ is the bundled default MATLAB problem library in OptiProfiler. Ordinary
users obtain it through the OptiProfiler MATLAB source or, in the next release,
the planned MATLAB-only ZIP. They do not need to clone this repository or add
it to the MATLAB path separately.

Use the public name directly:

```matlab
options.plibs = {'s2mpj'};
scores = benchmark(solvers, options);
```

The bundled provider cannot be registered or removed with
`registerProblemLibrary` or `unregisterProblemLibrary`. `setup uninstall`
removes its OptiProfiler-managed MATLAB path together with the core, but does
not remove benchmark output or other user data.

This repository keeps a reviewed S2MPJ snapshot for OptiProfiler maintenance.
An automated workflow checks upstream and reports differences, but it never
changes `src/`, metadata, or the OptiProfiler lock. A later core revision selects
a new bundled snapshot only after maintainers review and commit the candidate.

## Configuration

Selection limits use finite integer lower bounds (`mindim >= 1`, other
`min* >= 0`). Each of `maxdim`, `maxb`, `maxlcon`, `maxnlcon` and `maxcon`
accepts an integer at least the corresponding lower bound or positive `Inf`
for no upper cutoff. NaN and negative infinity are not valid limits.
`benchmark` validates these inputs; direct `s2mpj_select` callers should
provide criteria satisfying the same contract.

The file `config.txt` in this directory controls how `s2mpj_select` filters
problems (e.g., `variable_size` and `test_feasibility_problems`). See the
comments in `config.txt` for a full description of each option. The current
MATLAB adapter reads this file directly; it does not provide a separate
environment-variable or process-level override layer.

## Testing

The `CI` workflow runs daily and on pushes. It checks the OptiProfiler adapter layer by:

- selecting a small set of representative `u`, `b`, `l`, and `n` problems;
- loading each selected problem through `s2mpj_load`;
- evaluating `fun`, `cub`, and `ceq` at the initial point;
- checking `variable_size` and `test_feasibility_problems` in `config.txt`;
- checking nonlinear lower/upper/two-sided constraint Hessians against Jacobian
  differences, including stacking and multiplier order;
- sampling a few additional small problems each day with at most two numerical-library threads.

Locally, from this repository:

```bash
matlab -batch "run('tests/smoke_s2mpj_matlab.m'); addpath('tests'); test_constraint_hessians"
```

## Maintenance

`Check S2MPJ Upstream` compares the managed MATLAB subset with the latest
`GrattonToint/S2MPJ` revision every day. A difference creates or updates an
`upstream-update` issue and uploads a report. The workflow has no permission to
push source changes.

The manual `Collect Info` workflow regenerates `probinfo_matlab.csv` and
`probinfo_matlab.mat` for review and uploads them as artifacts. It does not
commit either file automatically.

## Provenance and Citation

The files under `src/` originate from [S2MPJ](https://github.com/GrattonToint/S2MPJ)
by Serge Gratton and Philippe L. Toint. Their **BSD-3-Clause** license is
preserved verbatim in [LICENCE.txt](LICENCE.txt). The
[third-party notice](THIRD_PARTY_NOTICES.md) records the exact license revision,
source comparison and attribution, and distinguishes the independently added
OptiProfiler adapter and metadata. The upstream copyright notice does not
assign ownership of those independent additions.

Please cite S. Gratton and Ph. L. Toint, *S2MPJ and CUTEst optimization
problems for Matlab, Python and Julia*, Optimization Methods and Software
40(4), 871-903 (2025), [doi:10.1080/10556788.2025.2490640](https://doi.org/10.1080/10556788.2025.2490640).

Distributions must carry `LICENCE.txt` and `THIRD_PARTY_NOTICES.md` together
with the source. CI checks their exact contents in source archives. To check a built archive:

```bash
python3 tests/check_distribution.py /path/to/archive.zip
```

For the full collection or other languages, please visit the [original repository](https://github.com/GrattonToint/S2MPJ).
