# Engine-First (M2 + M3a) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the room's behaviour engine before final art:
- the routine scheduler and pet behaviour
- tap interactions
- the customization panel
- hybrid time and weather
- the power policy

Script-made stand-in art makes every state visible.

**Architecture:**
- **Behaviour is pure, testable logic** (`Domain/`, `Application/`).
- **Time is injected.** Timers and clocks are passed in, following `ClockDriver`'s pattern of a one-shot timer plus notifications, with no polling.
- **`SceneCoordinator` is the only thing that pushes state into `LoFiSKScene`.**
- **The UI is SwiftUI overlays.** Hotspots are transparent SwiftUI buttons placed over scene anchors, which gives tap handling and VoiceOver for free.
- **Art is replaceable.** Every new visual is an optional, manifest-driven sprite.

**Tech Stack:** Swift 6, SwiftUI, SpriteKit, URLSession async/await, XCTest. XcodeGen and the Python 3 stdlib are used for tools. No third-party dependencies.

**Spec:** `docs/spec/LOCKED_MVP_SPEC.md` (§1.3, §1.4, §1.7, §5, §7, §8.2). The review report `docs/spec/MVP_REVIEW_REPORT.md` is advisory; its D5, D6 and D7 defaults are adopted. User decisions for this phase:
- **Art:** script stand-ins.
- **Spotify:** deferred.
- **Weather location:** city search only, with no location permission.

## Why engine first: the art will change completely

The current PixelLab art is a placeholder direction. The reference board (`docs/reference/mvp-board.png`, local only) is very different:
- **Characters:** side profile, half-body, with the lower body hidden behind the desk. The current art is a full body seen from behind.
- **Desk:** much more detailed (monitor with code, lamp, mug, clock, cat on the desk, shelves).
- **City:** dense cyberpunk (neon signs, elevated train, rain). The current art is a quiet lo-fi skyline.

That is a new scene, new characters and new pets, not a re-skin. The new direction is **experimental**, so the engine must work unchanged with either art set, and both must be able to live side by side.

### What is reusable (art-independent)

| Area | Code | Why it survives an art change |
|---|---|---|
| Scaling | `Rendering/ScalePolicy.swift` | Works from the scene manifest's canvas and safe rectangle, at any size |
| Pack loading and validation | `Infrastructure/SpriteAssetRepository.swift`, `Domain/SpritePack.swift`, `Domain/ScenePack.swift` | Reads whatever the manifests declare; rejects mismatched `perspective` |
| Layer order | `Rendering/LoFiSKScene.swift` groups | `foreground` holds any occluder: today the chair back, in the new art the desk front that hides the half-body |
| Clock | `Domain/ClockTime.swift`, `Application/ClockDriver.swift`, `Rendering/PixelClockNode.swift` | Glyph size, slot positions and bezel come from the clock skin manifest |
| Saved settings | `Application/RoomStateStore.swift` | Stores folder names; unknown names fall back to the first pack that loads |
| Animation timing, safe exits | Task 2 `ActorTimeline` | Pure arithmetic on whatever frames and fps a manifest declares |
| Routine and pet scheduling | Task 3 `RoutineScheduler` | Driven by manifest-declared routines (see Task 1B), never by built-in names |
| Hotspots | Task 4 manifest `hotspots`, Task 5 `HotspotOverlay` | Rectangles come from the scene manifest; 44 pt padding is applied at runtime |
| Environment and weather | Tasks 1 and 6 | No art at all; the scene only receives a `ResolvedScene` |
| Customization panel | Task 7 | Lists whatever packs the active scene accepts |
| Power policy | Task 8 | No art at all |

### What is art-specific (expected to be replaced)

- `ArtSource/`, `LoFiRoom/Assets/`, `Tools/build_art.py` and `Tools/cutout.py`: the current images and the script that cuts them. The new direction gets its own source images and build script.
- The stand-in frames from Task 4: they shift pixels of the current sprites, so they are throwaway.
- The scene manifest values: anchors, hotspot rectangles, canvas and safe sizes.

### What was not yet art-independent in M1 (fixed by Task 1B)

Earlier I said a new camera angle needs "no Swift changes". That was too optimistic. Four things are tied to the current art:
- `LoFiSKScene.show` hardcodes the resting animations `"study"`, `"sleep"` and `"idle"`.
- The planned `RoutineConfig` hardcoded `drink`, `stretch` and `rest`.
- The scene is fixed to `StudyRoom01` (a constructor default, with no way to choose another).
- `SpriteAssetRepository.folders(in:)` lists every pack, even ones made for a different `perspective`, so two art directions in one build would offer incompatible packs.

### How an art experiment is done later

1. Work on a branch, for example `art/cyberpunk-profile`, so `main` keeps working.
2. Add a new scene folder (for example `Scenes/CyberDesk01`) with its own `perspective` tag, plus character, pet and scenery packs carrying that tag. Old packs stay.
3. Write that direction's own art build script beside `Tools/build_art.py`.
4. Launch with `-scene CyberDesk01`. The engine, tests and settings are unchanged.
5. Compare both directions on the iPad, then keep one.

## Global Constraints

