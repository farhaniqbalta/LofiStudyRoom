# Art set A — lo-fi room: sprite pass

**Status:** Character and cat stand-ins replaced; lamp-off room replaced. Day rooms, day city views and rain are still stand-ins.
**Date:** 2026-11-16
**Registry:** [`docs/ART_SETS.md`](../ART_SETS.md)

## What changed

| Asset | Before | Now | Source |
|---|---|---|---|
| Boy01, Girl01 `drink` | 4×5 px mug pasted on the rest frame | Real pose: mug raised to the mouth, head tilted back | PixelLab edit of the rest picture |
| Boy01, Girl01 `stretch` | Upper body shifted up 2–4 px | Real pose: leaning back, hands behind the head | PixelLab edit |
| Boy01, Girl01 `rest` | Head shifted 2 px | Real pose: leaning back, hands in lap, looking out of the window | PixelLab edit |
| OrangeCat, BlackCat `idle` | Tail moved 1 px | Ear twitch, drawn in Aseprite | `ArtLab/type-a-lofi/*.aseprite` |
| OrangeCat, BlackCat `react` (tap) | Whole cat lifted 1–2 px | Startle hop with eyes opening (green eyes), drawn in Aseprite | same |
| Room, lamp off | Hand-traced cone recoloured darker (cone still faintly visible) | Lamp area re-rendered unlit by PixelLab, patched into the room only where it was lit, colour-matched to the untouched wall | PixelLab edit of a 256×160 crop |

Each routine is now one held pose: drink 2.5 s, stretch 3 s, rest 8 s. The character frame grew from 85×159 to 114×162 to fit raised arms; the `desk-seat` anchor follows.

## PixelLab jobs (7 generations)

| Asset | Job |
|---|---|
| Boy drink | `eb6bf14f-d1cd-4fc3-a1d9-5847c0592368` |
| Boy stretch | `9e28eaa2-60bd-438d-b318-c512197fcfb3` |
| Boy rest | `d37d0deb-8676-49d8-b917-7b0288e5f67a` |
| Girl drink | `d677a003-6fb9-455e-a034-b6af5e07a8c2` |
| Girl stretch | `5f911362-7571-4162-872d-7a0cce043704` |
| Girl rest | `f1ff52c5-c21b-4be9-9dfe-2a8203d840cf` |
| Lamp off | `1caa32ca-cc50-4c08-95f8-89f9b91583ea` |

Each pose is an edit of the character's existing rest picture (`ArtSource/<who>_edit_raw.png`), so scale, light and the chair match. Raw outputs are in `ArtSource/`.

## Pipeline

- Characters and the lamp-off room: `Tools/build_art.py` (cut-out with the hand-traced chair occluder; the body behind the chair is continued with nearest colour, as before).
- Cats: `ArtLab/type-a-lofi/OrangeCat.aseprite` and `BlackCat.aseprite` with `.pack.json` sidecars, exported by `Tools/aseprite_export.py`. `Tools/build_art.py` runs that export at its end, so one command still builds the whole set. It now needs Aseprite installed.

## Results

- `Executed 112 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad.
- Device run with `-routineSpeed 20`: of eight screenshots 3 s apart, two showed the rest pose (looking out of the window) correctly placed in the chair.

## Fixes after the user's review (2026-11-16)

- Lamp off: glow was left on the wall above the lamp, outside the crop sent to PixelLab. The wall under the shelf is now recoloured with the lit→unlit colour mapping learned from the patched area (`GLOW_ABOVE` in `Tools/build_art.py`).
- Rain: drops were placed in random columns and left the left pane nearly empty. Now one drop per 4 px column band, so the whole window rains evenly.
- Checked on the iPad at night with rain and the lamp off.

## Rain and music player redrawn (2026-11-17)

- Rain: two depths instead of one row of tiny dashes. Far: short, faint, slow streaks every 3 px. Near: long, bright, fast streaks every 9 px. Ten still beads on the glass. Still a seamless 6-frame loop (each layer repeats every 6 × its step).
- Music player, first redraw: a bevelled retro radio in cool purples. Reviewed against the room: it still read as an app overlay (flat, a palette found nowhere else in the room, unlit by the lamp, no shadow).
- Music player, re-skin: a walnut wall radio. Every colour is sampled from the room (desk wood, sill, lamp light); wood grain lines, a dithered sheen, a warm rim on the side facing the lamp, brass screws, a few scuffs, a dim warm tuner glass behind the text, and a 2 px shadow cast on the wall. Title text is warm cream, artist and messages amber. The panel image grew by the 2 px shadow; slot positions are unchanged.
- Checked on the iPad: rain at night over the city; the player showing "Spotify is paused" / "Resume in Spotify".

## Still stand-ins

- Day rooms (`room_day.png`, `room_day_off.png`): a pale wash; characters look too dark against them.
- Day city views: brightened copies of the night pictures.
- Music skin notes: first-pass, drawn by the script.

## Idea for later: music in a room object (not built)

Instead of a panel on the wall, the music lives in something already in the room, for example a small cassette deck or radio on the window sill or the shelf. Closed, it is just furniture (maybe a tiny lit display or turning reels while playing). Tapped, it opens the readable player. This fits "a living room, no HUD" best. It needs two designs (the closed object and the open player), a hotspot on the object instead of the monitor, and room in the sill or shelf art. The skin manifest would gain an "object" sprite with closed/playing animations; the engine pieces (slots, overlay, controller) stay as they are.

## Known problems

- The cat's tap reaction (startle with eyes opening) is too plain; the user wants more cat animation later.

- Moving between rest and a pose is a cut, not an animation (one frame per pose).
- On the iPad (routines sped up 20×) the rest pose was seen in place with nothing clipped; drink and stretch were not caught in the screenshots.
- Cat frames 3–5 in the `.aseprite` files are unused leftovers of the old stand-ins.
