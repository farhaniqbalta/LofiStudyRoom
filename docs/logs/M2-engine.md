# Engine-first (M2 + M3a)

**Status:** In progress (Task 1 done)
**Scope:** [`docs/plans/2026-11-14-engine-first.md`](../plans/2026-11-14-engine-first.md)
**Date:** 2026-11-14

## Decisions

- Build the engine before final art. The art is replaceable: packs are folders, and a new camera angle is a new scene pack plus matching character and pet packs.
- States with no real art get script-made stand-ins, marked `"provenance": "stand-in …"`.
- Spotify (M3b) is deferred until after an App Remote spike.
- Weather location is chosen by city search only; no location permission.
- The art will change completely (side-profile half-body characters, detailed desk, cyberpunk city). The engine must be reusable with it, so the plan adds Task 1B (manifest-driven animations and routines, perspective-filtered pack lists, `-scene` choice) and a fixture-scene test that every later task extends.
- Repo tidied and published as a public repo: specs moved to `docs/spec/`, private IDs moved to the git-ignored `CLAUDE.local.md`, concept images kept local, history squashed to one commit.

## Done

- Task 0: repo tidied and published.
- Task 0B: plan and directions written.
- Task 1: `RoomConfig` v2 (lamp, time, weather, city, keep awake; old saves keep their pack choices) and `Domain/Environment.swift` (weather-code mapping, sunrise/sunset day phase with 06:00–18:00 fallback, manual-over-automatic, 2-hour staleness).

## Build / test results

- After the tidy-up: `Executed 14 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad.
- After Task 1: `Executed 20 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad.

## Open issues

- Tests hang if the iPad locks; set Auto-Lock to Never while testing.

## Next step

Task 1B (make the engine art-independent).