- **Deployment target:** iPadOS 26.0. Swift 6 language mode. No third-party dependencies.
- **Build and test:** on the physical iPad only. `$IPAD` and `$DEVELOPMENT_TEAM` come from `CLAUDE.local.md`:
  - `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
  - `xcodebuild test -project LoFiRoom.xcodeproj -scheme LoFiRoom -destination "platform=iOS,id=$IPAD" -allowProvisioningUpdates -derivedDataPath build`
  - Run `xcodegen generate` after adding Swift files.
- **No per-frame business logic.** Scheduling and refresh use one-shot `Timer`s; there are no `update(_:)` overrides.
- **Layer rules** (`CLAUDE.md`): `scenery < room < actors < foreground < objects < debug`. Actors contain no furniture. Textures use `.nearest`. No full-screen transparent textures. A one-frame animation runs no action.
- **Packs:** `LoFiRoom/Assets` is generated by `python3 Tools/build_art.py`; never hand-edit it. Every stand-in asset carries `"provenance": "stand-in …"`.
- **Clock:** always shows the real time. Manual Day/Night never changes it.
- **Weather refresh:** every 30 min while in the foreground, and on returning to the foreground if the data is older than 30 min. Never per frame.
- **Weather API:** Open-Meteo forecast `https://api.open-meteo.com/v1/forecast` and geocoding `https://geocoding-api.open-meteo.com/v1/search`. No API key.
- **Attribution:** the text "Weather data by Open-Meteo.com" with a link appears in the customization panel.
- **Hotspots:** at least 44×44 pt each, with VoiceOver labels "Cat", "Desk lamp", "Window", "Computer".
- **Keep Screen Awake:** off by default. Label: "Keep screen awake (uses more battery)".
- **Public repo:** never commit device IDs, team IDs, API keys or personal emails. Push after each task's commit.
- **Art independence:** no Swift file outside tests may name an animation, pack folder or scene. Names come from manifests. The only exception is `RoomConfig`'s default pack names, which are preferences with a fallback.
- **Out of scope:** Spotify, production art, long-run profiling. The computer hotspot only toggles a "Music coming soon" stub panel.

## Review Focus

1. **Upgrading from M1.** A v1 saved config must keep the user's pack choices; a decode failure would reset everything. Test lives in Task 1.
2. **Tap during a one-shot.** Tapping the pet or swapping the character mid-drink waits for the next safe exit and never leaves a prop floating. Test lives in Task 2.
3. **First launch offline with Automatic weather.** The room shows Clear plus clock-based day/night, never a blank or a hang. Settings say "Weather unavailable". Test lives in Task 6.
4. **Background mid-routine, then foreground.** Exactly one routine timer and one weather timer exist afterwards, not two. Test lives in Task 3 (routines) and Task 6 (weather).
5. **City search with no results or a network error.** The panel shows a message and the previous city stays. Test lives in Task 6.
6. **A differently drawn scene.** A scene with another canvas size, other animation names and no rain must run the whole engine. Test lives in Task 1B, and later tasks extend it.

---

### Task 0: Tidy the repo and publish it (before anything else; no app code)

The repo becomes public as `farhaniqbalta/LofiStudyRoom`. User decisions:
- **History:** squash to one clean commit, authored with the GitHub noreply address.
- **Reference images:** stay local only.
- **Licence:** none yet.

**What the audit found:**
- The iPad's device ID is in `CLAUDE.md` and `docs/logs/M0.md`.
- The Apple team ID is in `project.yml` and `docs/logs/M0.md`.
- Both are also in the two existing commits, which are authored with a Gmail address.
- There is no README.
- The reference images have spaces in their names and show a Spotify logo.

**Target layout:**
```
README.md                  what it is, status, how to build, art credits, no-licence note
CLAUDE.md                  agent directions (no private IDs)
CLAUDE.local.md            git-ignored: device ID, team ID, local quirks
project.yml  LoFiRoom/  LoFiRoomTests/  Tools/  ArtSource/
docs/spec/                 LOCKED_MVP_SPEC.md, DESIGN_EXPLORATION_BRIEF.md, MVP_REVIEW_REPORT.md
docs/logs/                 worklog.md, M0.md, M1.md, M2-engine.md
docs/plans/                2026-11-14-engine-first.md
docs/reference/            git-ignored: the two concept images, renamed mvp-board.png and rainy-night-nook.png
```

- [ ] **Step 1: Move files.**
  - `git mv` the three spec documents into `docs/spec/`.
  - Move the two images to `docs/reference/` under the new names.
  - Add `docs/reference/`, `CLAUDE.local.md` and `.DS_Store` to `.gitignore`.
  - `git rm --cached` the two images.
- [ ] **Step 2: Remove private IDs from tracked files.**
  - `project.yml`: `DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}`. XcodeGen expands environment variables.
  - `CLAUDE.md` commands:
    - `IPAD=<device UDID from: xcrun devicectl list devices>`.
    - `export DEVELOPMENT_TEAM=<Apple team ID>` before `xcodegen generate`.
    - Add the line "Private values live in `CLAUDE.local.md`."
  - `docs/logs/M0.md`: replace the UDID and team ID with "(see `CLAUDE.local.md`)".
  - Create `CLAUDE.local.md` holding the real UDID, the team ID and the `DEVELOPER_DIR` note.
- [ ] **Step 3: Fix paths and wording in the docs.**
  - `CLAUDE.md`: source-of-truth paths become `docs/spec/…`; the visual reference paths become `docs/reference/…`, marked "local only, not in the repo".
  - Cross-references inside the three spec documents and the logs get the new paths.
  - The M0 and M1 logs are read through once for anything personal. The audit grep found no names or emails.
