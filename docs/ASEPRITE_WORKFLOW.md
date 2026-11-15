# Aseprite asset workflow

**PixelLab (optional draft) → Aseprite (edit, animate, clean up) → `Tools/aseprite_export.py` → sprite pack.**

Status: proof of concept, validated on 2026-11-15 with one demonstration pack. The shipped packs in `LoFiRoom/Assets` still come from `Tools/build_art.py`; nothing there was changed.

## Setup (once per machine)

- Aseprite at `/Applications/Aseprite.app` (1.3.18 used here), or set `ASEPRITE_PATH` to the binary.
- Optional, for agents: [diivi/aseprite-mcp](https://github.com/diivi/aseprite-mcp), registered with the same `ASEPRITE_PATH`. The export does not need it; it calls the Aseprite command line directly.

## Files

| File | Role | Edit by hand? |
|---|---|---|
| `ArtLab/aseprite/<Name>.aseprite` | Editable source: layers, frames, tags, frame durations | Yes (Aseprite or the MCP) |
| `ArtLab/aseprite/<Name>.pack.json` | Sidecar: what Aseprite cannot hold | Yes |
| `ArtLab/aseprite/out/<Category>/<Name>/{sheet.png, manifest.json}` | Generated pack | Never; re-export |

`<Name>` is the pack folder name; the manifest `id` is its lowercase form.

## Rules for the source file

- Canvas = the frame size of the category = the size of the scene anchor (pet 37x28, character 85x159 in `StudyRoom01`). The sprite sits with its bottom-left corner on the anchor, so keep the art where it was in the canvas.
- RGB colour mode, one frame per sheet frame. Frame N in Aseprite (1-based) is sheet frame N-1 in the manifest.
- A **tag** becomes an animation with the same name: its frames are the tag's range, its fps is `1000 / frame duration`. Give every frame in a tag the same duration, and use forward tags only.
- Hidden layers are not exported, so reference and guide layers are safe to keep if hidden.
- No furniture in character or pet sprites (see "Layered sprite rendering" in `CLAUDE.md`).

## Sidecar

```json
{
  "category": "Pets", "type": "pet",
  "perspective": "study-room-back-3q-v1", "anchor": "pet-spot",
  "fallbackAnimation": "sleep",
  "animations": {
    "twitch": { "frames": [5, 6, 5], "loop": false, "routine": { "weight": 1, "cooldown": 120 } },
    "react":  { "frames": [3, 4, 3, 0], "fps": 4, "loop": false, "onTap": true }
  },
  "provenance": "where the pixels came from, tool settings, licence"
}
```

Sidecar fields are merged over the tag: add `routine`, `onTap`, `loop`, `safeExits` to a tagged animation, override its `frames` or `fps`, or define an animation with no tag at all (needed when frames repeat or are not contiguous). Optional `"scene": "<folder>"` validates against a scene other than the first one.

## Export

```sh
python3 Tools/aseprite_export.py ArtLab/aseprite/OrangeCatAse.aseprite            # -> ArtLab/aseprite/out/Pets/OrangeCatAse
python3 Tools/aseprite_export.py ArtLab/aseprite/OrangeCatAse.aseprite <out root>  # e.g. LoFiRoom/Assets, to ship a pack
```

The script fails with a readable message, before writing a manifest, on the same rules as `SpritePack.problems()`: wrong perspective, unknown anchor, canvas not the anchor's size, missing fallback, frame index out of range, safe exit not in the animation. It refuses to write into a folder holding a pack it did not export from the same source. Two runs give byte-identical files.

## Validate

1. Look: MCP `view_sprite`, `compare_frames`, `audit_animation`, or open the file in Aseprite.
2. Export (above).
3. On the iPad: `xcodebuild test ... -only-testing:LoFiRoomTests/AsepritePipelineTests`. Everything under `ArtLab/aseprite/out` is a resource of the test bundle; the test copies it beside the bundled scene and loads each pack through `SpriteAssetRepository`. The packs are not in the app.

## What the proof of concept showed

- The existing `Pets/OrangeCat` sheet was split into frames, imported with the MCP, and saved as `OrangeCatAse.aseprite`. Two frames (a small ear twitch) were drawn with the MCP's `draw_rows`.
- After export, frames 0-4 are pixel-identical to the original sheet; `compare_frames` reports 9 changed pixels between the rest frame and the twitch.
- Aseprite's horizontal sheet already matches the pack format (one row, equal frames, RGBA, no padding). **Only the manifest needed an adapter** (about 60 lines). No runtime code changed.
- 88 tests pass on the iPad Pro 11-inch (M1), including the new load test.
- Not done: the pack was not shown on screen in the running app, and no power measurement was taken (nothing in the app changed).

## Recommendations for the art phase

1. Keep one `.aseprite` per pack with the body on its own layer and each moving part (ear, tail, arm, cup) on a separate layer; that is what makes later edits cheap.
2. Use PixelLab only for a first draft of a pose, then import it as a layer and finish in Aseprite. Record the job and settings in the sidecar `provenance`.
3. When a pack is approved, export it with `LoFiRoom/Assets` as the out root under a new folder name, and remove the matching block from `build_art.py`. Do not have two pipelines write the same folder.
4. Scene art (room images, foreground cut-outs, rain) is not covered by the exporter. Add that only when the new scene is started; the room's layered export will need Aseprite's per-layer export, not a sheet.
5. For the art-direction pass, move sources to `ArtSource/aseprite/` (or keep `ArtLab/`) and change the test resource path in `project.yml` to match.
