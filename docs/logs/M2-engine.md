# Engine-first (M2 + M3a)

**Status:** In progress (Tasks 1, 1B, 2 and 3 done)
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
- Task 1B: engine made art-independent. Resting animation is each pack's `fallbackAnimation`; manifests can mark animations as `routine` or `onTap`; the scene is the first scene folder or `-scene <folder>`; pack lists are filtered by the scene's `perspective`. A synthetic fixture scene (320×240, other animation names) runs the engine in tests.
- Task 2: one-shot animations and safe exits. `ActorTimeline` (pure timing), `TimerScheduling` / `LiveTimers` (injectable timers, reused by later tasks), `PackSpriteNode.play(_:then:)` and `requestExit(then:)`. A one-shot stays on its last frame until the caller shows something else. Note: `requestExit` and `show` cancel a pending `play` completion, so whoever interrupts must restart the routine chain (handled in Task 3).
- Task 3: routine and pet scheduling. `RoutineScheduler` (weighted pick, cooldowns, delay range), `ActorDirector` (one per actor: routine chain, swap and tap wait for a safe exit only while a one-shot plays, at most one timer, none when inactive or when the pack has no routines), `SceneCoordinator.setActive` / `petTapped`, launch argument `-routineSpeed`. Pacing lives in code: characters 90–240 s, pets 60–180 s; weights and cooldowns come from manifests. A pack swap resets cooldowns.
- Working method from Task 1B on: the lead writes each task's brief and acceptance tests, a Sonnet subagent implements, the lead reviews, runs the tests and commits.

## Build / test results

- After the tidy-up: `Executed 14 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad.
- After Task 1: `Executed 20 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad.
- After Task 1B: `Executed 25 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad. Source search for art names outside `RoomStateStore.swift`: none.
- After Task 2: `Executed 35 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (run by the subagent and again by the lead).
- After Task 3: `Executed 46 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (subagent and lead).

## Open issues

- Tests hang if the iPad locks; set Auto-Lock to Never while testing.
- `testFixtureRoutinesUseOnlyDeclaredNames` uses the system random generator, so it could fail by chance (about 1 in 100,000 runs).
- The bundled art has no routines or tap reaction yet, so nothing visible changes until Task 4 adds stand-ins.

## Next step

Task 4 (stand-in art and scene visuals).
