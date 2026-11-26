# Art set D — room exploration

**Status:** First pass runs on the iPad with `-artSet D` (2026-11-24). 133 tests pass. Not the default.
**Plan:** [`docs/plans/2026-11-17-art-set-d.md`](../plans/2026-11-17-art-set-d.md)
**Sources:** `ArtLab/type-d-capsule/raw/room-1.png` … `room-5.png`; prompts and job ids in `ArtLab/type-d-capsule/prompts.md`.

## Decisions so far (user, 2026-11-17)

- Direction: cozy cyberpunk lo-fi. The reference board is a guide, not a strict target, and it doesn't have to be violet.
- Character: generate the full seated body and cut it ourselves.
- **Room 3 chosen**, then **variant 3a** (2026-11-20). The user edits out the chair by hand instead of spending generations on more rooms.
- **Keep every generated room** (`room-1` … `room-5`, `room-3a/b/c`) in `raw/`; none are deleted.
- Names (2026-11-24): scene `CapsuleDesk01`, perspective `capsule-desk-side-v1`, packs `Capsule*`; sources in `ArtLab/type-d-capsule/`.

## Room options (5 generations, 2026-11-17)

Room 1 came from the first plan prompt. Rooms 2 and 4 follow the board; rooms 3 and 5 are the advisor's free designs. All are `create_image_pixen`, 480×352. Open the raw PNGs zoomed 3× to compare.

| Room | Design | Good | Problems (all fixable by hand, at no cost) |
|---|---|---|---|
| 1 | Violet board room | Strongest neon look, clean magenta glass | Blinds over the glass, nonsense text on the poster, chair faces right |
| 2 | Board-led | Chair faces left toward the desk, as on the board; warm and cozy | Not much cyberpunk; glass is dusty pink; curtain on one side |
| 3 | Advisor's design: high-rise capsule with a big window | Most cinematic; the large window gives the city room; paper lantern plus a teal neon tube | Moon and glare drawn on the glass; **chair is seen from behind, not from the side**, so the character would need a back view |
| 4 | Board-led, window as the main feature | Closest to the board's mood: dense desk, string lights, pink neon tube, chair facing left | Reflections on the glass and a sheer curtain over part of it; two desk lamps |
| 5 | Advisor's design: attic den | Most distinctive: round porthole window, shelves of old monitors, cassette deck, teal and orange | Small window, so little city shows; chair faces right; reads more retro than cyberpunk |

## What the prompts taught us

- Give the layout as a left-to-right order; "facing left" on its own is ignored.
- Say "bare glass, no blinds, no curtains, no reflections"; the model still adds glare or curtains about half the time.
- The window is keyed inside a polygon, not by colour, because the glass colour also shows up as light on the walls and in string lights.
- "Chair seen exactly from the side in profile" worked in room 4. Room 3's prompt didn't say it, and its chair came out from behind.

## Room 3 variants (3 generations, 2026-11-20)

The user asked for three variations of room 3, with the chair turned side-on and clean glass. Prompt and job ids are in `prompts.md`.

| Variant | Chair | Glass | Notes |
|---|---|---|---|
| 3a | Three-quarter, turned toward the desk; not a true profile | Skyline drawn in the glass, plus glare streaks | Closest to room 3's capsule feel; long desk under a three-panel window; lantern and teal tube kept |
| 3b | Three-quarter from behind, at the desk's end | Moon, glare and faint shapes drawn in | Warmest; window over the desk with the lamp in front; daybed on the right |
| 3c | Seen from behind, centred at the desk | Skyline and glare | Most symmetrical and readable: centred window with curtains, desk across it, lamps both sides, bed right; the clock shows stray text |

What we learned: pixen ignores "seen exactly from the side" in this layout and still draws a city in the glass. The city is replaced anyway (the glass is cut by its outline), so the drawn skyline doesn't matter. A side-on chair will have to come from the user's edit, as already planned.

## Next

**Decided (user): room 3 (2026-11-17), then variant 3a (2026-11-20), edited by the user.** No more room generations. The user removes the chair from room 3 by hand and supplies it as a separate asset. Handoff format:

