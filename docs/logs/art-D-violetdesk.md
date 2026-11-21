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
