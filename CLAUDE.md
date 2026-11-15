# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Lo-Fi Pixel Room

## Project purpose

Build a native, low-power iPadOS pixel-art ambient room application.

The application is a foreground app that behaves like an animated screensaver.

It is not a traditional game.

## Source of truth

Read these documents before making architectural decisions:

1. `docs/spec/LOCKED_MVP_SPEC.md` — authoritative requirements.
2. `docs/spec/DESIGN_EXPLORATION_BRIEF.md` — visual direction.
3. `docs/spec/MVP_REVIEW_REPORT.md` — advisory technical findings. Blockers B1–B3, decisions D1–D8 and open questions Q1–Q6 each have a proposed default; use the default unless the user decides otherwise, and say so in the worklog.
4. `docs/logs/worklog.md` — checkpoint progress index (see Worklogs).

When documents conflict, the original locked MVP specification takes precedence.

Do not silently modify its scope.

## Visual reference

The two concept images are local only (`docs/reference/` is git-ignored), so they may be absent in a fresh clone.

- `docs/reference/mvp-board.png` — MVP board: hero room (boy, desk, lamp, monitor, orange cat on desk, in-world digital clock left of the monitor, rainy cyber-city window), girl variant, character/pet/scenery/clock variants, routine strip (study → drink → stretch → rest).
- `docs/reference/rainy-night-nook.png` — base mood: rainy neon night.

Use them for composition, palette (warm amber lamp vs cyan/violet city) and anchor placement only. They are concept art, not sprite sheets. Where the board differs from the spec, the spec wins:
- The snowy panel is out of scope (MVP weather is Clear/Rain only).
- The always-visible Spotify and weather HUD panels are mock-ups; in the app they are hidden by default/compact (spec §1.1, §1.3).
- The "15–30 FPS" label is a hypothesis, not a target (see review D1).

## Sprite generation

Generate sprites with the **PixelLab MCP** (`pixellab` server). Keep every generated asset on one logical pixel grid, one camera angle and shared anchors; record the prompt/settings and licence for each pack in its manifest or the checkpoint worklog. Generated output still needs a consistency pass before it counts as production art.

## Commands

Testing is done on a physical iPad, not a simulator. The device ID and Apple team ID are private: they live in the git-ignored `CLAUDE.local.md`, never in tracked files. If `xcode-select` points at the Command Line Tools, prefix Xcode commands with `DEVELOPER_DIR`.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
IPAD=<device UDID>                    # xcrun devicectl list devices
export DEVELOPMENT_TEAM=<Apple team ID> # read by project.yml when xcodegen runs

xcodegen generate                      # regenerate LoFiRoom.xcodeproj after editing project.yml or adding source files
python3 Tools/build_art.py             # rebuild LoFiRoom/Assets packs from the raw PixelLab images in ArtSource/
python3 Tools/preview.py Boy01 OrangeCat NeonCity01 build/art/preview.png 22:47   # layered composite without a device

# build + run all tests on the iPad (must be unlocked)
xcodebuild test -project LoFiRoom.xcodeproj -scheme LoFiRoom -destination "platform=iOS,id=$IPAD" -allowProvisioningUpdates -derivedDataPath build
# single test
xcodebuild test ... -only-testing:LoFiRoomTests/LoFiRoomTests/testIntegerScale

