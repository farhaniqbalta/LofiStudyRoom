# Lo-Fi Room — Locked MVP Specification & Agent Review Handoff

**Status:** MVP product scope LOCKED for independent technical/design review  
**Version:** 1.0 (2026-11-14)  
**Target:** Native iPad app, landscape only; primary proof-of-concept device is an M1-generation iPad Pro  
**Purpose:** Review the feasibility, internal consistency, architecture and acceptance criteria of the locked MVP **before implementation**. This handoff does **not** authorize expanding scope or writing application code.

> **Product definition:** A quiet, customizable, living **2D pixel-art** lo-fi study room, displayed as a full-screen **foreground iPad app**. It looks like an animated screensaver but is **not** an OS screensaver, lock-screen replacement, idle clicker, or progression game. The room feels alive through sparse animation, subtle real-world integrations, and small contextual interactions, while prioritizing low power usage over high frame rate.

## 0. Rules for reviewing agents

1. Treat Section 1 as locked product decisions. Do **not** silently replace features, frameworks, platforms, or aesthetics.
2. Distinguish a **product requirement** (locked) from an **implementation hypothesis** (reviewable).
3. Investigate critical technical or API constraints; report evidence, dates and links for findings. Do not infer that a reference mockup is a production-ready sprite sheet.
4. Propose the smallest architecture and artwork pipeline that meets the scope; do not build a general-purpose game engine.
5. Flag legal, store-policy, network, energy or API restrictions as risks, with a mitigation and effect on MVP acceptance criteria.
6. Explicitly identify what **cannot** be verified until tested on physical iPad hardware.
7. Produce a review report (see Section 11). **Documentation/review only** unless separately asked to implement.

## 1. Locked product requirements

### 1.1 Experience

- Native **iPadOS** app; **landscape-only** designed for iPad-class aspect ratios, not a resized 16:9 desktop wallpaper.
- True **2D pixel-art sprites**, consistent pixel grid/scale, silhouettes and room perspective. No 3D, semi-3D renderer, rasterized illustrations posing as reusable sprite animation, or continuous physics simulation.
- One cozy cyberpunk study room in the MVP, with a boy/girl studying at a desk. The room fills the screen and remains calm even without input.
- HUD is largely hidden: optional now-playing/music panel, compact weather/clock display as needed, a dismissible customization panel. The **clock itself is an in-world sprite object**.
- Atmospheric and low-demand first: mostly static background, modest independently scheduled ambient animation and contextual interactions.
- No coins, achievements, XP, upgrades, tasks, inventory, quests, character AI, emergent agent simulation or monetization.

### 1.2 Swappable visuals and assets

| Content | Locked MVP | Deferred (not MVP) |
| --- | --- | --- |
| Room | 1 consistent room layout, fixed furniture positions | More room layouts, furniture drag-and-drop |
| Main character | 2 variants: boy and girl | Hair/outfit/body sliders |
| Character behavior | Study/typing, rest/look away, drink, stretch | Walking freely, pathfinding, complex activities |
| Pets | Orange cat and black cat | Dogs, many breeds, pet inventory |
| Pet behavior | Sleep/idle, small movement, tap reaction | Following character, pathfinding, physics |
| Window scenery | 2 swappable cyberpunk city backgrounds | Rooftop gardens, natural landscapes, multiple regions |
| Weather visuals | Clear and rain | Snow, thunderstorm-specific effects, seasons |
| Time visuals | Day and night, automatically or manually chosen | Continuous cinematic sunrise/sunset palettes |
| Room lighting | Tap on/off desk lamp | Color grading studio or detailed fixtures |
| Presets | One auto-saved active configuration | Multiple named room presets |
| Scenery animation | Optional sparse effects and future-ready attachment points | Rich traffic system, dynamic crowds, many trains |

**Important:** The game does not need to own or edit pixels of the underlying background dynamically. Different scenery packs can carry static layers plus optional animated parts that operate independently.

### 1.3 Small interactions