- `ArtLab/type-d-capsule/raw/room-3a-nochair.png`: room 3a (480×352) with the chair painted out (wall, desk legs and floor filled in behind it).
- `ArtLab/type-d-capsule/raw/chair.png`: the chair alone on transparency, in the same 480×352 canvas and the same position, so it lines up with no offsets. Side-on if possible, so a profile character works.
- Optional: glass glare and moon painted out, or left in; the window is keyed by polygon either way.

With a separate chair the layering is chosen per pose: the chair back sits behind the body (room layer), and any part in front of it (near armrest, seat edge) becomes a foreground piece cut from `chair.png`. After that comes plan Task 2: character rest pose, city, lamp off. The names are renamed from `Violet*` at that point.

## The user's edit (2026-11-21)

`raw/room-3a-nochair.png` and `raw/chair.png`, both 480×352. The editor re-rendered the whole picture (71 colours became about 50,000, slightly soft), so `python3 ArtLab/type-d-capsule/cut_layers.py` builds clean layers in `layers/` (git-ignored) and leaves the user's files untouched:

- `layers/room.png`: the original PixelLab pixels everywhere, except the area the user painted (chair, its floor shadow, relit floor), which takes the user's fill snapped to the original 71-colour palette. The area is the connected patch of real changes touching the chair.
- `layers/chair.png`: the original pixels under the user's chair mask, hard alpha.
- The script asserts that pixels outside the painted area are unchanged and that every colour is from the original palette.

The chair is drawn three-quarter, turned toward the desk. In the scene it is room art behind the character; its near armrest and seat front will become foreground pieces once the character exists. With the chair layered over the clean room it has no floor shadow; one can be drawn later if it looks like it floats.

## Window glass keyed out (2026-11-21)