# install, launch with switches, screenshot
xcrun devicectl device install app --device $IPAD build/Build/Products/Debug-iphoneos/LoFiRoom.app
xcrun devicectl device process launch --terminate-existing --device $IPAD com.lofiroom.app -- -character Girl01 -debugAnchors YES
xcrun devicectl device capture screenshot --device $IPAD --destination build/shots/shot.png
```

Launch switches: `-fps N`, `-paused YES`, `-debugAnchors YES` (anchor overlay + FPS counter), `-scene <folder>`, `-character <folder>`, `-pet <folder>`, `-scenery <folder>`, `-time auto|day|night`, `-weather auto|clear|rain`, `-lamp on|off` (choices are saved), `-routineSpeed N` (shortens routine delays for watching). The tests hang if the iPad is locked: check `xcrun devicectl device info lockState` first.

## Code layout (as of the engine-first phase)

- **Flow:** `LoFiRoomApp` → `RoomView` (SwiftUI root: `SceneContainer` for the `SKView`, `HotspotOverlay`, gear, `CustomizationSheet`) → `SceneCoordinator` (`ObservableObject`, built by `SceneCoordinator.live()`). The coordinator is the only thing that pushes state into `LoFiSKScene`; it owns the `SpriteAssetRepository`, `RoomStateStore` (one saved `RoomConfig` in `UserDefaults`), `ClockDriver`, two `ActorDirector`s and the `EnvironmentController`.
- **Packs:** `LoFiRoom/Assets/<Category>/<Folder>/{manifest.json, sheet.png}` is a folder reference, so adding a pack is adding a folder. A sheet is one row of equal frames. `SpritePack.problems()` validates a pack against the scene; a bad pack is rejected with a readable message and the scene keeps what it had. Pack lists are filtered to the active scene's `perspective`.
- **Manifests drive behaviour:** `fallbackAnimation` is the resting animation; an animation with `routine {weight, cooldown}` can be scheduled; `onTap` marks the tap reaction; `loop: false` makes a one-shot; `safeExits` lists frames where it may be interrupted (empty: only at its end); scenery `phases` maps day/night to animations.
- **Scene pack:** `Scenes/<Folder>/manifest.json` holds the canvas, safe rectangle, anchors, foreground pieces and optional `rooms` (four images keyed `<phase>-<on|off>`), `rain`, `hotspots`. Coordinates are logical pixels, origin bottom-left; every pack sprite sits with its bottom-left corner on its anchor. Anchors and hotspots must be inside the safe rectangle. The scene is the first folder in `Scenes/` or `-scene <folder>`.
- **Scaling:** `ScalePolicy` picks the largest integer scale at which the safe rectangle fits; the rest letterboxes.
- **Time-based logic:** everything uses injected one-shot timers (`TimerScheduling`) and clocks, never per-frame code. `ActorTimeline` is pure timing; `RoutineScheduler` picks routines; `ActorDirector` runs the chain for one actor and waits for a safe exit only while a one-shot plays. Tests drive time with `FakeTimers`.
- **Clock:** `ClockTime` → `ClockDriver` (one timer per minute boundary plus system notifications) → `PixelClockNode`. Each tick also re-applies the environment.
- **Environment:** `EnvironmentRules` (pure) resolves config + weather snapshot into a `ResolvedScene`; `LoFiSKScene.apply` swaps the room texture, rain and scenery picture without adding nodes. `OpenMeteoProvider` / `EnvironmentController` fetch only when a city is set and time or weather is automatic.
- **Power:** `PowerPolicy` (pure) plus wiring in `RoomView` / `SceneContainer`: inactive means paused view and no timers.
- **Art pipeline:** `ArtSource/` holds raw PixelLab output; `Tools/build_art.py` is the single source for anchors and builds every pack, including the stand-ins. Never hand-edit `LoFiRoom/Assets`.

## Layered sprite rendering (mandatory)

The room is built from independent sprite layers, never one flattened illustration. `LoFiSKScene.Layer` defines the groups and draw order, back to front:

| Group | zPosition | Holds |
|---|---|---|
| scenery | 0 | City behind the window; future rain, trains and parallax go here |
| room | 10 | Fixed room art. Its window glass is transparent, so it is the mask for everything in `scenery` |
| actors | 20 | Character, then pet |
| foreground | 30 | Room pieces in front of the actors (the chair back) so bodies are really occluded |
| objects | 40 | In-world objects (clock; lamp and computer hotspots in M2) |
| debug | 100 | Anchor overlay |

Rules:
- Character and pet sprites must not contain furniture. Anything that should hide part of a body is a `foreground` piece cut from the room.
- Interchangeable packs share one frame size and anchor per category.
- Scenery animates inside its own group without touching the room.
- Group static art; no full-screen transparent textures; a one-frame animation runs no action.

## Architecture

- SwiftUI for application UI.
- SpriteKit for 2D pixel-art rendering.
- Modular sprite-pack architecture.
- Event-driven animation scheduling.
- Scene coordinator separates rendering and application state.
- External integrations must not directly control SpriteKit.
- No backend for MVP.
- No unnecessary dependencies.

## Performance priorities

The application should be suitable for running continuously in the foreground on an iPad.

Prioritize:

1. Low CPU and GPU utilization.
2. Low energy consumption.
3. Stable memory usage.
4. Consistent pixel-art rendering.
5. Maintainability.

Avoid unnecessary per-frame calculations, continuous polling, and heavy rendering effects.

Performance claims require measurements.

## MVP constraints

- Do not introduce gameplay, currencies, levels, or progression.
- Do not introduce AI-driven characters.
- Do not introduce complex physics.
- Do not introduce additional room layouts.
- Do not implement features from later milestones prematurely.
- PixelLab art is first-pass; it still needs a consistency pass before it counts as production art.

## Working rules

1. Inspect existing code before creating or modifying architecture.
2. Implement only the active milestone.
3. Prefer the simplest reliable implementation.
4. Keep components independently testable.
5. Build and test whenever practical.
6. Document assumptions and limitations.
7. Do not claim tests passed without executing them.
8. Do not modify locked requirements without explicit approval.

## Current milestone

**Engine-first (M2 + M3a) is done:** built, tested (87 tests on the iPad) and hand-tested by the user. See `docs/logs/M2-engine.md` for what was verified and what was not. No next phase is active; do not start one without the user's go-ahead.

What exists: routine and pet scheduling, tap hotspots, the customization panel, hybrid time and weather (Open-Meteo, city search, cache), and the power policy, all on script-made stand-in art.

What comes next, in order (spec §9 allows reordering):

1. Spotify: a one-day App Remote spike, then M3b. Needs separate approval. Until then the computer hotspot shows a "Music coming soon" card.
2. Art-direction pass (experimental, on a branch): the reference board is side-profile, half-body characters hidden below a detailed desk, and a dense cyberpunk city. It is done as a new scene with its own `perspective` tag, characters, pets and art build script, chosen with `-scene <folder>`. Stand-ins (marked `"stand-in"` in `provenance` / `standIns`) are replaced then.
3. M4: power tuning and polish. M0's energy baseline is still unmeasured.

Working method: the lead writes each task's brief and acceptance tests, a subagent implements, the lead reviews, re-runs the tests on the iPad and commits.

## Reusable engine vs art

The engine must run unchanged with any art direction. The full table is in the plan (`docs/plans/2026-11-14-engine-first.md`, "What is reusable").

- **Reusable (keep art-free):** scaling, pack loading and validation, layer order, clock, saved settings, animation timing and safe exits, routine and pet scheduling, hotspots, environment and weather, customization panel, power policy.
- **Art-specific (expect to replace):** `ArtSource/`, `LoFiRoom/Assets/`, `Tools/build_art.py`, `Tools/cutout.py`, stand-in frames, scene manifest values.
- **Rule:** no Swift file outside tests names an animation, pack or scene. Resting animations, routines and tap reactions come from pack manifests (`fallbackAnimation`, `routine`, `onTap`). `RoomConfig`'s default pack names are the only exception; unknown names fall back.
- **Proof:** tests run the engine against a synthetic fixture scene with a different canvas, different animation names and no extras. Every new behaviour gets one fixture assertion.

## Public repository

This repo is public at https://github.com/farhaniqbalta/LofiStudyRoom. Never commit device IDs, Apple team IDs, API keys, personal email addresses or absolute home paths; they belong in the git-ignored `CLAUDE.local.md`. The concept images in `docs/reference/` stay local. Push after each task's commit.

## Completion requirements

Provide:

- Working source code.
- Build and test results.
- Architecture summary.
- Performance observations.
- Known limitations.
- Milestone acceptance checklist.

Stop after each milestone and request approval before starting the next.