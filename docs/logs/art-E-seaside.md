# Art set E — seaside hut

A cozy lo-fi seaside hut, based on the user's concept image "Seaside Hut Through Three Lights" (sunset and moonlit-night panels). The image itself is local only, like the other concept art: `docs/reference/seaside-hut-three-lights.png` (git-ignored; 1672×941, day panel left, sunset top right, night bottom right). Only the PixelLab conversions are in the repo. First pass: runs with `-artSet E`; not the default. PixelLab prompts and job ids: `ArtLab/type-e-seaside/prompts.md`.

Decisions (user, 2026-11-26):
- The character is seen from behind, facing the sea, as in set A.
- The sunset light is the day look; the engine stays day/night.
- The layout is free; the layer rules stay.
- One character in two outfits, shirt and shirtless, instead of a boy and a girl.
- Ocean waves play beside the rain, each with its own control.

## Build

```sh
python3 ArtLab/type-e-seaside/cut_rooms.py   # room + scenery from the two PixelLab conversions
python3 ArtLab/type-e-seaside/export.py      # scene, packs and rain into LoFiRoom/Assets
```

Packs are written straight from `raw/` (no `.aseprite` sources yet). The waves file is local only: see `docs/AUDIO.md`.

## Files (`ArtLab/type-e-seaside/raw/`)

| File | What |
|---|---|
| `px-sunset-faithful.png`, `px-night-faithful.png` | PixelLab `image_to_pixelart` (faithful, strength 200) of the sunset and night panels, 320×240 |
| `room-day.png`, `room-night.png` | Room, 320×240, transparent in the sea opening |
| `scenery-day.png`, `scenery-night.png` | The sea view, 205×140: the opening's bounding box from the same conversions |
| `boy-raw.png` | PixelLab output for the boy, with the desk it drew |
| `boy-shirt.png`, `boy-shirtless.png` | The boy, 56×56, desk erased; the shirtless one is an edit of it (same pose) |
| `boy-shirt-drink.png`, `boy-shirt-rest.png` | Poses, recoloured to `boy-shirt.png`'s palette |
| `boy-shirt-stretch.png`, `boy-shirt-stretch-big.png` | The stretch as drawn (about 1.2× too small) and scaled back up, 56×70 (used) |

## Scene `SeasideHut01`

- Canvas 320×240, safe area 298×208 at (11, 16): an exact 8× on the iPad Pro 11" (2388×1668). Perspective `seaside-hut-back-v1`.
- Anchors, top-left image pixels: seat (100, 148) 56×70, at the table a little right of centre; view (57, 32) 205×140; clock (269, 128) 23×15 standing on the right counter, left of the lantern; pet spot (178, 194) 32×24 on the rug.
- `foreground` is empty: the boy sits in front of the table, so nothing covers him.
- Rooms: day and night. The lamp-off rooms are the lit rooms (stand-ins).
- `actorTints`: cooler boy at night, warmer at sunset (`#6C74B0` 0.35 at night, `#5A5C8C` 0.45 at night with the lamp off, `#FFC896` 0.15 by day).
- `ambient`: `ocean-waves`, "Waves". `rain`: `rain.png`, 4 frames at 8 fps, two layers of slanted streaks over the opening, no drops on glass (the hut is open). It sits in the scenery group, so the post, chime and plant stay in front.
- Music player (Spotify): tapping the chest (hotspot `computer`, (224, 150) 40×32) opens an 87×43 teak panel at (218, 60) with set D's layout at 0.625 scale, so the text is the same size on screen at 8× as D's at 5×. 10×10 icons; amber and cream notes rise above the chest while a song plays. (A script-drawn radio on the chest was tried and dropped: it looked off.) Lamp, window and pet tap spots are left out: no lamp-off art, one sea view, no cat.
- Packs: `SeasideView01` (scenery), `SeasideBoy` (study, drink, stretch, rest), `SeasideBoyShirtless` (study only), `SeasideClock` (set A's digit shapes in lantern amber on a teak bezel from `skin.py`; set A's cyan LCD looked out of place). No cat yet: the engine logs "No usable pack in Pets" and runs on.

## How the art was made

**Room.** Three PixelLab test rooms were rejected ("all very bad"), and a plain 2× shrink of the concept image was muddy. PixelLab `image_to_pixelart` in faithful mode gave clean pixel art; strengths 10 to 200 look nearly the same, so 200 is used. `cut_rooms.py` cuts the opening: flood fill from sky and sea seeds; enclosed islands filled (moon, stars, town lights, boat); opaque specks of 40 px or less in the opening dropped; a tight tolerance around the shell chime so it stays. The day cut also takes the night cut wherever the day pixel is not a warm object. Check: room over scenery rebuilds each conversion exactly (0 holes, 0 differing pixels).

**Sea motion.** `export.py` makes three scenery frames per look, played 0-1-0-2 at 1.5 fps. Sea rows slide 1 px, alternate rows in opposite directions, so the glints and the sun or moon reflection shimmer. At night about a third of the town windows dim in one frame. Only pixels seen through the opening change, so the post and chime copies baked into the scenery never show. These stay still (each one the user saw wobble):
- the sailboat and its reflection: a box;
- the plant leaves over the sea: a box, because a colour rule missed their shaded and sunlit parts;
- the headland: from column 120 the shimmer starts at row 103, below its base.

**Boy.** One `create_image_pixen`, 56×56, seen from behind. PixelLab drew a desk under his arms despite the prompt; it is erased by hand. The poses are `edit_image_pixen` edits, recoloured to the base palette because PixelLab lightened the shirt. The stretch came out about 1.2× too small (legs 33 px wide against 39), so it is scaled back up: EPX 2×, then nearest-neighbour to 1.2×, hips and feet lined up with the base pose. Every boy frame is padded to 56×70 for the raised arms; the bottom-left anchor keeps him in place.

## Checks

`Executed 136 tests, with 0 failures` on the iPad (2026-11-26): `testArtSetERunsTheEngineUnchanged` (packs, resting animation, no pet, clock, room sound, player, chest tap spot) and `testRoomSoundPlaysBesideTheRain` (fixture). Watched on the device in day, night and rain. No energy measured.

## Known limits and next

- **Needs PixelLab:**
  - the shirtless poses (3 generations);
  - a cat;
  - possibly a new rest pose (his head tilts sideways instead of dropping).
- **Free:**
  - lamp-off rooms;
  - lamp tap spot (with the lamp-off rooms).
- Moving the scenery (a drifting boat, parallax) would show the post and chime pixels baked into it; repaint them first.
- The waves' source is assumed to be Pixabay from the file name; the user should confirm (`docs/AUDIO.md`).
