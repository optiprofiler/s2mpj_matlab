# S2MPJ MATLAB Subset

This repository provides a specialized MATLAB-only subset of the [S2MPJ](https://github.com/GrattonToint/S2MPJ) collection.

## Paper backport and attribution

This candidate retains the paper provider snapshot
`8938143d17cd9413676f563eba8d89770f8d2ecc`, including its problem sources,
selection metadata, configuration and public interface. The adapter correction
negates lower-bound constraint Hessians, consistently with its values and
Jacobians. Regression tests cover both bounds and constraint/multiplier order.

The upstream S2MPJ sources are distributed under BSD-3-Clause. The unmodified
official [LICENCE.txt](LICENCE.txt) and [source and citation notice](THIRD_PARTY_NOTICES.md)
record the authors, paper, exact license revision and retained source differences.
The license revision does not indicate a numerical source update or assign
copyright or a license to independently authored OptiProfiler additions.

## Contents

This repository preserves only the files relevant to MATLAB users from the original source. These files are located in the `src/` directory:

- **`src/matlab_problems/`**: Directory containing the optimization problems converted to MATLAB.
- **`src/list_of_matlab_problems`**: A listing of all available problems.
- **`src/s2mpjlib.m`**: Supporting library script.

## Configuration

Selection limits use finite integer lower bounds (`mindim >= 1`, other
`min* >= 0`). Each of `maxdim`, `maxb`, `maxlcon`, `maxnlcon` and `maxcon`
accepts an integer at least the corresponding lower bound or positive `Inf`
for no upper cutoff. NaN and negative infinity are not valid limits.
`benchmark` validates these inputs; direct `s2mpj_select` callers should
provide criteria satisfying the same contract.

The file `config.txt` in this directory controls how `s2mpj_select` filters problems (e.g., `variable_size` and `test_feasibility_problems`). See the comments in `config.txt` for a full description of each option.

This MATLAB adapter reads `config.txt` directly. It does not implement the
Python environment-variable or process-level configuration override layer.

## Testing

The `CI` workflow runs daily and on pushes. It checks the OptiProfiler adapter layer by:

- selecting a small set of representative `u`, `b`, `l`, and `n` problems;
- loading each selected problem through `s2mpj_load`;
- evaluating `fun`, `cub`, and `ceq` at the initial point;
- checking `variable_size` and `test_feasibility_problems` in `config.txt`;
- sampling a few additional small problems each day with at most two numerical-library threads.

Locally, from this repository:

```bash
matlab -batch "run('tests/smoke_s2mpj_matlab.m')"
```

## Maintenance

This repository is **automatically synchronized** with the upstream `GrattonToint/S2MPJ` repository via GitHub Actions. It checks for updates daily to ensure the problem set remains current.

The `Collect Info` workflow regenerates `probinfo_matlab.csv` and `probinfo_matlab.mat` for `s2mpj_select`. It runs after upstream synchronization and can also be triggered manually.

## Provenance and Citation

The files under `src/` are a filtered MATLAB subset of the upstream [S2MPJ](https://github.com/GrattonToint/S2MPJ) repository. This repository adds only the OptiProfiler adapter, metadata, and maintenance workflows. Please follow the upstream S2MPJ citation and license guidance when using the problem collection.

For the full collection or other languages, please visit the [original repository](https://github.com/GrattonToint/S2MPJ).