- Tap **pet**: short reaction, then return to its previous state.
- Tap **desk lamp**: toggle light appearance.
- Tap **computer/music object**: toggle the Spotify now-playing overlay.
- Tap **window**: provide an unobtrusive way to select the available scenery/environment options (direct cycle or small contextual menu, art/UX to decide).
- Open **customization**: swap character, pet, scenery and environment behavior. The panel is dismissed back to uninterrupted room view.
- No constant popups, tooltips or intrusive overlays during passive viewing.

### 1.4 Real-world time and weather (hybrid mode)

- Time of day and weather are **independent** settings, each with **automatic** and **manual** modes.
- Automatic time follows local clock; manual time selects Day or Night independently of real clock.
- Automatic weather uses a supported weather provider; manual weather selects Clear or Rain irrespective of actual conditions.
- If automatic weather cannot fetch, use last known value if appropriate or a predictable default; do not blank the scene or block startup.
- User-selected manual overrides persist across app restarts; no automatic reset to current real conditions.
- Weather refreshes periodically (initial proposal: every ~30 minutes while relevant/foreground), NOT on every animation frame.
- User must have a way to choose a weather location without forcing precise location permission; prefer city/manual choice or opt-in approximate location. Report privacy/performance implications.

### 1.5 Integrated pixel-sprite real-time clock — explicitly MVP

- Clock is a **diegetic object**: a digital clock on the desk or wall, visible inside the room artwork.
- Render `HH:mm` in **24-hour format**, with no seconds for MVP.
- A shared sprite atlas contains glyphs `0` through `9` plus a colon (or equivalent transparent monochrome pixel glyph textures). Four digit instances and one separator are positioned within a clock bezel/skin.
- Use the iPad local time. Recalculate on **minute boundary**, app foreground/resume and relevant system time/time-zone change notifications. Update only changed digit sprites; **no per-frame polling**.
- Clock time stays real even when **manual day/night atmosphere** is selected. Manual night lighting must **not** turn the actual displayed time into a fake time.
- Clock component has a dedicated layout anchor and independent skin/colors for future packs, but MVP can ship one skin.

### 1.6 Spotify now-playing (optional connection, MVP feature)

- In-world computer or similar object opens/closes a small music overlay.
- If user connects Spotify and playback is available, show track title, artist, artwork/placeholder, play/pause and next/previous. Basic playback progress is optional if costly or unavailable; do not animate a per-second HUD when overlay is closed.
- The app does **not** stream, decode or store Spotify music itself. Use an appropriate official Spotify iOS integration / App Remote path; the Spotify app handles playback.
- Must handle not-installed, not-signed-in, not-playing, permission denied, expired authorization, disconnected, offline and app-switch-required states gracefully.
- Room animation is **not audio-beat synchronized**. Never build an audio-reactive music visualizer or artwork/video sync using Spotify sound recordings without verifying policy rights.
- Spotify is not required to use the rest of the room.
- Validate Spotify Developer rules and authorization constraints before implementation; personal-use Development Mode limits may apply (as of 2026, Premium app owner, five authorized users and restricted endpoints). Source links in Section 10.

### 1.7 Power and runtime

- Foreground visual app meant to remain open for hours, not a system-level screensaver.
- Prioritize idle energy efficiency (CPU/GPU/network *and display*). Animations must not create an always-busy game simulation.
- The suggested baseline is **30 FPS Balanced** with an optional **15 FPS Eco** target, subject to `SKView`/iPad testing. These are engineering hypotheses, NOT measured energy savings or mandatory exact frame timings.
- One scene uses static art where possible, texture atlases, localized animation state and a small number of SpriteKit nodes.
- Avoid per-frame work for service logic, redundant timers, unnecessarily frequent network requests, large emitter/particle counts or physics bodies.
- On losing foreground: pause/stop nonessential scene activity and disconnect/reconnect services as appropriate; on re-entry refresh current time and stale weather state.
- User-configurable **Keep Screen Awake** option, clearly labeled as affecting battery life. Do not change device brightness without explicit user control; optionally offer an in-app visual dim effect (future/polish, not a new gameplay system).
- Acceptance requires measurements on an actual iPad at controlled brightness. Do not claim a battery-percent-per-hour target before profiling.

