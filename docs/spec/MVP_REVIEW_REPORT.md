# Lo-Fi Room — MVP Review Report

**Reviews:** `LOCKED_MVP_SPEC.md` v1.0 (2026-11-14) and `DESIGN_EXPLORATION_BRIEF.md`
**Review date:** 2026-11-14
**Scope of this report:** Documentation/review only. No code, no scope changes. Anything functional is marked **Suggested change (needs approval)**.

---

## 1. Executive verdict

**Ready with blockers.**

The spec is well disciplined. Scope is tight. Business logic is event-driven, not per-frame. Energy figures are framed as hypotheses. The asset-pack contract is the right level of abstraction. Most of the architecture can go ahead unchanged.

Three external constraints have to be settled before M0/M3 because they change requirements, not just implementation:

| # | Blocker | Affects | Short resolution |
|---|---|---|---|
| B1 | iPadOS 26 deprecates `UIRequiresFullScreen`. Apps are expected to handle resizable windows, so "landscape-only, fixed aspect" can't be guaranteed | §1.1, §2.3, M0 | Support resizable scenes with a letterbox/frame policy and a minimum scene size. Request orientation lock via `prefersInterfaceOrientationLocked` |
| B2 | Spotify App Remote can't reliably resume playback in-app after a pause. Spotify's docs say an app switch is required | §1.6, §12, M3 | Redefine the music controls as tiered states (§6, R2) and accept app-switch resume as documented behavior |
| B3 | Spotify Development Mode limits the app to personal use: Premium owner, max 5 authorized users. Extended quota is organization-only | §1.6, distribution | State explicitly that the MVP is personal/small-circle. Open-Meteo's non-commercial license points the same way |

There are also several internal gaps (frame-rate policy, day/night art method, lamp-light technique, automatic day/night definition, system power signals, hit-target accessibility). These are decisions to record, not redesigns. See §6.

---

## 2. Requirements traceability

| Locked requirement (spec §) | Module(s) | Assets | Verification |
|---|---|---|---|
| Native iPadOS, landscape (1.1, 2.3) | `SceneContainer`, `LoFiSKScene` scale policy | Room canvas with safe-area + bleed margins | Device screenshot matrix: full screen 4:3 and other iPad ratios, Stage Manager/windowed sizes, min size (see B1) |
| True 2D pixel art, consistent grid (1.1, 2.1) | `SpriteAssetRepository` (nearest filtering), scale policy | All packs on one logical grid | Visual inspection on device at 100%; automated check that every texture has `filteringMode = .nearest` |
| One room, fixed furniture (1.2) | `StaticRoomNode`, `ScenePack`/`AnchorManifest` | `Scenes/StudyRoom01` | Anchor overlay debug mode |
| Boy/girl variants (1.2) | `ActorDefinition`, `CharacterNode`, `RoomStateStore` | `Characters/Boy01`, `Girl01` | Swap test: registration on `desk-seat`, no node leak after 100 swaps |
| Study/rest/drink/stretch (1.2, 5) | `RoutineScheduler`, `AnimationCatalog` | Per-character animation sets | Scheduler unit tests (weights, cooldowns, safe boundaries); multi-hour soak with no stuck state |
| Orange/black cat (1.2) | `PetNode`, pet scheduler | `Pets/OrangeCat`, `BlackCat` | Swap test on pet anchor; tap reaction returns to prior state |
| 2 city sceneries (1.2) | `SceneryNode`, window mask | `Scenery/NeonCity01`, `02` | Swap with no room reload; memory returns to baseline after swap |
| Clear/Rain (1.2, 1.4) | `EnvironmentController`, rain effect node | `Effects/rain` | Manual override persists across relaunch; auto mapping table tests |
| Day/Night (1.2, 1.4) | `EnvironmentController`, `ResolvedScene` | Day/night scenery variants (see D2) | Auto vs manual independence tests |
| Lamp toggle (1.2, 1.3) | Hit-test layer, `RoomStateStore` | Lamp on/off + light-pool sprite (see D3) | Tap test; persists |
| One auto-saved config (1.2) | `RoomPresetStore`, `SettingsPersistence` | — | Kill/relaunch restores every field |
| Tap pet/lamp/computer/window (1.3) | Hit-test layer → `SceneCoordinator` | Enlarged invisible hit regions | Hit-target size audit; VoiceOver labels (see D7) |
| Customization panel (1.3) | `CustomizationSheet` (SwiftUI) | — | Dismiss returns to clean scene; no lingering overlay |
| Hybrid time/weather (1.4, 7) | `EnvironmentController`, `WeatherProvider` | — | State-machine tests; offline launch; stale-cache labeling |
| Weather location without precise permission (1.4) | Settings + Open-Meteo geocoding | — | Works with location permission denied |
| Diegetic 24h clock (1.5, 6) | `ClockComponent`, `PixelClockNode`, `DeviceClockProvider` | `Clocks/RetroDigital01` (0–9 + colon, bezel) | Tests for 09:59→10:00, 23:59→00:00, TZ change, clock change, DST, resume after suspend; manual Night doesn't change displayed time |
| Spotify now-playing (1.6) | `SpotifyRemoteAdapter`, `MusicState`, `MusicNowPlayingPanel` | Placeholder artwork | Failure-state matrix (§3.6); app-switch round trip on device |
| Power/runtime (1.7, 8) | `PowerPolicy` | Low frame counts | §4 protocol on physical iPad |
| Keep Screen Awake (1.7) | `PowerPolicy` → `isIdleTimerDisabled` | — | Toggle respected; off by default; label mentions battery |

