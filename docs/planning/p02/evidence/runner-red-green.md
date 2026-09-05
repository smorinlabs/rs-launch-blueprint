# P02 durable-runner RED/GREEN evidence

> Historical first-pass record. The later [adversarial review](runner-adversarial-review.md)
> replaces its acceptance claims with actual-validator and full-tree tests.
> Early stub-based publication tests did not establish first acceptance.

RED cases are independent fake-provider failures: an accepted operation is
followed by timeout, a submission ID is lost, one provider fails after another
has retained a raw artifact, a run ID collides, a caller traverses out of the
run directory, an active run or publication writer lock exists, and publication
stops after its first write. Each must refuse or preserve state rather than
infer a fresh request.

GREEN is `uv run python scripts/test-research-runner.py`. It creates a temporary
repository, drives the public CLI across a process restart, and asserts those
observable failures plus journal roll-forward. It does not contact a provider
or assert that a state label emitted by the same implementation is sufficient.