- [ ] **Step 4: Write `README.md`** with these sections:
  - A one-paragraph description.
  - A status table (M0 and M1 done, engine-first next).
  - Requirements (Xcode 27, XcodeGen, an iPad).
  - Build and test commands.
  - A repo map.
  - Art credits: generated with PixelLab, under PixelLab's Terms of Service; hand-made parts by `Tools/build_art.py`.
  - The line "No licence has been chosen yet; all rights reserved."
- [ ] **Step 5: Verify clean.**
  - `git grep -n -I -i -E "$IPAD|$DEVELOPMENT_TEAM|gmail|/Users/"` returns nothing (both values come from `CLAUDE.local.md`).
  - `git status --short` shows only the intended changes.
  - `export DEVELOPMENT_TEAM=… && xcodegen generate && xcodebuild test …` on the iPad still reports `Executed 14 tests, with 0 failures`.
- [ ] **Step 6: Squash history.**
  - Read the noreply address: `gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"'`.
  - Set it as this repo's `user.email` (local config only).
  - Run `git checkout --orphan public && git add -A && git commit -m "Lo-Fi Room: M0 and M1 (SpriteKit room, swappable packs, pixel clock)"`, then `git branch -M main`. The old commits are no longer referenced.
  - Check that `git log --format='%ae %s'` shows one commit with the noreply address.
  - Check that `git grep` over `$(git rev-list --all)` finds none of the private strings.
- [ ] **Step 7: Publish.**
  - Run `gh repo create LofiStudyRoom --public --source . --remote origin --push --description "A calm, low-power pixel-art lo-fi study room for iPad (SwiftUI + SpriteKit)"`.
  - Confirm with `gh repo view --json visibility,url`, and report the URL.

### Task 0B: Update the plan and directions in Markdown (no app code)

**Files:**
- Create: `docs/plans/2026-11-14-engine-first.md` (this plan, copied verbatim), `docs/logs/M2-engine.md`
- Modify: `CLAUDE.md`, `docs/logs/worklog.md`

- [ ] **Step 1: Copy this plan** to `docs/plans/2026-11-14-engine-first.md`.
- [ ] **Step 2: Update `CLAUDE.md`:**
  - **Current milestone:**
    - M1 is approved.
    - The active milestone is "Engine-first (M2 + M3a)": the routine scheduler, pet behaviour, tap interactions, customization panel, hybrid time and weather, and the power policy, all on script-made stand-in art.
    - Link the plan file.
  - **Order of work:** Engine-first → Spotify spike and M3b → art-direction pass → M4. Spec §9 allows reordering.
  - **Art direction:** the current PixelLab art is kept but is off from the reference board. Art experiments come after the engine, by adding scene, character and pet packs with a new `perspective` tag and no Swift changes.
  - **Stand-in rule:** stand-ins carry `"provenance": "stand-in …"` and must be replaced in the art pass.
  - **Decisions:** weather location is city search only. Spotify waits for the App Remote spike, which needs separate approval.
  - **Public repo rule:** never commit device IDs, team IDs, API keys or personal emails; they go in `CLAUDE.local.md`.
