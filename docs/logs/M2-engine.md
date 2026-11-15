# Engine-first (M2 + M3a)

**Status:** In progress (Tasks 1–6 done)
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
- Task 4: stand-in art and scene visuals.
  - Art (`Tools/build_art.py`, no PixelLab generations): character `drink`, `stretch`, `rest`; cat `idle` and `react`; 6-frame rain; day frames for both cities; four room images (`night-on`, `night-off`, `day-on`, `day-off`); hotspots for pet, lamp, window, computer. All marked as stand-ins in `provenance` / `standIns`.
  - Engine: scene manifest gains optional `rooms`, `rain`, `hotspots`; scenery packs gain optional `phases`. `LoFiSKScene.apply(_:reduceMotion:)` swaps the room texture, shows or hides rain (half speed under Reduce Motion) and picks the scenery picture for the phase, without adding nodes. The coordinator applies the environment at start and on every clock tick. Debug launch arguments `-time`, `-weather`, `-lamp`.
  - Change from the plan: day/night and lamp are four baked room images, not overlay sprites (no extra nodes, and new art can supply its own four).
- Task 5: hotspots and taps. `HotspotOverlay` puts invisible SwiftUI buttons (at least 44×44 pt, VoiceOver labels Pet / Desk lamp / Window / Computer) over the manifest's hotspot rectangles; smaller frames sit on top. Pet tap plays the manifest's tap reaction, lamp toggles and saves, window cycles scenery, computer toggles a "Music coming soon" card. `SceneCoordinator` is now an `ObservableObject` created by `SceneCoordinator.live()`; `RoomView` is the root view. `-debugAnchors YES` outlines the tap areas.
- Task 6: weather. `OpenMeteoProvider` (forecast and city search; requests carry only coordinates or the typed name), `EnvironmentController` (disk cache per city, one 30-minute refresh timer, stale after 2 hours, results after stop or a city change are discarded, never throws). The coordinator fetches only when a city is set and time or weather is automatic; otherwise the network is unused. `weatherStatus` is published for the panel. Debug: `-cityName/-cityLat/-cityLon` and a status line under `-debugAnchors`.
- Working method from Task 1B on: the lead writes each task's brief and acceptance tests, a Sonnet subagent implements, the lead reviews, runs the tests and commits.

## Build / test results

- After the tidy-up: `Executed 14 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad.
- After Task 1: `Executed 20 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad.
- After Task 1B: `Executed 25 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad. Source search for art names outside `RoomStateStore.swift`: none.
- After Task 2: `Executed 35 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (run by the subagent and again by the lead).
- After Task 3: `Executed 46 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (subagent and lead).
- After Task 4: `Executed 56 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (subagent and lead). Device screenshots checked for night/rain/lamp-off, day/clear/lamp-on and night/clear/lamp-on: rain shows only inside the window.
- After Task 5: `Executed 64 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (subagent and lead). Debug screenshot: the four tap areas sit on the cat, lamp, window and monitor; nothing is visible without the debug flag.
- After Task 6: `Executed 75 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (subagent twice, lead once). Real-network check on the iPad with Tokyo coordinates showed `weather: current · day · rain · lamp on`.

## Open issues

- Tests hang if the iPad locks; set Auto-Lock to Never while testing.
- `testFixtureRoutinesUseOnlyDeclaredNames` uses the system random generator, so it could fail by chance (about 1 in 100,000 runs).
- Stand-in quality (all to be replaced in the art pass): the day room is a pale wash and the character looks too dark against it, with ragged edge pixels; lamp-off still shows a faint cone; the drink mug is 4×5 px and easy to miss; the cat's idle twitch is 1 px; rain is faint.
- Characters and pets have no day variant.
- Real finger taps on the iPad have not been tried yet (taps cannot be sent from the Mac); the user needs to try the four hotspots.
- The VoiceOver label for the pet is "Pet", not "Cat" as the plan said, to stay art-independent.
- The `-cityLat`/`-cityLon` launch arguments cannot take negative numbers (the system reads `-6.2` as another argument name), so southern or western cities cannot be set that way; the settings panel (Task 7) is the real way to choose a city.
- A Reduce Motion change is only picked up on the next clock tick (up to a minute).
- Automatic time shows the stand-in day room during daylight until the settings panel exists; use `-time night` to force night.

## Next step

Task 7 (customization panel).