`cut_layers.py` also removes the drawn city from the three window panes of `layers/room.png`, so the scenery pack shows through (the room's glass is the mask for the scenery layer). Inside each pane polygon it clears the sky, building and window-light colours, then any leftover speck under 40 px that doesn't join the curtain, frame or a desk object. The laptop's box is kept whole. The frame, its teal highlight, curtains, cords, plant and laptop stay. About 33,000 px are transparent. Preview on magenta: `build/art/d-room-keyed-3x.png`.

## Character, city, lamp off (3 generations, 2026-11-21)

- **Boy** (`raw/boy-rest.png`): a good side-profile seated figure (headphones, hoodie, typing), but PixelLab drew a chair, desk, monitor, bottle and keyboard despite "only the boy". They are separate shapes, so they are removed by hand (the user's "removing is easier than generating"). His chair is side-on while the room's chair is three-quarter; fitting him to the room's chair is the next decision.
- **City** (`raw/city-night.png`): fits the window very well at offset (2, 14): teal sky, amber windows, neon signs, train. Preview with the room: `build/art/d-room-city-3x.png`.
- **Lamp off** (`raw/lamp-off-crop.png`): the lamp is off, but the edit also darkened the whole crop (plants, curtain, shelf), so pasting it as a block would leave a dark square. It is used only inside the lamp's glow area, blended at the edges.

## Boy from the user's image (2026-11-24)

The PixelLab boy (`raw/boy-rest.png`) was rejected. The user supplied `raw/boy-source-user.png` instead: room 3a re-rendered with a seated side-profile boy on a side-on chair, approved for use. Only the boy and his chair are taken from it; the room stays ours. Details and job ids in `prompts.md`.

Pose tests (`edit_image_pixen` from the study crop, 3 generations): **drink** and **rest** are consistent with the study pose; **stretch** is not (he turned to face the camera). Retry stretch later with "keep the exact side profile facing left, only the arms rise above the head", or swap it for a smaller routine.

Next: cut the boy and his chair into separate layers (chair behind, near armrest as a foreground piece), clean the edges in Aseprite, build the scene for `-artSet D`.

## Lamp-off room (2026-11-24, no generations)

`cut_layers.py` now also writes `layers/room-off.png`. The PixelLab edit darkened its whole crop, so it is used only on pixels the lamp lights in the room (warm and bright: the wall cone, the desk top, the lamp). The desk left of the crop fades back to lit through a 16 px dither. The floor and bed are lit by the paper lantern and stay. Preview: `build/art/d-lampoff-check.png`. A touch-up in Aseprite can smooth the fade later.

## Cutting out the boy: blocked

An automatic cut by difference doesn't work: the user's image is a re-render, so its background differs from our room everywhere, and the dark trousers and chair match the dark floor. Hand-tracing each pose at 160×200 is unreliable. PixelLab `remove_background` (1 generation per image) was refused by the session's permission check. Options for the user: allow it, or cut the boy and his chair by hand as was done for the room chair.

## Boy cut out, scene built (2026-11-24, 3 generations)

- PixelLab `remove_background` on the study, drink and rest crops (jobs in the boy's sidecar). It kept his chair with him, but removed the room cleanly.
- `cut_layers.py` splits the chair off: the chair back (right of a slanted line behind his back), the seat and base, and the armrest go into the room picture; the armrest and its post also go into `chair_front.png`, a foreground piece, so they cross his hip. The rest is the boy: three 132×181 frames at `desk-seat` (206, top 157).
- `make_source.lua` built `CapsuleDesk01.aseprite` (frames room, room_off, chair_front), `CapsuleBoy.aseprite` (study, drink, rest) and `CapsuleCityNight.aseprite` once from `layers/`; `CapsuleCat.aseprite` is set A's orange cat. Edit these from now on; `export.py` writes the scene and packs.
- The city frame starts at x 14 (the safe area), so its left 12 columns are cropped and the glass left of x 14 keeps the room's own pixels.
- Routines: drink and rest with set A's timings. No stretch yet.
- Checks: `testArtSetDRunsTheEngineUnchanged`; `Executed 133 tests, with 0 failures` on the iPad; launched with `-artSet D -time night -weather clear -lamp on`, screenshot `build/shots/d-ipad.png`.

## Open for set D

1. ~~Stretch~~: replaced by a lean-back routine (2026-11-24).
2. ~~The cat is set A's~~: replaced by a cat drawn for this room (2026-11-24).
3. Rain, music skin, day room and day city done (2026-11-24).
4. Study is one frame: a 1 px head-bob or typing frame would make it breathe.
5. Lamp-off fade on the desk could be smoothed in Aseprite.
6. Girl character: same method (supplied image or PixelLab), not started.

## Stretch retry and a cat for this room (2026-11-24, 4 generations)

- **Stretch, second try: rejected.** Even with "keep the exact side profile, do not turn him toward the camera", `edit_image_pixen` turned him front-on (legs and chair drift 47, noise about 20). Two tries, same failure: this tool doesn't raise both arms in profile. Options: draw the arms by hand in Aseprite from the study frame, pick a profile-safe routine instead (head tilt back, neck roll, sip already exists), or try the pricier `edit_image` (10+ generations).
- **Cat:** a new orange tabby drawn for this room's light (amber key, teal rim), 24×20, replacing set A's copy. `cut_layers.py` keeps only its main shape (drops stray specks) and adds a breathing frame. Animations: `sleep` (2-frame breath, 1 fps), `idle` (a short peek, routine), `react` (awake face on tap). It sits on the desk front in front of the plant (`pet-spot` 116, top 258).
- `Executed 133 tests, with 0 failures` on the iPad after the change.

## Lean-back routine and a sharper boy (2026-11-24, 2.1 generations)

- **Lean** replaces stretch: leaning back, head tilted up, hands on his lap. He stays in profile (drift 12). Routine weight 1, cooldown 900 s, 3 s long, like set A's stretch. The armrest (foreground) passes in front of his hand.
- **Sharpness** (the user: "the boy is not that sharp"): the source image is high-resolution art that was scaled down with blending. PixelLab `correct_pixelart` barely helped. Shrinking the original by majority colour per 3×3 block instead gives dark outlines and clear eyes and hands, so the study frame and the chair now come from that (free). Drink, rest and lean were generated from the soft crop and stay softer; regenerating them from the sharp crop would cost about 6 generations (3 edits, 3 cut-outs).
- `Executed 133 tests, with 0 failures` on the iPad.

## All poses sharp (2026-11-24, 6 generations)

Drink, rest and lean were regenerated from the sharp study crop and cut out again, so all four frames now have the same crisp outlines. They are still consistent with the study pose (drift 8–25). In the rest pose the lamp's light on the wall shows behind his lowered head; that is the room, not the sprite. `Executed 133 tests, with 0 failures` on the iPad. Preview: `build/art/d-poses-final.png`.

## Art set switch in Settings (2026-11-24)

The user asked for a way to swap the scene in the app and chose "applies on reopen" over a live swap (a live swap would need a teardown path for timers, clock, weather, rain audio and Spotify). Settings → Art set lists the registry's sets by name; the choice is saved as `RoomConfig.artSet` and used at the next launch; a launch argument still wins, and a saved set that no longer exists falls back to the active one. `SpriteAssetRepository` now exposes `artSets` (letter to name) and `artSet` (the running letter). Test: `testArtSetChoiceIsListedAndSavedForNextLaunch`. `Executed 134 tests, with 0 failures` on the iPad; the picker shows A, B and D on the device.

## Rain and music player (2026-11-24, no generations)

`ArtLab/type-d-capsule/skin.py` (adapted from set A's `build_art.py`, which runs on import and can't be shared) draws them in room 3a's colours; `export.py` writes them and the manifest fields.
- **Rain:** two depths of streaks plus beads, teal-white, 6 frames at 8 fps over the 220×224 city frame.
- **Music player:** a 118×66 indigo wall tablet with a teal neon strip, on the right wall over the blank poster (set A's 178 px radio would cover the boy's head here). Cover, title, artist, controls and Spotify logo slots; cream title `#DCF6F4`, teal secondary `#6BD5D3`. Floating notes (amber and teal) above the boy's head while music plays.
- Checked on the iPad with `-artSet D -weather rain -showMusic YES`: rain in the window, the tablet shows "Spotify is paused". The action button text is cut to "Resume in Spoti…" because the tablet's screen is only 58 px wide. `Executed 134 tests, with 0 failures`.

## Day room and day city (2026-11-24, 1 generation)

- **Day city:** an edit of the night city into a golden late afternoon, same skyline. The scenery pack is renamed `CapsuleCity01` (it now holds both) with `phases` night → `night`, day → `day`. `Tools/aseprite_export.py` now passes a sidecar's `phases` through and checks that each names a real animation.
- **Day rooms:** `cut_layers.py` tints room and lamp-off room with a mild warm light (22 %), as set A does with script-made day rooms. The chair is left untinted so it matches its armrest, which is a foreground piece shared by day and night (and the boy, who is never tinted). The scene now has all four rooms.
- `Executed 134 tests, with 0 failures` on the iPad. Preview: `build/art/d-day.png`.

## Bigger cat (2026-11-24, 1 generation)

From the cohesion review: the 24×20 cat read as a kitten and its orange was too saturated. The new one is 43×33, muted orange with chunky clusters. PixelLab drew a teal cushion behind it; furniture can't be in a pet sprite, so `cut_layers.py` moves the cushion pixels into the room under the cat. Frames: sleep, breath, and a one-row startle hop. The tap reaction is the hop until an awake frame is drawn (1 generation, an edit of this cat). `pet-spot` 103, top 246, 43×33 (moved up 10 px on 2026-11-26: it hung over the desk front on the device). The 32×32 cat is kept in `raw/` but unused. `Executed 134 tests, with 0 failures` on the iPad (2026-11-26).
- **Awake frame (2026-11-26, 1 generation):** an edit of the same cat with eyes open, shape identical. Tap: hop, then awake for a second, then back to sleep. Idle routine: a short awake peek. `Executed 134 tests, with 0 failures`.