---

## 3. Feasibility review

### 3.1 SwiftUI + SpriteKit
**Feasible.** Use `SpriteView` or a `UIViewRepresentable`-wrapped `SKView`. A wrapped `SKView` gives direct access to `preferredFramesPerSecond`, `isPaused` and `ignoresSiblingOrder`, which `PowerPolicy` needs. Recommendation: wrap `SKView`.

### 3.2 iPad orientation and framing — **Blocker B1**
iPadOS 26 deprecates `UIRequiresFullScreen`, and Apple strongly encourages apps to support dynamic resizing because the compatibility mode will be removed. Apple's migration note (TN3192) recommends `prefersInterfaceOrientationLocked` for temporary orientation lock. Developers also report iPadOS 26.x displaying landscape-only apps in portrait when device orientation lock is off.

**Effect on spec:**
- §1.1 "landscape-only" stays as a *design intent*. It can't be guaranteed as a *runtime guarantee*.
- §2.3 integer scaling needs a policy for arbitrary window sizes:
  - Pick the largest integer scale that fits the **safe scene**.
  - Fill the remainder with bleed art (extended walls/sky) first, then a themed letterbox frame.
  - Set a minimum scene size (via `UIWindowScene` size restrictions) below which a letterboxed version is shown.
  - In a portrait-shaped window, show the safe scene letterboxed. Don't re-compose the room.
- M0 gate gains: "verify full screen, windowed and Stage Manager sizes on device".

### 3.3 Sprite atlases and asset packs
**Feasible.** Xcode `.spriteatlas` per pack, JSON manifest per pack, validated at load. Notes:
- Bundled packs only for MVP (no downloadable packs) keeps "no code changes to swap compatible packs" achievable with zero infrastructure.
- Add a **debug-build manifest validator** (missing frames, wrong anchor IDs, mismatched `perspective` tag, wrong pixel density). This is how the spec's "fail validation with actionable errors" requirement becomes testable.
- Set `filteringMode = .nearest` on every texture. Also snap node positions to whole logical pixels. Sub-pixel positions produce shimmer even with nearest filtering.

### 3.4 Clock minute-boundary scheduling
**Feasible, low risk.** Schedule a one-shot timer for the next minute boundary, plus a small tolerance, and recompute on fire. Also recompute on:
- `UIApplication.significantTimeChangeNotification`
- `NSSystemTimeZoneDidChange`
- `NSSystemClockDidChange`
- Scene foreground (`scenePhase == .active`)

Don't rely on the timer firing exactly on time after suspend. Always recompute from `Date()` on resume. Diff glyph identities and only swap changed textures.

Gap: digits must be **emissive** (self-lit colors) so they stay readable at Night with the lamp off (see D4).

