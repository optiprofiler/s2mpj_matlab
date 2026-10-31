# OptiProfiler 2.0 compatibility

This line is the reviewed S2MPJ MATLAB adapter for OptiProfiler 2.0.0. Provider
API version remains **1**. Upstream problem definitions and the automatic
upstream-promotion policy are unchanged. Selection changes in three deliberate
ways: NOZZLEfp is corrected to its native `rrrrb` domain and no longer offered,
`variable_size='all'` now includes the default instance, and the native models
HS67 and ROSSIMP1NE, whose constraint bounds are invalid, are no longer offered.

The adapter supplies selection and public Problem callbacks. Ordered feature
composition, counters and histories, scores, save/load, and eval_report/2 are
owned by core, not duplicated in adapters. No core-private class is accessed.
The loader returns the public MATLAB Problem class, not a subclass.

The adapter owns native setup state through an internal serializable
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

Only continuous models are exposed: an integer or binary declaration is
rejected before any evaluation and selection excludes it, in every configuration
mode and oracle level. Native metadata fails closed: an undefined or impossible
bound never drops a constraint, and an unreadable linear constraint fails the
load.

No trusted reference has been promoted for these wrapped instances, so
Problem.reference remains empty ([]) and profiles keep the empirical default
target. Initial values, history minima, upstream solution vectors and metadata
fbest are not converted into references. A future fact needs raw `fun` and
`maxcv`, one of the two kinds `feasible` or `merit`, and a verifiable source
under the core reference contract.

MATLAB uses the public registry and supported setup contract, not Python
entry points. Optional roots are external to core; S2MPJ stays bundled.
Unregister removes registration/path ownership, not source/runtime/cache.
Core uninstall does not delete provider data. Validate with isolated registry,
startup and pathdef targets, including new sessions and parallel workers.
