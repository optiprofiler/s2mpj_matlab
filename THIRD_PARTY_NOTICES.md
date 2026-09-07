# S2MPJ sources and redistribution notice

## Upstream S2MPJ

The files in `src/` originate from [S2MPJ](https://github.com/GrattonToint/S2MPJ)
by Serge Gratton and Philippe L. Toint. The problem files retain their
individual mathematical-source references, SIF-input credits and translation
notices. These references must be preserved; this mirror does not claim
authorship of the original problem collection.

S2MPJ is licensed under **BSD-3-Clause**. The complete upstream
[`LICENCE.txt`](LICENCE.txt) is reproduced byte for byte, including:

> Copyright (c) 2026, S. Gratton and Ph. L. Toint

Redistributors must retain that copyright notice, the three conditions and
the disclaimer. The authors' names may not be used to imply endorsement.
The license text, rather than this explanatory notice, governs upstream use.

- Upstream license revision: `fea6a70048eaad28b13a08703ddbfdbf65cd9c30`.
- [Exact license source](https://github.com/GrattonToint/S2MPJ/blob/fea6a70048eaad28b13a08703ddbfdbf65cd9c30/LICENCE.txt).
- SHA-256: `a8636fc42ac474fc85fbf451c6a0316f6cbd9efa9031d549797dec6b43e9e5b4`.

## Reviewed source snapshot

The license was adopted separately from numerical source updates. On
2026-09-05 the tracked source subset was compared with upstream at the
license revision above:

- Provider baseline: `8938143d17cd9413676f563eba8d89770f8d2ecc`.
- Unchanged Git tree for `src/`: `dcfe70eeef9246d3549bc13d67471914555c41d2`.
- 1,132 tracked source files match upstream byte for byte.
- The extra `src/matlab_problems/listm` is a retained historical upstream
  listing. Upstream removed it in the license commit; it is not a problem
  definition and was not removed as part of this license adoption.

The license revision is **not** a claim that every file was synchronized to
that revision. This paper backport freezes the original adapter interface, metadata and
retained source together. It only corrects lower-bound constraint Hessian
signs and adds regression tests and redistribution information. It does not
adopt later provider interfaces or regenerate the problem-selection data.

## OptiProfiler additions

`s2mpj_load.m`, `s2mpj_select.m`, configuration, generated
`probinfo_matlab.csv` / `probinfo_matlab.mat`, tests and maintenance workflows
provide the OptiProfiler integration. Generated metadata is derived from the
wrapped upstream problems; it is not a separately authored problem collection.

The upstream `LICENCE.txt` applies to the S2MPJ material identified above.
OptiProfiler integration code retains its existing OptiProfiler authorization
and attribution. This notice does not transfer authorship of those independent
additions to Gratton and Toint, change existing licenses, or reassign third-party
copyrights.

## Citation and distribution

Please cite S. Gratton and Ph. L. Toint, *S2MPJ and CUTEst optimization
problems for Matlab, Python and Julia*, Optimization Methods and Software
40(4), 871-903 (2025), [doi:10.1080/10556788.2025.2490640](https://doi.org/10.1080/10556788.2025.2490640).
The [authors' preprint](https://arxiv.org/abs/2407.07812) and
[upstream documentation](https://github.com/GrattonToint/S2MPJ/blob/fea6a70048eaad28b13a08703ddbfdbf65cd9c30/s2mpj.pdf)
describe the collection.

Carry `LICENCE.txt` and this notice alongside the bundled source in every
MATLAB ZIP and source archive.
Verify both files in any consuming MATLAB/source archive. The core maintainer
owns the combined package notice and adoption of this provider commit.