### 3.5 Actor interruptions
**Feasible.** Model each animation as segments with marked **safe exit points** (e.g. mug back on desk). A tap or customization swap requests preemption, and the actor exits at the next safe point. Character swaps happen at a safe point or behind a 2–4 frame crossfade/blink. Add this to the manifest schema: `"safeExits": [frameIndex...]`.

### 3.6 Spotify App Remote — **Blockers B2, B3**

**What works**
- App Remote controls the Spotify app on the same device. Playback is offloaded to Spotify.
- While playing: pause, next, previous and player-state subscription all work in-app.

**What doesn't work reliably**
- Spotify's lifecycle guide states an app switch is currently required to resume playback after the user pauses. It recommends a "Resume Playback"/"Open Spotify" button when App Remote is not connected.
- Developers report a ~30 s grace period after pausing. After that, Spotify ends the connection. Disconnects are reported even while the client app is fully foregrounded ("The Spotify app might have been suspended").
- Reconnecting after that requires `authorizeAndPlayURI`, i.e. another app switch.
- Initial authorization also involves an app switch.

**Web API alternative**
- `PUT /me/player/play` resumes on the user's *active device*. It requires Premium.
- A suspended Spotify app on the iPad is unlikely to count as an available device. A community report describes an iPad going "Unavailable for listening on" after pausing while locked. This is **unverified for our case**.
- It's viable when playback is on *another* device (Mac, speaker). The costs:
  - a second OAuth (PKCE) flow
  - refresh tokens that expire six months after authorization
  - no push events, so polling, which should run only while the overlay is open

**Recommended requirement rewrite (Suggested change — needs approval).** Replace "play/pause and next/previous" with tiered states:

| State | Overlay shows | Controls |
|---|---|---|
| Not connected / never authorized | "Connect Spotify" | Starts auth (app switch) |
| Connected, playing | Title, artist, art | Pause, next, previous (in-app) |
| Connected, paused (grace window) | Same | Resume (in-app) |
| Disconnected (grace expired, suspended) | Last known track, dimmed | **"Resume in Spotify"** (app switch, reconnect on return) |
| Spotify not installed | "Spotify not installed" | App Store link (`SKStoreProductViewController`) |
| Auth expired / denied | "Reconnect Spotify" | Re-auth |
| Offline | Last known track, "offline" | Disabled controls |

Lifecycle rules:
- Disconnect App Remote when Lo-Fi Room backgrounds, and reconnect on foreground. Spotify's own guidance is not to hold the connection in the background.
- Never auto-trigger an app switch. Only switch on an explicit user tap.

**B3 — Development Mode.**
- Since Feb 2026, Development Mode requires the app owner to have Premium, allows one Client ID (later raised to 25 per account, sharing one quota), and caps each Client ID at five authorized users.
- If the owner's Premium lapses, the app stops working.
- The spec's §1.6 note is accurate. Add a product statement: *"Spotify integration is personal-use only; distribution beyond 5 users requires removing or replacing it."*

### 3.7 Open-Meteo
**Feasible.**
- No API key is needed.
- The forecast endpoint returns `weather_code`, `precipitation`, `is_day`, `sunrise`/`sunset`.
- The geocoding endpoint supports city search, which satisfies "no precise location permission".

Notes:
- Non-commercial license with attribution. Show it in Settings/About.
- If distribution changes, re-evaluate. Apple's WeatherKit is the obvious alternative inside an Apple Developer membership. Check current quotas before switching.

### 3.8 Local persistence
**Feasible.**
- Settings (selected variants, manual overrides, location name and coordinates, Keep Awake, frame-rate mode): one versioned `Codable` struct in `UserDefaults` or a small JSON file.
- Spotify tokens: Keychain.
- Add `schemaVersion` now so later presets can migrate.

---

## 4. Power review

### 4.1 Likely major costs (ranked, unmeasured)
1. **Display.** Almost certainly dominant for an hours-long foreground app. Brightness and Keep Screen Awake matter more than any code optimization.
2. **Spotify app playback.** Audio decode and network run in Spotify's process. Measure it separately as system-level energy.
3. **Render cadence.** SpriteKit redraws every frame while unpaused, even if nothing changed.
4. **Rain effect.** The only effect that needs a higher frame rate.
5. **Wakeups/network.** Small if the design holds (minute timer, ~30 min weather).