## 2. Visual direction / scene composition

### 2.1 Visual identity

- Cozy, melancholic **lo-fi cyberpunk**, not a neon-dense combat game.
- Readable authentic pixel grid, limited palette within each environment, warm desk-lamp amber against cool cyan/purple outdoor light.
- Side-facing or gentle 3/4 side perspective for desk/character; **consistent** camera across all replaceable sprite packs.
- Main focus = boy/girl seated at desk; secondary focus = generous window scenery; tertiary = cat, clock, computer, plants and sparse decor.
- Quiet room first; the window serves as a showcase for alternate backgrounds and future animated layers.
- Avoid complex HUD, meters or mobile-game panels. The scene should remain beautiful with every overlay dismissed.

### 2.2 Logical layer hierarchy (not six guaranteed full-screen GPU passes)

1. Far scenery: skyline/city background with optional moving objects.
2. Window atmosphere: rain/clear overlay, clouds/lightning **only if packed** (MVP rain/clear).
3. Fixed room: walls, furniture, desk, lamp, screens and decorations.
4. Actors: user-selected character and pet, with stable anchors.
5. Foreground accents: limited steam/glow/reflections as needed.
6. In-world objects and hit targets: clock sprites, lamp, music hotspot; presentation UI through SwiftUI overlays above scene.

Key requirement: a new background can be added as an **asset pack**, without rewriting character/clock/room logic.

### 2.3 iPad framing

- Design for iPad landscape aspect ratios (e.g. approximately **4:3** and other iPad proportions); **not exclusively 16:9**.
- Define a central safe scene and flexible margins: character, desk clock, pet and interactive targets stay visible across supported aspect ratios.
- Choose a logical pixel canvas, integer/nearest-neighbor scaling policy and art-export sizes during M0; don't lock arbitrary values without a device screenshot test.
- All visuals should be crisp sprites on actual iPad panels, with no bilinear blur, sprite seam artifacts or non-pixel-art glows/shaders over the primary artwork.

## 3. Architecture (proposed, subject to agent validation)

**Recommended stack:** `SwiftUI` app shell + `SpriteKit` pixel scene; `async/await` services as needed; local storage for preferences and Keychain for auth tokens when applicable. No server required for MVP.

```text
LoFiRoomApp (iPadOS / SwiftUI)
 |
 +-- Presentation /
 |    +-- SceneContainer  (SpriteKit host)
 |    +-- CustomizationSheet
 |    +-- MusicNowPlayingPanel
 |    +-- MinimalSettings
 |
 +-- Application /
 |    +-- RoomStateStore          (single source of normalized scene state)
 |    +-- SceneCoordinator       (translate state/events into scene updates)
 |    +-- RoutineScheduler       (sparse weighted actions, cooldowns)
 |    +-- EnvironmentController  (auto/manual time & weather)
 |    +-- PowerPolicy            (idle/Eco/foreground handling)
 |    +-- RoomPresetStore        (local configuration)
 |
 +-- Domain /
 |    +-- ActorDefinition & AnimationCatalog
 |    +-- ScenePack & AnchorManifest
 |    +-- ClockComponent & ClockSkin
 |    +-- EnvironmentState & MusicState
 |
 +-- Infrastructure /
 |    +-- SpriteAssetRepository  (atlases, load/swap/unload)
 |    +-- DeviceClockProvider
 |    +-- WeatherProvider        (Open-Meteo adapter)
 |    +-- SpotifyRemoteAdapter   (iOS SDK/App Remote)
 |    +-- SettingsPersistence
 |
 +-- Rendering /
      +-- LoFiSKScene
      +-- StaticRoomNode
      +-- SceneryNode
      +-- CharacterNode / PetNode
      +-- PixelClockNode
      +-- AmbientEffectNodes
```

**Dependency direction:** infrastructure adapters provide data to application-domain interfaces -> scene state changes -> rendering. `LoFiSKScene` must **not** call Spotify or HTTP APIs directly. SwiftUI owns overlays and handles accessibility/text. Rendering should work offline with mock implementations.

### 3.1 State and data flow

