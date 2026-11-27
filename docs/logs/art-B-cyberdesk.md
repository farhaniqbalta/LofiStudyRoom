# Art set B — cyberpunk side desk (experimental)

**Status:** Removed on 2026-11-27 at the user's request (assets, sources, registry entry and tests). This log is kept as history; the files are in git history before that date.
**Date:** 2026-11-15
**Registry:** [`docs/ART_SETS.md`](../ART_SETS.md)

## Why

Art set A is off from the reference board (`docs/reference/`, local only): the board has a side view, a character in profile partly hidden by desk and chair, a much more detailed desk, and a dense cyberpunk city. Set B is a first try at that look through the new workflow: PixelLab draft → Aseprite source → export.

## What was made

| Asset | How | PixelLab job |
|---|---|---|
| Room 480×352 | `create_image_pixen`, window glass asked for as flat green and keyed out | `6a15ba72-3d76-4db9-bbbc-d08f2fe3a58f` |
| Character | `edit_image_pixen` on a 192×224 crop of the room around the chair | `40ff89ad-6abf-4557-985c-de824150f3ae` |
| City 88×224 | `create_image_pixen`, imported unchanged | `c0ec1568-201f-48bc-9ea5-3b74a682cc44` |
| Cat | Set A's orange cat, re-exported under B's perspective tag | none |
| Clock | Copy of set A's clock skin under B's perspective tag | none |

Three generations were used. Usage is under PixelLab's Terms of Service.

## Pipeline (all in `ArtLab/type-b-cyberdesk/`)

1. `raw/`: PixelLab output, untouched.
2. `python3 ArtLab/type-b-cyberdesk/cut_layers.py`: keys the glass, cuts the chair-front layer and the character into `layers/` (git-ignored). The outlines are polygons traced by hand from Aseprite's ruler view.
3. Aseprite sources, built with the Aseprite MCP (`import_image_as_layer`, `copy_frame`, `move_region`, `set_tag`):
   - `CyberDesk01.aseprite`: layers `room`, `chair_front`, and a hidden `ref_pixellab_boy`.
   - `CyberBoy.aseprite`: layer `body`, two frames, tag `study` (frame 2 is a 1 px head bob).
   - `CyberCity01.aseprite`: layer `city`, tag `night`.
   - `CyberCat.aseprite`: copy of `ArtLab/aseprite/OrangeCatAse.aseprite`.
4. `python3 ArtLab/type-b-cyberdesk/export.py`: exports the scene layers and writes the scene manifest (anchors and hotspots are in this script), then runs `Tools/aseprite_export.py` for each pack into `LoFiRoom/Assets`.

After step 2 changes, the layer PNGs must be imported into the `.aseprite` files again before step 4; the export reads only the `.aseprite` files.

## Layering

Scenery behind the room's transparent glass; character between the room and `chair_front` (chair back, near armrest and its support), so the chair really hides his back.

## Results

- `Executed 90 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad, including `testArtSetsAreChosenByTheRegistry` and `testArtSetBRunsTheEngineUnchanged`.
- On the iPad: `-artSet B` shows the new room with the live clock, cat and city; a plain launch gives a screenshot identical to `-artSet A`.
- No Swift change was needed for the art. The only code change is choosing the scene from `art-sets.json`.

## Where the tools fell short

- PixelLab cannot return separate layers: it painted the character into the chair and desk. Inpainting, which could separate them, is not available on the trial plan. Separation is by hand-traced polygons.
- The Aseprite MCP has no object-selection tool. It holds layers, moves regions and draws pixels; cleaning an outline is pixel-by-pixel work.

## Known problems

1. The character sprite is not clean on its own: it carries a little keyboard under the hand and some re-rendered background fringe, and the body behind the chair is flat fill.
2. The shoes are cropped by 8 rows so the sprite stays inside the safe rectangle. Next time generate the room with more floor margin.
3. Against the reference: the head is in profile but the chair and body are three-quarter from behind; the window is narrower and taller; the palette is less violet and neon.
4. Missing: character routines, girl, black cat, second city, rain, day and lamp-off rooms. Tapping the lamp changes nothing visible in this set.
5. The cat keeps set A's routine and tap animations.

## To continue later

Options, cheapest first: clean the character outline in Aseprite; regenerate the character for a true side profile; regenerate the room with a wider window and more floor. Each PixelLab step costs one generation of the daily allowance.
