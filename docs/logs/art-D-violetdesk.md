# Art set D — room exploration

**Status:** Exploring rooms. No room chosen yet; nothing is in the app.
**Plan:** [`docs/plans/2026-11-17-art-set-d.md`](../plans/2026-11-17-art-set-d.md)
**Sources:** `ArtLab/type-d-violetdesk/raw/room-1.png` … `room-5.png`; prompts and job ids in `ArtLab/type-d-violetdesk/prompts.md`.

## Decisions so far (user, 2026-11-17)

- Direction: cozy cyberpunk lo-fi. The reference board is a guide, not a strict target, and it doesn't have to be violet.
- Character: generate the full seated body and cut it ourselves.
- **Room 3 is the current favourite.** Spend more generations on room options before moving on to characters.
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

More room generations, starting with variations on room 3. A useful one to try: room 3's layout and palette with the chair seen side-on, so a profile character works. The alternative is to keep room 3 and draw the character from behind, as in set A. Then pick one room and continue with plan Task 2.