### 4.2 Frame-rate policy — Suggested decision D1
The manifest example animates at **1–3 fps**. At "30 FPS Balanced" SpriteKit redraws identical frames ~10–30 times. Proposal: derive `preferredFramesPerSecond` from the **fastest active animation**:

| Scene state | Target |
|---|---|
| Idle (character/cat loops only) | ~6 fps (or lowest stable value that keeps 2–3 fps loops even) |
| Rain on | ~12 fps; hand-animate rain as an 8–12 fps sprite loop (authentic lo-fi look) |
| Transition (swap/crossfade) | Temporary 30 fps, then drop back |
| Customization sheet open | Scene may pause entirely |

Choose rates that divide the panel refresh evenly. The M1 iPad Pro is a 120 Hz ProMotion panel, so values like 6/12/15/30 work. Whether lower requested rates save display power on ProMotion **can't be confirmed without device measurement**.

### 4.3 System signals (Suggested addition to PowerPolicy — policy, not a feature)
- `ProcessInfo.isLowPowerModeEnabled` → force Eco.
- `ProcessInfo.thermalState` ≥ `.serious` → Eco, pause optional effects.
- `UIAccessibility.isReduceMotionEnabled` → calmer rain (fewer drops/slower), no flicker effects.

### 4.4 Measurement protocol additions
Keep spec §8.1, plus:
- Fix brightness with auto-brightness and True Tone off. Record the nits setting.
- 30-minute steady-state per scenario after a 10-minute warm-up. Start each from the same battery and thermal state.
- Instruments: Energy Log (via device), Time Profiler, Allocations/Leaks, Metal System Trace for frame pacing.
- Run scenario 2 at 30 / 12 / 6 fps to test D1 directly.
- Record Spotify separately: scenario 4 vs scenario 4 with Spotify playing but Lo-Fi Room backgrounded.

---

## 5. Visual / asset-production review

### 5.1 Minimum art deliverables (MVP)

| Pack | Required items | Indicative frames |
|---|---|---|
| StudyRoom01 | Static room (split into a few large layers: back wall/window frame, furniture, foreground), window mask, bleed extensions, anchor map | Static |
| Lamp | Off sprite, on sprite, dithered light-pool sprite (night) | 1 each (optional 2-frame flicker) |
| Boy01 / Girl01 | study (loop), rest/look-away, drink (in-hold-out), stretch | study 2–4, rest 1–2, drink 4–6, stretch 3–5 |
| OrangeCat / BlackCat | sleep (breathing loop), idle (ear/tail), react (tap) | sleep 2–3, idle 2–4, react 3–4 |
| NeonCity01 / 02 | Day base, night base (see D2) | Static (+ optional effects later) |
| Rain | Window-rain loop (inside window mask), optional glass streaks | 6–8 |
| Clock | Bezel, glyphs 0–9 and colon (emissive palette) | Static |
| Computer/music | Idle screen; optional "music on" screen variant | 1–2 |

Variant-matched requirements:
- Boy and girl must share the same seated silhouette footprint (chair occlusion, desk overlap).
- Both cats must fit the same cushion footprint.

