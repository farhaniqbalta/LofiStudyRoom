# Engine-first (M2 + M3a)

**Status:** Planned
**Scope:** [`docs/plans/2026-11-14-engine-first.md`](../plans/2026-11-14-engine-first.md)
**Date:** 2026-11-14

## Decisions

- Build the engine before final art. The art is replaceable: packs are folders, and a new camera angle is a new scene pack plus matching character and pet packs.
- States with no real art get script-made stand-ins, marked `"provenance": "stand-in …"`.
- Spotify (M3b) is deferred until after an App Remote spike.
- Weather location is chosen by city search only; no location permission.
- Repo tidied and published as a public repo: specs moved to `docs/spec/`, private IDs moved to the git-ignored `CLAUDE.local.md`, concept images kept local, history squashed to one commit.

## Done

- Task 0: repo tidied and published.
- Task 0B: plan and directions written.

## Build / test results

- After the tidy-up: `Executed 14 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad.

## Open issues

## Next step

Task 1 (config schema v2 and environment rules), after the user approves the updated directions.