- [ ] **Step 3: Update the worklog.** Mark M1 "Approved" and add `| Engine-first (M2 + M3a) | Planned | [M2-engine.md](M2-engine.md) |`.
- [ ] **Step 4: Create `docs/logs/M2-engine.md`:** Status (Planned), Scope (plan link), Decisions (the user's answers), empty Done / Results / Open issues, Next step (Task 1).
- [ ] **Step 5: Commit** `docs: engine-first plan and updated directions` **and push.**
- [ ] **Step 6: Stop and show the user the changed Markdown.** Start Task 1 only after the user approves it.

### Task 1: Config schema v2 and the environment domain

**Files:**
- Create: `LoFiRoom/Domain/Environment.swift`
- Modify: `LoFiRoom/Application/RoomStateStore.swift` (`RoomConfig`)
- Test: `LoFiRoomTests/EnvironmentTests.swift`

**Interfaces:**
- Produces:
  - `enum DayPhase: String, Codable { case day, night }`
  - `enum Sky: String, Codable { case clear, rain }`
  - `enum TimeSetting: Codable, Equatable { case automatic, manual(DayPhase) }`
  - `enum WeatherSetting: Codable, Equatable { case automatic, manual(Sky) }`
  - `struct City: Codable, Equatable { var name: String; var latitude: Double; var longitude: Double }`
  - `struct WeatherSnapshot: Codable, Equatable { var sky: Sky; var sunrise: Date?; var sunset: Date?; var fetched: Date }`
  - `struct ResolvedScene: Equatable { var phase: DayPhase; var sky: Sky; var lampOn: Bool }`
  - `enum EnvironmentRules`:
    - `static func sky(forWeatherCode: Int) -> Sky`
    - `static func phase(at: Date, snapshot: WeatherSnapshot?, calendar: Calendar) -> DayPhase`
    - `static func resolve(config: RoomConfig, snapshot: WeatherSnapshot?, now: Date, calendar: Calendar) -> ResolvedScene`
    - `static func isStale(_: WeatherSnapshot, now: Date) -> Bool`
  - New `RoomConfig` fields: `lampOn = true`, `time: TimeSetting = .automatic`, `weather: WeatherSetting = .automatic`, `city: City? = nil`, `keepAwake = false`, `schemaVersion = 2`.

- [ ] **Step 1: Write the failing tests** in `EnvironmentTests`:
  - `testV1ConfigKeepsPackChoices`
    - Input: the JSON `{"schemaVersion":1,"character":"Girl01","pet":"BlackCat","scenery":"NeonCity02","clock":"RetroDigital01"}`.
    - Expect: the decoded config keeps those four values, plus `lampOn == true`, `time == .automatic`, `weather == .automatic`, `city == nil`, `keepAwake == false`.
  - `testWeatherCodeMapping`
    - Rain for 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99.
    - Clear for 0, 1, 2, 3, 45, 48.
    - Unknown 1234 maps to Clear.
  - `testPhaseUsesSunriseSunsetThenFallsBack`
    - With a snapshot sunrise 06:10 and sunset 17:55 (Asia/Jakarta): 06:09 is night, 06:10 is day, 17:54 is day, 17:55 is night.
    - With no snapshot: 05:59 is night, 06:00 is day, 17:59 is day, 18:00 is night.
  - `testManualSettingsWinOverSnapshot`
    - `.manual(.night)` and `.manual(.clear)` with a midday rain snapshot resolve to night and clear.
  - `testStaleAfterTwoHours`
    - A snapshot fetched at T is not stale at T+7199 s and is stale at T+7200 s.
- [ ] **Step 2: Run** `xcodebuild test … -only-testing:LoFiRoomTests/EnvironmentTests`. Expect a compile failure: `EnvironmentRules` is not defined.
- [ ] **Step 3: Implement** `Environment.swift`, and add the fields plus a hand-written `RoomConfig.init(from:)` that uses `decodeIfPresent` with the defaults above.
  - Why hand-written: synthesized `Codable` ignores default values and throws on missing keys.
  - `phase(at:)` with a snapshot compares times of day on the snapshot's sunrise and sunset dates, shifted to `at`'s day.
- [ ] **Step 4: Run** the tests. Expect all 5 to pass, and the 14 existing tests to still pass.
- [ ] **Step 5: Commit** `feat: config v2 and environment rules`.

### Task 1B: Make the engine art-independent

**Files:**
- Modify: `LoFiRoom/Domain/SpritePack.swift`, `LoFiRoom/Rendering/LoFiSKScene.swift`, `LoFiRoom/Infrastructure/SpriteAssetRepository.swift`, `LoFiRoom/Presentation/SceneContainer.swift`, `Tools/build_art.py`, `Tools/preview.py`
- Create: `LoFiRoomTests/FixtureScene.swift`
- Test: `LoFiRoomTests/ArtIndependenceTests.swift`

**Interfaces:**
- Produces:
  - `SpritePack.Animation` gains two fields:
    - `routine: RoutineSpec?` with `struct RoutineSpec: Codable, Equatable { var weight: Double; var cooldown: TimeInterval }`. An animation with a `routine` can be picked by the scheduler.
    - `onTap: Bool?`. The animation played when the actor is tapped.
  - The resting animation of every pack is its `fallbackAnimation`. `LoFiSKScene.show` uses it instead of a hardcoded name.
  - `SpriteAssetRepository.folders(in:)` returns only packs whose manifest `perspective` matches the active scene.
  - `SpriteAssetRepository(sceneName:)` is chosen by the `-scene <folder>` launch argument. The default is the first folder in `Scenes/`.
  - **Test helper** `FixtureScene.make(in: URL) throws -> URL` writes a synthetic scene to a temporary folder, using tiny PNGs made with `UIGraphicsImageRenderer`:
    - a 320×240 canvas with different anchors
    - perspective `fixture-profile-v1`
    - a character with animations `type` (fallback), `sip` (routine) and `lean` (routine)
    - a pet with `nap` (fallback) and `purr` (onTap)
    - a scenery pack and a clock skin with 4×6 glyphs
    - no rain or day/night extras
  - `build_art.py` writes `routine` and `onTap` into the current packs: Boy01 and Girl01 `drink`, `stretch` and `rest` with the weights and cooldowns from Task 3; cats `react` with `onTap`.
  - `preview.py` gets a `--scene` option, and reads the clock skin from the scene's packs instead of a fixed name.

- [ ] **Step 1: Write the failing tests:**
  - `testFixtureSceneLoadsAndRuns`
    - Load the fixture with `SpriteAssetRepository(root:sceneName:)` and start a `SceneCoordinator`.
    - Expect: the character rests on `type` and the pet on `nap`; the clock shows text; the scene's canvas is 320×240.
  - `testPackListsAreFilteredByPerspective`
    - Copy one bundled character pack into the fixture root.
    - Expect: `folders(in: "Characters")` does not list it.
  - `testRestingAnimationComesFromTheManifest`
    - Expect: bundled Boy01 rests on `study` because its manifest says so, not because the code does.
  - `testNoArtNamesInAppSource`
    - Read the app's Swift sources from the test bundle's source path (`#filePath`, up to the project root).
    - Expect: none contains the strings `"study"`, `"sleep"`, `"drink"`, `"Boy01"` or `"StudyRoom01"`, except inside `RoomStateStore.swift`.
- [ ] **Step 2: Run** `-only-testing:LoFiRoomTests/ArtIndependenceTests`. Expect a fail.
- [ ] **Step 3: Implement** the manifest fields, the perspective filter, the `-scene` argument, the build-script and preview changes, and rebuild the packs.
- [ ] **Step 4: Run** all tests. Expect a pass, with the existing 14 tests unchanged.
- [ ] **Step 5: Commit and push** `refactor: drive resting animations, routines and scene choice from manifests`.

**Rule for every later task:** each new behaviour gets one assertion against the fixture scene as well as the bundled scene. Tasks 3 to 7 list theirs.

### Task 2: One-shot animations with safe exits

**Files:**
- Modify: `LoFiRoom/Domain/SpritePack.swift`
- Create: `LoFiRoom/Domain/ActorTimeline.swift`
- Modify: `LoFiRoom/Rendering/PackSpriteNode.swift`
- Test: `LoFiRoomTests/ActorTimelineTests.swift`

**Interfaces:**
- Consumes: `SpritePack.Animation`, `LoadedPack`, `PackSpriteNode.show(_:animation:)`.
- Produces:
  - **Manifest fields:** `SpritePack.Animation` gains `loop: Bool?` (nil means true) and `safeExits: [Int]?` (nil means every frame).
  - **Validation:** `problems()` also reports `"animation 'x' safe exit N is not one of its frames"`.
  - `struct ActorTimeline`:
    - `init(animation: SpritePack.Animation)`
    - `func frameIndex(at elapsed: TimeInterval) -> Int` returns the sheet frame index. One-shots clamp to the last frame.
    - `func isFinished(at: TimeInterval) -> Bool` is always false for loops.
    - `func nextSafeExit(after elapsed: TimeInterval) -> TimeInterval` gives the elapsed time at which the next safe-exit frame ends.
  - `PackSpriteNode`:
    - `func play(_ name: String, then next: @escaping () -> Void)` plays a one-shot, then calls `next`.
    - `func requestExit(then: @escaping () -> Void)` waits until `nextSafeExit`, then runs `then`. A second request replaces the first; it never cuts the current frame.
    - `private(set) var currentAnimation: String`

- [ ] **Step 1: Write the failing tests:**
  - `testLoopFrameIndex`
    - Animation `frames [4,5,6]` at 2 fps.
    - Expect: elapsed 0 gives 4, 0.5 gives 5, 1.49 gives 6, 1.5 gives 4.
  - `testOneShotClampsAndFinishes`
    - Animation `loop false`, `frames [0,1,2]` at 2 fps.
    - Expect: frame index 2 at 10 s; `isFinished` is false at 1.49 and true at 1.5.
  - `testNextSafeExit`
    - Animation `frames [0,1,2,3]` at 1 fps, `safeExits [0,3]`.
    - Expect: after 0.2 the next exit is 1.0; after 1.0 it is 4.0; for a loop, after 4.1 it is 5.0.
  - `testSafeExitMustBeAFrame`
    - Expect: `safeExits [9]` produces the problem message above.
- [ ] **Step 2: Run** `-only-testing:LoFiRoomTests/ActorTimelineTests`. Expect a compile failure.
- [ ] **Step 3: Implement** `ActorTimeline` as pure arithmetic on `frames.count` and `fps`.
  - `PackSpriteNode` schedules with `SKAction.sequence([.wait(forDuration:), .run])`. The wait duration comes from `ActorTimeline`.
  - It records `startTime` from `CACurrentMediaTime()` at `show`/`play` so `requestExit` knows the elapsed time.
- [ ] **Step 4: Run** all tests. Expect a pass.
- [ ] **Step 5: Commit** `feat: one-shot animations and safe exits`.

### Task 3: Routine and pet scheduling

**Files:**
- Create: `LoFiRoom/Application/RoutineScheduler.swift`
- Modify: `LoFiRoom/Application/SceneCoordinator.swift`
- Test: `LoFiRoomTests/RoutineSchedulerTests.swift`

**Interfaces:**
- Consumes: `PackSpriteNode.play`, `requestExit`, `show`.
- Produces:
  - `struct RoutineConfig`:
    - `var idle: String`
    - `var routines: [String: RoutineSpec]`
    - `var delay: ClosedRange<TimeInterval>`
    - `static func from(_ pack: SpritePack, delay: ClosedRange<TimeInterval>) -> RoutineConfig`. The idle animation is the pack's `fallbackAnimation`; routines are its animations with a `routine` spec.
    - Pacing is not art, so it stays in code: characters `90...240` s, pets `60...180` s.
  - `struct RoutineScheduler`:
    - `init(config:)`
    - `mutating func next(now: Date, random: inout some RandomNumberGenerator) -> (routine: String?, delay: TimeInterval)`. A nil routine means stay idle because everything is on cooldown.
  - `protocol TimerScheduling { func schedule(after: TimeInterval, _ fire: @escaping @MainActor () -> Void) -> Cancellable }`. The live implementation wraps `Timer`; tests pass a fake.
  - `SceneCoordinator`:
    - `var timers: TimerScheduling` (default live)
    - `var routineSpeed: Double = 1`, set from the `-routineSpeed` launch argument
    - `func setActive(_ active: Bool)`. False cancels both routine timers; true schedules each once.
    - `func petTapped()` plays the pet's `onTap` animation at its next safe exit, then returns to the previous animation. A pet without one ignores the tap.

- [ ] **Step 1: Write the failing tests:**
  - `testNextRespectsWeightsAndCooldowns`
    - Seeded generator, `RoutineConfig.character`.
    - Expect: over 1,000 picks, drink is chosen at least 2× as often as stretch. A routine chosen at T is not chosen again before T + cooldown.
  - `testAllOnCooldownStaysIdle`
  - `testDelayWithinRange`
  - `testInactiveCoordinatorSchedulesNothing`
    - Fake timers; call `setActive(false)`.
    - Expect: zero pending timers. After `setActive(true)` twice, exactly 2 are pending (character plus pet) — Review Focus 4.
  - `testPetTapReturnsToPreviousState`
    - Pet in `idle`, tapped.
    - Expect: after the fake timers fire, `currentAnimation` goes `react`, then `idle`.
  - `testFixtureRoutinesUseOnlyDeclaredNames`
    - Fixture scene, 200 fake timer firings.
    - Expect: the character plays only `sip` and `lean`; the pet's tap plays `purr`.
  - `testTapDuringDrinkWaitsForSafeExit`
    - Character in `drink`; call `select("Girl01")`.
    - Expect: the swap happens only after the scheduled safe-exit timer fires — Review Focus 2.
- [ ] **Step 2: Run** `-only-testing:LoFiRoomTests/RoutineSchedulerTests`. Expect a compile failure.
- [ ] **Step 3: Implement.**
  - Weighted pick over routines that are off cooldown.
  - Delay is uniform in the range, divided by `routineSpeed`.
  - The coordinator chains: timer fires → `requestExit` → `play(routine)` → back to idle → schedule the next one.
  - `select(_:in:)` for Characters goes through `requestExit`.
- [ ] **Step 4: Run** all tests. Expect a pass.
- [ ] **Step 5: Commit** `feat: routine and pet schedulers`.

### Task 4: Stand-in art and scene visuals

**Files:**
- Modify: `Tools/build_art.py`, `LoFiRoom/Domain/ScenePack.swift`, `LoFiRoom/Rendering/LoFiSKScene.swift`
- Test: `LoFiRoomTests/SceneVisualsTests.swift`; extend `testEveryBundledPackLoadsAndIsNearestFiltered`

**Interfaces:**
- Consumes: `ResolvedScene` (Task 1).
- Produces:
  - **Stand-in art from `build_art.py`:**
    - Characters `drink` (5 frames, loop false, `safeExits [0,4]`), `stretch` (4 frames, loop false, `safeExits [0,3]`), `rest` (2 frames, loop false, `safeExits [0,1]`).
    - Pets `idle` (2 frames) and `react` (3 frames, loop false, `safeExits [0,2]`).
  - **`ScenePack` optional fields:**
    - `rain: SceneEffect?` with `struct SceneEffect: Codable, Equatable { var sheet: String; var frame: PixelSize; var fps: Double; var anchor: String }`.
    - `dayOverlay: String?`, `nightOverlay: String?`
    - `roomLampOff: String?`: a full room image with the lamp cone painted out. It replaces the room texture while the lamp is off.
    - `hotspots: [String: ScenePack.Anchor]`, keyed `pet`, `lamp`, `window`, `computer`, in logical pixels. The 44 pt minimum is applied at runtime (Task 5), because the pixel scale depends on the scene's canvas size.
  - `LoFiSKScene`:
    - `func apply(_ scene: ResolvedScene, reduceMotion: Bool)`
    - `func viewRect(forHotspot: String) -> CGRect?` in view coordinates.
- Stand-in recipes. These are **throwaway**: they shift pixels of the current sprites and will not carry over to the new art. Only the manifest fields and scene nodes above are reusable.
  - **drink:** existing frames with a 4×5 mug sprite moved from the desk to the head.
  - **stretch:** arms rows shifted up 1–3 px.
  - **rest:** head rows shifted 2 px toward the window.
  - **pet idle and react:** the tail cluster or the whole sprite shifted 1 px.
  - **rain:** 6 frames, 184×128, sparse 1×3 streaks, alpha 160, drawn in the `scenery` group above the city.
  - **overlays:** 1-in-2 dithered dark-blue (night) and pale-amber (day) layers covering the room's wall area only, not full-screen.
  - **lamp off:** `room_lamp_off.png`, a copy of the room with the lit cone and the bulb glow recoloured to the neighbouring wall and desk tones by a hand-traced polygon. Swapping one texture costs nothing extra while idle.

- [ ] **Step 1: Write the failing tests:**
  - `testBundledPacksHaveAllRoutines`
    - Expect: Boy01 and Girl01 have `drink`, `stretch` and `rest`. Both cats have `idle` and `react`. Every stand-in manifest's `provenance` starts with `"stand-in"`.
  - `testApplyTogglesLayersWithoutAddingNodes`
    - Apply night, rain and lamp-off, then day, clear and lamp-on, 50 times.
    - Expect: node count is unchanged. The rain node is hidden when clear and paused when hidden.
  - `testReduceMotionHalvesRainFps`
  - `testFixtureWithoutExtrasApplies`
    - Fixture scene (no rain, no overlays, no lamp-off image).
    - Expect: `apply` succeeds and changes nothing visible.
- [ ] **Step 2: Run** `python3 Tools/build_art.py`, then `-only-testing:LoFiRoomTests/SceneVisualsTests`. Expect a fail.
- [ ] **Step 3: Implement** the `build_art.py` additions and the scene nodes.
  - Rain lives in the scenery group.
  - Overlays and lamp art live in the room group, above the room sprite.
  - `apply` only sets `isHidden`, `isPaused` and textures.
- [ ] **Step 4: Run** all tests. Then run `python3 Tools/preview.py Boy01 OrangeCat NeonCity01 build/art/pv.png` and look at it. Expect a pass, and the preview to look unchanged in the default state.
- [ ] **Step 5: Commit** `feat: stand-in routine art, rain, day/night and lamp layers`.

### Task 5: Hotspots and taps

**Files:**
- Create: `LoFiRoom/Presentation/HotspotOverlay.swift`
- Modify: `LoFiRoom/Presentation/SceneContainer.swift`, `LoFiRoom/App/LoFiRoomApp.swift`, `LoFiRoom/Application/SceneCoordinator.swift`
- Test: `LoFiRoomTests/InteractionTests.swift`

**Interfaces:**
- Consumes: `LoFiSKScene.viewRect(forHotspot:)`, `SceneCoordinator.petTapped()`.
- Produces:
  - `SceneCoordinator`:
    - `func lampTapped()` toggles and saves `config.lampOn`, then re-applies the resolved scene.
    - `func windowTapped()` cycles `repository.folders(in: "Scenery")`.
    - `@Published var musicPanelVisible: Bool`
    - `func computerTapped()` toggles it.
    - `SceneCoordinator` becomes an `ObservableObject` so SwiftUI can bind.
  - `HotspotOverlay`: one `Button` per hotspot, positioned by `viewRect` and padded to 44×44 pt minimum. Clear background, with the `accessibilityLabel`s from Global Constraints.
  - `MusicStubPanel`: a small card that says "Music coming soon". It dismisses on tap.

- [ ] **Step 1: Write the failing tests:**
  - `testLampToggleSavesAndApplies`
  - `testWindowCyclesSceneryAndSaves`
    - Expect: NeonCity01 → NeonCity02 → NeonCity01.
  - `testComputerTogglesMusicStub`
  - `testHotspotViewRectsAreAtLeast44Points`
    - Use an SKView at 1194×834 pt, with both the bundled and the fixture scene.
- [ ] **Step 2: Run** `-only-testing:LoFiRoomTests/InteractionTests`. Expect a fail.
- [ ] **Step 3: Implement.**
  - `SceneContainer` becomes a `ZStack` of the `SKView` representable, `HotspotOverlay` and the stub panel.
  - The coordinator is created once in `LoFiRoomApp` as a `@StateObject`, replacing `makeCoordinator`, and passed down.
- [ ] **Step 4: Run** all tests. Expect a pass.
- [ ] **Step 5: Commit** `feat: tap hotspots for pet, lamp, window, computer`.

### Task 6: Weather provider and environment controller

**Files:**
- Create: `LoFiRoom/Infrastructure/WeatherProvider.swift`, `LoFiRoom/Application/EnvironmentController.swift`
- Test: `LoFiRoomTests/WeatherTests.swift`

**Interfaces:**
- Consumes: `EnvironmentRules`, `WeatherSnapshot`, `City`, `TimerScheduling`.
- Produces:
  - `protocol WeatherProviding`:
    - `func snapshot(for: City) async throws -> WeatherSnapshot`
    - `func searchCities(_ name: String) async throws -> [City]`
  - `struct OpenMeteoProvider: WeatherProviding`:
    - `init(session: URLSession = .shared)`
    - The forecast query uses `latitude`, `longitude`, `current=weather_code`, `daily=sunrise,sunset`, `timezone=auto`, `forecast_days=1`.
    - The search query uses `name`, `count=5`, `language=en`, `format=json`.
  - `@MainActor final class EnvironmentController`:
    - `init(provider:timers:cacheURL:now:onChange: (WeatherSnapshot?) -> Void)`
    - `func start(city: City?)`, `func stop()`, `func refreshIfStale()`
    - `private(set) var status: WeatherStatus`, with `enum WeatherStatus: Equatable { case off, loading, current, stale, unavailable }`
    - The cache is a JSON file in Application Support (`weather.json`). It is written on every successful fetch and read at `start`.
  - `SceneCoordinator.start` creates the controller; `setActive` calls `refreshIfStale` or `stop`.

- [ ] **Step 1: Write the failing tests** with a `URLProtocol` stub that serves canned JSON or errors:
  - `testParsesForecast`
    - Canned body: `{"current":{"weather_code":61},"daily":{"sunrise":["2026-11-14T05:31"],"sunset":["2026-11-14T17:49"]},"timezone":"Asia/Jakarta"}`.
    - Expect: `sky == .rain`, sunrise at 05:31 Jakarta.
  - `testParsesCitySearchAndEmptyResult`
    - A body without `results` returns `[]` — Review Focus 5.
  - `testOfflineFirstLaunchIsUnavailableNotBlank`
    - No cache, network error.
    - Expect: `status == .unavailable`, `onChange(nil)` was called, and the resolved scene uses `.clear` — Review Focus 3.
  - `testOfflineUsesCache`
    - The cache holds a snapshot 1 h old.
    - Expect: `status == .current`.
    - With the cache 3 h old: `status == .stale`.
  - `testRefreshEvery30MinutesOnlyOneTimer`
    - Call `start`, then `stop`, then `start`.
    - Expect: exactly 1 pending timer, with a 1800 s delay — Review Focus 4.
  - `testManualWeatherIsNeverOverwritten`
    - Config `.manual(.clear)` plus a fetched rain snapshot.
    - Expect: the resolved sky is `.clear`, and the config is unchanged.
- [ ] **Step 2: Run** `-only-testing:LoFiRoomTests/WeatherTests`. Expect a compile failure.
- [ ] **Step 3: Implement.**
  - Decode with `JSONDecoder` into private response structs.
  - Parse daily times with `DateFormatter` (`yyyy-MM-dd'T'HH:mm`, `timeZone` from the response's `timezone`).
  - Errors map to `.unavailable` and are never thrown into the UI.
- [ ] **Step 4: Run** all tests. Expect a pass.
- [ ] **Step 5: Commit** `feat: Open-Meteo weather with cache and 30-minute refresh`.

### Task 7: Customization panel

**Files:**
- Create: `LoFiRoom/Presentation/CustomizationSheet.swift`
- Modify: `LoFiRoom/Presentation/SceneContainer.swift`, `LoFiRoom/Application/SceneCoordinator.swift`
- Test: `LoFiRoomTests/CustomizationTests.swift`

**Interfaces:**
- Consumes: `select(_:in:)`, `EnvironmentController.status`, `WeatherProviding.searchCities`.
- Produces:
  - `SceneCoordinator`:
    - `func setTime(_: TimeSetting)`, `func setWeather(_: WeatherSetting)`, `func setCity(_: City)`, `func setKeepAwake(_: Bool)`. Each saves and re-applies.
    - `@Published var panelVisible: Bool`
  - `CustomizationSheet` is a SwiftUI `Form` with these sections:
    - Character, Pet, Scenery (pickers over `repository.folders`).
    - Time: Automatic / Day / Night.
    - Weather: Automatic / Clear / Rain, with a city search field and a status line. The status line reads "Updated hh:mm", "Weather may be out of date" or "Weather unavailable".
    - Display: Keep screen awake.
    - About: Open-Meteo attribution link.
  - **Open gesture:** a two-finger tap anywhere on the room, plus an always-present but transparent VoiceOver-only button labelled "Room settings". Nothing visible during passive viewing.

- [ ] **Step 1: Write the failing tests:**
  - `testSettersSaveAndApply`
    - Expect: each setter changes `store.config` and the scene's applied `ResolvedScene`.
  - `testManualNightKeepsRealClock`
    - Real time 10:15 UTC; call `setTime(.manual(.night))`.
    - Expect: the clock text is still `"10:15"`.
  - `testPickersListOnlyTheActiveScenesPacks`
    - Expect: with the fixture scene, the character picker lists only the fixture character.
  - `testFailedCitySearchKeepsPreviousCity`
    - Provider throws.
    - Expect: `config.city` is unchanged, and an error message is published — Review Focus 5.
- [ ] **Step 2: Run** `-only-testing:LoFiRoomTests/CustomizationTests`. Expect a fail.
- [ ] **Step 3: Implement** the setters and the sheet. The sheet only calls coordinator methods.
- [ ] **Step 4: Run** all tests. Expect a pass.
- [ ] **Step 5: Commit** `feat: customization panel`.

### Task 8: Power policy, device check, docs

**Files:**
- Create: `LoFiRoom/Application/PowerPolicy.swift`
- Modify: `LoFiRoom/Presentation/SceneContainer.swift`, `CLAUDE.md`, `docs/logs/worklog.md`
- Create: `docs/logs/M2-engine.md`
- Test: `LoFiRoomTests/PowerPolicyTests.swift`

**Interfaces:**
- Consumes: `SceneCoordinator.setActive`, `RoomConfig.keepAwake`.
- Produces: `struct PowerPolicy`:
  - `static func framesPerSecond(requested: Int, lowPower: Bool, thermal: ProcessInfo.ThermalState) -> Int`
    - Returns `requested` normally, and 15 when `lowPower` is true or `thermal` is `.serious` or above.
  - `static func idleTimerDisabled(keepAwake: Bool, active: Bool) -> Bool`
  - The live wiring lives in `SceneContainer`:
    - `scenePhase` → `coordinator.setActive` and `view.isPaused`.
    - `.NSProcessInfoPowerStateDidChange` and `ProcessInfo.thermalStateDidChangeNotification` → `preferredFramesPerSecond`.
    - `UIApplication.shared.isIdleTimerDisabled` is set from `keepAwake` while active.

- [ ] **Step 1: Write the failing tests:**
  - `testFpsDropsUnderLowPowerOrHeat`, covering every case of the rule above.
  - `testIdleTimerOnlyWhileActiveAndChosen`.
- [ ] **Step 2: Run** `-only-testing:LoFiRoomTests/PowerPolicyTests`. Expect a fail.
- [ ] **Step 3: Implement** and wire it up.
- [ ] **Step 4: Run** all tests. Expect `** TEST SUCCEEDED **`.
- [ ] **Step 5: Device check**, saving screenshots to `build/shots/`.
  - Install and launch with `-debugAnchors YES -routineSpeed 20`.
  - Watch drink, stretch and rest happen within about a minute.
  - Tap the cat, lamp, window and computer.
  - Open the panel with a two-finger tap. Set Manual Night/Rain, then Automatic with the city "Jakarta". Confirm the status reads "Updated …".
  - Enable airplane mode, relaunch, and confirm the cached weather shows.
  - Turn VoiceOver on and confirm the four hotspots and "Room settings" are announced.
- [ ] **Step 6: Docs.**
  - `docs/logs/M2-engine.md`: decisions, the stand-in list, test output and open issues.
  - A worklog index line.
  - `CLAUDE.md` "Current milestone" changes to Engine-first M2+M3a. Note that Spotify (M3b) and the art pass remain.
- [ ] **Step 7: Commit** `feat: power policy; docs for engine-first milestone`.

---

## Execution

The recommended method is **Native**: I implement every task in this session, then one fresh reviewer checks the whole branch. Reasons:
- The 9 tasks share interfaces tightly. `SceneCoordinator` is touched in tasks 3, 5, 6, 7 and 8.
- Every test run needs the one physical iPad, so parallel subagents would queue on it anyway.

The alternative is **Subagent-driven**: a fresh implementer and reviewer per task. It is more thorough and slower.
