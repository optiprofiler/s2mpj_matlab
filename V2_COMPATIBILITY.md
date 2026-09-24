# OptiProfiler 2.0 compatibility candidate

This branch is an unpushed compatibility candidate, not a release. Provider
API version remains **1**. No adapter version, upstream problem definitions,
selection metadata, or automatic upstream-promotion policy is changed.

The adapter supplies selection and public Problem callbacks. Ordered feature
composition, counters and histories, scores, save/load, and eval_report/2 are
owned by core, not duplicated in adapters. No core-private class is accessed.
The loader returns the public MATLAB Problem class, not a subclass.

The candidate now owns native setup state through an internal serializable
oracle. Instance switches and fresh-session/worker restoration replay original
setup arguments after validating native and helper source identities inside
the current installation. Cache invalidation precedes setup, and successful
metadata validation precedes committing the active identity. This does not
change problem definitions or expose a new loader option.

The bounded contract requires an explicit reload after raw native setup or
selective clearing, and assumes installed source files are not edited while
objects are alive. Legacy raw Problem MAT archives lacking original arguments
require explicit reconstruction; retained local callback names are not a
claim of automatic legacy-state recovery. Java is not required. See the
README for the full state and source-ownership contract.

No trusted feasible reference has been promoted for these wrapped instances.
Problem.reference remains empty ([]). Initial values, history minima, upstream
solution vectors and metadata fbest are not converted into references. A
future fact requires a kind, feasible applicability, source and supported
mapping under the current core reference contract.

MATLAB uses the public registry and supported setup contract, not Python
entry points. Optional roots are external to core; S2MPJ stays bundled.
Unregister removes registration/path ownership, not source/runtime/cache.
Core uninstall does not delete provider data. Validate with isolated registry,
startup and pathdef targets, including new sessions and parallel workers.
The initial release may use a reviewed repository tag/source ZIP, not PyPI.