```text
Local user action ───────────────────┐
Local clock minute ──────────────────┤
Weather cache/network (sparse) ──────┼──> RoomStateStore / SceneCoordinator
Spotify subscribed player state ─────┤        |
Routine scheduled action ────────────┘        +--> SpriteKit node/texture changes
                                              +--> SwiftUI conditional HUD update
                                              +--> Persist selected preferences
```

No global frame-dependent game logic is required. SpriteKit update/rendering is still frame based for active animations; the **business logic** should be event/schedule driven.

## 4. Asset pack contract (proposal for validation)

Every variant should declare: identifier, category, art-pixel density/version, anchor coordinates within the logical scene, sprite sheet/atlas references, animations with frames and durations, and fallback behavior.

```text
Assets/
  Scenes/StudyRoom01/{room_static,anchors,manifest}
  Characters/Boy01/{atlas,manifest}
  Characters/Girl01/{atlas,manifest}
  Pets/OrangeCat/{atlas,manifest}
  Pets/BlackCat/{atlas,manifest}
  Scenery/NeonCity01/{base,optional_effects,manifest}
  Scenery/NeonCity02/{base,optional_effects,manifest}
  Effects/{rain,clear,desk_light}
  Clocks/RetroDigital01/{bezel,digits_atlas,manifest}
```

Example conceptual manifest (exact file schema to be reviewed, not a code mandate):

```json
{
  "id": "boy01",
  "type": "character",
  "packVersion": 1,
  "perspective": "study-room-side-3q-v1",
  "anchor": "desk-seat",
  "atlas": "boy01.atlas",
  "animations": {
    "study": {"frames": ["study_0", "study_1"], "fps": 2},
    "drink": {"frames": ["drink_0", "drink_1", "drink_2"], "fps": 3},
    "stretch": {"frames": ["stretch_0", "stretch_1"], "fps": 2},
    "rest": {"frames": ["rest_0"], "fps": 1}
  },
  "fallbackAnimation": "study"
}
```

Requirements:
- All character variants align to the same chair/desk anchor; animation frames must preserve seated registration.
- Pet variants align to the same pet cushion/floor anchor; use same abstract states (`sleep`, `react`) even if counts/durations differ.
- Scenery packs share the same **window frame/mask** and visual depth, so no new room layout is necessary.
- Clock uses a shared `0...9` + `:` atlas; digit-slot coordinates and colors belong to its clock skin, not to every clock update.
- Only active variants/effects should retain textures in memory; preloading a pending alternate pack is optional and must be measured.
- Missing optional animations must fall back gracefully; missing required textures must fail validation with actionable errors.
- Art provenance/license must be recorded for each delivered pack. Concept images are not usable sprite sheets without production conversion.

## 5. Routine scheduler behavior

- Predefined, infrequent **natural routines**, not autonomous agents or per-frame random action decisions.
- Default steady state is study/typing. Secondary actions: drink, stretch, short rest/look away.
- Scheduler uses configurable minimum/maximum delays, weights and cooldowns, **but does not commit to particular intervals before animation pacing review**.
- Triggered interactions can preempt a routine at an animation-safe boundary. Do not interrupt midway and leave held props floating.
- Pet scheduler is independent and simpler (`sleep`, occasional idle, tap reaction); actor selection does not require new scene or schedule code.
- Never run routine scheduling off-screen or during paused/inactive scene states.
- Optional background pack animation events (e.g. passing train) are separate from actor scheduler and not required for first MVP art.

## 6. Clock technical details

```text
DeviceClockProvider.now() -> wall-clock Date
    -> TimeFormatter.format24h() -> "23:47"
    -> PixelClockNode.setGlyphs(['2','3',':','4','7'])
    -> update slots whose glyph identity changed
    -> schedule next minute boundary with lifecycle/time-change correction
```

- Use locale-aware calendar/timezone for sourcing local wall time, while maintaining fixed `HH:mm` display output.
- Handle midnight, 09:59 -> 10:00, time-zone changes, DST where relevant, system clock adjustments, scene resume and accessibility.
- Clock bezel is static. Colon **does not blink** by default (unnecessary refresh, potentially distracting).
- Clock remains functional offline and without Spotify/weather permissions.

