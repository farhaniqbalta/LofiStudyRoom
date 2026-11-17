# Art set D — room exploration

**Status:** Room 3 chosen. Waiting for the user's edit (room without chair, chair as its own image). Nothing is in the app yet.
**Plan:** [`docs/plans/2026-11-17-art-set-d.md`](../plans/2026-11-17-art-set-d.md)
**Sources:** `ArtLab/type-d-violetdesk/raw/room-1.png` … `room-5.png`; prompts and job ids in `ArtLab/type-d-violetdesk/prompts.md`.

## Decisions so far (user, 2026-11-17)

- Direction: cozy cyberpunk lo-fi. The reference board is a guide, not a strict target, and it doesn't have to be violet.
- Character: generate the full seated body and cut it ourselves.
- **Room 3 chosen.** The user edits out the chair by hand instead of spending generations on more rooms.
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

## Next

**Decided (user, 2026-11-17): room 3, edited by the user.** No more room generations. The user removes the chair from room 3 by hand and supplies it as a separate asset. Handoff format:

- `ArtLab/type-d-violetdesk/raw/room-3-nochair.png`: the 480×352 room with the chair painted out (wall, desk legs and floor filled in behind it).
- `ArtLab/type-d-violetdesk/raw/chair.png`: the chair alone on transparency, in the same 480×352 canvas and the same position, so it lines up with no offsets. Side-on if possible, so a profile character works.
- Optional: glass glare and moon painted out, or left in; the window is keyed by polygon either way.

With a separate chair the layering is chosen per pose: the chair back sits behind the body (room layer), and any part in front of it (near armrest, seat edge) becomes a foreground piece cut from `chair.png`. After that comes plan Task 2: character rest pose, city, lamp off. The names are renamed from `Violet*` at that point.
