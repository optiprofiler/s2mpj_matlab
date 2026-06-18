# S2MPJ MATLAB Subset

This repository provides a specialized MATLAB-only subset of the [S2MPJ](https://github.com/GrattonToint/S2MPJ) collection.

## Contents

This repository preserves only the files relevant to MATLAB users from the original source. These files are located in the `src/` directory:

- **`src/matlab_problems/`**: Directory containing the optimization problems converted to MATLAB.
- **`src/list_of_matlab_problems`**: A listing of all available problems.
- **`src/s2mpjlib.m`**: Supporting library script.

## Configuration

The file `config.txt` in this directory controls how `s2mpj_select` filters problems (e.g., `variable_size` and `test_feasibility_problems`). See the comments in `config.txt` for a full description of each option.

When used through **OptiProfiler**, these options can also be overridden by OptiProfiler's problem-library configuration layer. Environment-level overrides should be preferred in automated workflows, so the checked-in `config.txt` remains stable.

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