## 7. Environment states and mapping

Suggested normalized state shape:

```text
TimeSetting    = Automatic | Manual(Day | Night)
WeatherSetting = Automatic(location) | Manual(Clear | Rain)
ResolvedScene  = {time: Day|Night, weather: Clear|Rain, lampOn: Bool}
```

- `Automatic` weather maps real conditions into limited visual classes; map snow/cloudy/etc to **a documented fallback** (e.g. Clear or Rain based on precipitation) until those art packs exist.
- Changes use cheap texture/tint/overlay swaps, not reload-the-whole-room.
- Reuse weather data; do not request coordinates continuously or poll with high frequency.
- Annotate automatic weather as stale/unknown in settings when necessary; don't imply it is current when cached for a long time.
- User's chosen location and permission are separate from visual manual weather.

## 8. Power & quality review gates

### 8.1 Mandatory profiling scenarios

Run at a controlled brightness, with identical setup and device thermal conditions:

1. Static background, no overlays, no animations.
2. Room with character + cat idle loops.
3. Room with rain/lighting enabled.
4. Same with Spotify connected/playing (record Spotify's contribution separately where feasible).
5. Same with automatic weather enabled, plus foreground/background transitions.
6. 30 FPS Balanced vs 15 FPS Eco, if device/runtime supports intended rates.
7. Multi-hour continuous run and scene-pack swaps for memory leaks.

Record: app CPU utilization, GPU/render performance, wakeups/network activity, FPS/frame pacing, peak/steady memory, thermals and system energy metrics (Instruments), device/display brightness, test duration and battery trends. No unjustified percentage goals.

### 8.2 Explicit conditions for acceptance

- No app-side busy loop for the clock, routine scheduler, Spotify metadata, or weather.
- App remains useful offline; automatic weather and Spotify fail gracefully.
- No continuous per-frame texture recreation or unnecessary full-scene reinitialization when changing variants.
- App pauses/resumes correctly, does not display stale clock after foregrounding, and does not accumulate nodes/timers/listeners on repeated swaps.
- No unexpected loss of the visual room when external network is absent.
- All animation states terminate or loop as intended; scene stays stable for a multi-hour test.

## 9. Milestone plan (locked content, implementation may be reordered on review)

### M0 — Visual + energy proof of concept

- Render one fixed landscape room and one boy in true 2D pixel art.
- Implement a minimal steady study animation; static city, single cat/placeholder if useful.
- Verify logical resolution, sharpness, anchors and layout on physical iPad.
- Run first static-vs-animated energy baseline.
- **Gate:** art looks consistent, correct on iPad, and rendering approach is feasible.

### M1 — Modular scene packs + real clock

- Implement scene/state-independent swap of boy/girl; orange/black cat; two city backdrops.
- Shared asset manifest contract, anchor rules, fallback animation convention.
- Render *real* clock via digit atlas (0-9 and colon), scheduled minute updates.
- Save and restore one active configuration.
- **Gate:** no code changes needed to replace compatible sprite packs, no character misalignment, clock survives suspend/time-zone changes.

### M2 — Routine scheduler + small interactions

- Implement study, drink, stretch, rest; pet idle/sleep/tap; lamp, window, computer hotspots.
- Avoid unnecessary repeated timers and business logic per frame.
- Add unobtrusive customization panel.
- **Gate:** interactions interrupt safely, no stuck states, correct preset persistence.

### M3 — Hybrid environment + Spotify

- Automatic/manual time and weather, location choice, cache/fallback and manual persistence.
- Official Spotify remote authorization, player-state subscription and tiny now-playing controls.
- Ensure the room remains fully functional disconnected/offline.
- **Gate:** no unwanted weather override, no dependency of room rendering on external services, graceful Spotify app-switch/deauth states.

### M4 — Power pass + UX polish

- Tune 30 FPS and optional 15 FPS Eco, only if measured effective.
- Optimize active textures, reduce rain workload, remove leaks/wakeups; implement Keep Screen Awake option.
- Long-duration performance test, store readiness/credits review, accessibility of small hotspots.
- **Gate:** stable multi-hour iPad run, documented profiling, no accumulating resource use.

## 10. External technical reference points — to verify during agent review

These links are background references, not a claim that all constraints have been proven on the target device.

- Apple SpriteKit `SKView` performance-related controls: https://developer.apple.com/documentation/spritekit/skview
- Spotify iOS SDK overview: https://developer.spotify.com/documentation/ios
- Spotify iOS SDK getting started, player state and app-switch flow: https://developer.spotify.com/documentation/ios/getting-started
- Spotify App Remote application lifecycle: https://developer.spotify.com/documentation/ios/concepts/application-lifecycle
- Spotify Development Mode Feb 2026 changes: https://developer.spotify.com/blog/2026-02-06-update-on-developer-access-and-platform-security
- Spotify Development Mode quota/eligibility: https://developer.spotify.com/documentation/web-api/concepts/quota-modes
- Open-Meteo non-commercial usage and attribution: https://open-meteo.com/

**Spotify caveat:** Official docs describe Spotify running as a separate app and playback authorization possibly requiring app-switch, with on-demand availability and developer access tied to account eligibility. The reviewer should determine the exact viable interaction, failure states and login experience. Do not promise completely silent connection or unrestricted commercial use.

**Weather caveat:** Open-Meteo publicly offers non-commercial weather APIs with attribution requirements. Keep source and licensing visible in Settings/About and re-evaluate if product distribution changes.

## 11. Required reviewer deliverables

Create **`MVP_REVIEW_REPORT.md`** containing:

1. **Executive verdict:** Ready / Ready with blockers / Needs redesign, with rationale.
2. **Requirements traceability table:** every locked feature mapped to proposed module, assets and tests.
3. **Feasibility review:** SwiftUI + SpriteKit, iPad orientation and screen framing, sprite atlas/asset-packs, clock minute-boundary scheduling, actor interruptions, Spotify App Remote, Open-Meteo and local persistence.
4. **Power review:** likely major energy costs (display, scene effects, Spotify app, wakeups), proposed measurement protocol, avoid claims without a device run.
5. **Visual/asset-production review:** minimum art deliverables/frame list, source pixel dimensions strategy, shared anchors, animation and transitions.
6. **Risks and decisions:** severity, evidence, mitigation, impact if an API/policy constraint prevents an expected behavior.
7. **Scope creep audit:** list proposed features that should remain post-MVP.
8. **Suggested implementation order/checkpoints**, only if it improves on M0–M4 while retaining scope.
9. **Open questions:** only questions that truly block implementation or art production; propose sensible defaults.
10. **No code changes, PRs or new features** unless the user explicitly requests implementation after review.

## 12. Acceptance checklist (product-level)

- [ ] Native foreground landscape iPad app; coherent composition across targeted iPad sizes.
- [ ] Authentic 2D sprite assets, one shared room perspective and consistent scale.
- [ ] Boy/girl selection; orange/black cat selection; two swappable city views.
- [ ] Scheduled study, drink, stretch, rest; pet sleep and tap reaction.
- [ ] Tap lamp, pet, computer/music, window; hidden-by-default customization/music UI.
- [ ] Manual/automatic time and weather controlled **independently**, with persistence.
- [ ] Real `HH:mm` 24-hour in-world clock using reusable digit textures and no seconds.
- [ ] Spotify optional connection with now-playing and basic playback controls; good disconnected handling.
- [ ] Weather no-key or appropriately authenticated supported provider, respectful cache, attribution and graceful offline behavior.
- [ ] One saved room state, restored on launch.
- [ ] Balanced performance; optional Eco; pause/resume; no per-frame network/business logic.
- [ ] Profiling on real iPad, documented power and memory results.
- [ ] No game mechanics, backend dependency, asset inconsistency, mandatory login or intrusive HUD.

---

**Change control:** This document is **MVP scope frozen** as of 2026-11-14. Agents may correct implementation assumptions and report blockers, but any functional addition/removal must be presented as a suggested change for explicit approval. Future mockup explorations are exploratory **art direction** and should not implicitly modify this locked scope.