### 5.2 Source pixel dimensions — to fix in M0
- Choose one logical canvas and integer-scale it. Example to test: a canvas ~480–640 px wide.
  - On a 2388×1668 (11") panel that gives a 4× or 5× integer scale with bleed margins.
  - Don't lock this before the device screenshot test (§2.3 of the spec is right).
- Author everything at 1× logical pixels. Never pre-scale exports.
- Define a **safe scene rectangle** (desk, character, clock, cat, lamp, computer, window). Paint bleed beyond it for wider/taller windows.

### 5.3 Anchors
Required anchor IDs in `AnchorManifest`: `desk-seat`, `pet-spot`, `clock-slot`, `lamp`, `computer`, `window-rect`, `window-mask`. Every pack references anchors by ID only and never by absolute coordinates.

### 5.4 Open art decisions
- **D2 Day/night method.** Tinting with blend factors breaks limited palettes. Recommendation:
  - Bake separate day/night art for scenery (2 cities × 2 = 4 backgrounds).
  - For the room, use a pre-drawn night overlay (dithered shadow layer) plus the lamp light-pool sprite.
  - Avoid `colorBlendFactor` on primary art.
- **D3 Lamp light vs. "no non-pixel-art glows" (§2.3).** The light must be a hand-drawn dithered sprite, not a shader or blur. Record this explicitly.
- **D4 Clock legibility.** Glyph palette must read at Night/lamp-off and in Day at low brightness. Test at 25% brightness.

---

## 6. Risks and decisions

| ID | Risk | Severity | Evidence | Mitigation | Impact on acceptance |
|---|---|---|---|---|---|
| R1 | Window resizing/orientation can't be fully locked (B1) | **High** | Apple TN3192; dev forums on `UIRequiresFullScreen` deprecation and portrait regression | Resizable-scene scale policy, min size, orientation lock request | §12 item 1 reworded: "coherent composition in full screen; graceful letterbox in other window sizes" |
| R2 | In-app resume after pause not reliable (B2) | **High** | Spotify lifecycle guide; community reports of ~30 s grace and foreground disconnects | Tiered control states (§3.6) | §12 Spotify item: "basic controls while connected; explicit app-switch resume when disconnected" |
| R3 | Spotify limited to ≤5 users, Premium-owner dependency (B3) | **High** (for distribution) / Low (personal) | Spotify Feb 2026 announcement and migration guide | Declare personal-use; keep Spotify optional and isolated behind adapter | None for personal MVP |
| R4 | Spotify connection flakiness (reconnect errors, stale state) | Medium | Long-standing SDK issue reports | Treat every state as recoverable; never block scene on Spotify | Covered by failure matrix |
| R5 | Open-Meteo non-commercial terms | Medium (if distributed) | open-meteo.com terms | Attribution in About; WeatherKit as fallback adapter | None for personal MVP |
| R6 | Frame-rate savings unproven on ProMotion | Medium | Not verifiable without device | D1 measured in M0 | M4 gate depends on data |
| R7 | Concept art mistaken for production sprites | Medium | Spec §4 already warns | Artist pass with frame list (§5.1) before M1 | Art schedule |
| R8 | Sub-pixel shimmer / seams | Low | Common SpriteKit pixel-art issue | Integer positions, nearest filtering, padded atlases | M0 gate |
| R9 | Tiny hit targets on pixel sprites | Medium | — | Invisible enlarged hit regions (≥44 pt); VoiceOver elements for hotspots | Move from M4 to M2 |
| R10 | Future OLED iPads + static clock for hours | Low (M1 iPad Pro is LCD/mini-LED) | — | Optional 1-px periodic scene drift later | None for MVP |

**Decisions to record**

| ID | Decision | Proposed default |
|---|---|---|
| D1 | Frame-rate policy | Activity-driven (§4.2) |
| D2 | Day/night method | Baked scenery variants + room night overlay |
| D3 | Lamp light technique | Dithered sprite |
| D4 | Clock palette | Emissive glyphs, tested at 25% brightness |
| D5 | Automatic day/night definition (spec leaves undefined) | Open-Meteo `sunrise`/`sunset` for chosen location; fallback 06:00–18:00 local |
| D6 | Weather mapping | `weather_code` precipitation classes (drizzle/rain/showers/thunderstorm/snow) → Rain; else Clear. Document the table |
| D7 | Accessibility timing | Hit regions + VoiceOver labels in M2 |
| D8 | Character swap transition | Safe-exit point + short blink/crossfade |

---

## 7. Scope-creep audit (keep post-MVP)

Fine to discuss later, none needed for the MVP:
- Web API Spotify control for other devices (Spotify Connect)
- Apple Music via MusicKit (no app-switch problem, no 5-user cap)
- Built-in ambient audio (rain/room tone tied to weather)
- Focus/countdown mode on the in-world clock
- App Intents / Focus filter integration
- External display / AirPlay room mode; tvOS port
- Seasonal decor packs; dog pets; more rooms; named presets
- Passing-train and traffic animation layers
- Snow/thunder visuals; continuous sunrise/sunset palettes
- In-app visual dim / night-stand mode; OLED pixel drift
- Downloadable asset packs

---

## 8. Suggested implementation order adjustments

M0–M4 stays. Small changes:
1. **M0** adds: resizable-window scale policy test (B1), frame-rate ladder measurement (D1), nearest-filter/integer-position check, day/night art method decision (D2).
2. **M1** adds: debug manifest validator; `safeExits` in schema.
3. **M2** adds: hit-region sizing and VoiceOver labels (moved from M4).
4. **M3** split into **M3a Environment** and **M3b Spotify**. Spotify carries the most external risk. Isolating it means a Spotify problem can't block the weather/time gate.
5. **Spike before M3b:** a 1-day throwaway App Remote probe on the target iPad to measure the real grace window, app-switch round trip and reconnect reliability. This is the only exception to "no code before review approval", so ask for approval explicitly.

---

## 9. Open questions (blocking only, with defaults)

| # | Question | Default if unanswered |
|---|---|---|
| Q1 | Accept tiered Spotify controls with app-switch resume (§3.6)? | Yes |
| Q2 | Confirm MVP is personal-use (≤5 users; non-commercial weather)? | Yes |
| Q3 | Behavior in non-landscape/small windows: letterbox safe scene, or allow re-composition? | Letterbox |
| Q4 | Automatic day/night: sunrise/sunset or fixed hours? | Sunrise/sunset with fixed fallback (D5) |
| Q5 | Day/night art: baked variants (more art) or overlays only (less art, palette risk)? | Baked scenery + room overlay (D2) |
| Q6 | Logical canvas size | Decided by M0 device test; start testing ~480–640 px wide |

---

## 10. Compliance with spec §0 / §11

- No code, PRs or new features produced.
- Locked requirements unchanged. All alterations marked *Suggested change*.
- **Not verifiable without physical iPad:**
  - energy/frame-rate savings
  - ProMotion behavior at low requested rates
  - real Spotify grace window and reconnect behavior on iPad
  - Web API device availability after suspend
  - pixel crispness at chosen scale
  - window-resizing behavior on the installed iPadOS version
  - multi-hour stability and thermals

---

## Sources

- Apple — TN3192: Migrating your iPad app from the deprecated UIRequiresFullScreen key: https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key
- Apple Developer Forums — UIRequiresFullScreen deprecation / orientation: https://developer.apple.com/forums/thread/810952
- Apple Developer Forums — iPadOS 26.x ignores supportedInterfaceOrientations: https://developer.apple.com/forums/thread/811216
- Spotify — iOS SDK Application Lifecycle (app switch required to resume): https://developer.spotify.com/documentation/ios/guides/application-lifecycle/
- Spotify Community — Remote SDK loses connection after paused ≥30 s: https://community.spotify.com/t5/Spotify-for-Developers/iOS-amp-Android-Remote-SDK-loses-connection-after-paused-for-30s/td-p/7077461
- Spotify Community — AppRemote disconnects after idle while foregrounded: https://community.spotify.com/t5/Spotify-for-Developers/SpotifyAppRemote-Disconnects-After-Idle-Despite-Valid-Access/td-p/6949155
- Spotify Community — Authentication iOS (reconnect via authorizeAndPlayURI): https://community.spotify.com/t5/Spotify-for-Developers/Authentication-iOS/td-p/5043919
- Spotify — Update on Developer Access and Platform Security (Feb 2026): https://developer.spotify.com/blog/2026-02-06-update-on-developer-access-and-platform-security
- Spotify — February 2026 Web API Dev Mode Migration Guide: https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide
- Spotify Web API — Start/Resume Playback: https://developer.spotify.com/web-api/console/put-play/
- Vorp Labs — Spotify API changes in 2026 (Client ID limit, refresh-token expiry): https://vorplabs.com/agent-tools/spotify-api-changes
- Spotify iOS SDK repository: https://github.com/spotify/ios-sdk
- Open-Meteo (terms, attribution): https://open-meteo.com/
