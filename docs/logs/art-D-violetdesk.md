# Art set D — room exploration

**Status:** Room 3a chosen; the user's chair-free edit and separate chair are in and cut into layers (2026-11-21). Next: character rest pose, city, lamp off. Nothing is in the app yet.
**Plan:** [`docs/plans/2026-11-17-art-set-d.md`](../plans/2026-11-17-art-set-d.md)
**Sources:** `ArtLab/type-d-violetdesk/raw/room-1.png` … `room-5.png`; prompts and job ids in `ArtLab/type-d-violetdesk/prompts.md`.

## Decisions so far (user, 2026-11-17)

- Direction: cozy cyberpunk lo-fi. The reference board is a guide, not a strict target, and it doesn't have to be violet.
- Character: generate the full seated body and cut it ourselves.
- **Room 3 chosen**, then **variant 3a** (2026-11-20). The user edits out the chair by hand instead of spending generations on more rooms.
- **Keep every generated room** (`room-1` … `room-5`, `room-3a/b/c`) in `raw/`; none are deleted.
- The names `VioletDesk01` / `violet-*` are placeholders until a room is chosen.

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

- `ArtLab/type-d-violetdesk/raw/room-3a-nochair.png`: room 3a (480×352) with the chair painted out (wall, desk legs and floor filled in behind it).
- `ArtLab/type-d-violetdesk/raw/chair.png`: the chair alone on transparency, in the same 480×352 canvas and the same position, so it lines up with no offsets. Side-on if possible, so a profile character works.
- Optional: glass glare and moon painted out, or left in; the window is keyed by polygon either way.

With a separate chair the layering is chosen per pose: the chair back sits behind the body (room layer), and any part in front of it (near armrest, seat edge) becomes a foreground piece cut from `chair.png`. After that comes plan Task 2: character rest pose, city, lamp off. The names are renamed from `Violet*` at that point.

## The user's edit (2026-11-21)

`raw/room-3a-nochair.png` and `raw/chair.png`, both 480×352. The editor re-rendered the whole picture (71 colours became about 50,000, slightly soft), so `python3 ArtLab/type-d-violetdesk/cut_layers.py` builds clean layers in `layers/` (git-ignored) and leaves the user's files untouched:

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
