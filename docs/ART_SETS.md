# Art sets

An **art set** is one complete look for the room: a scene plus the characters, pets, scenery and clock drawn for it. Sets are lettered (A, B, C, ...). The engine is the same for all of them; no Swift changes are needed to add or switch a set.

## Registry

| Set | Name | Status | Scene folder | Perspective tag | Sources | Build command | Log |
|---|---|---|---|---|---|---|---|
| **A** | Lo-fi room (three-quarter view from behind) | **Active.** First-pass PixelLab art plus stand-ins | `StudyRoom01` | `study-room-back-3q-v1` | `ArtSource/` | `python3 Tools/build_art.py` | [M1](logs/M1.md), [engine-first](logs/M2-engine.md) |
| **B** | Cyberpunk side desk | Experimental spike, saved. Closer to the reference board; not cleaned up | `CyberDesk01` | `cyber-desk-side-v1` | `ArtLab/type-b-cyberdesk/` | `python3 ArtLab/type-b-cyberdesk/export.py` | [art-B](logs/art-B-cyberdesk.md) |

What each set contains (folders under `LoFiRoom/Assets/`):

| Set | Characters | Pets | Scenery | Clock | Extras |
|---|---|---|---|---|---|
| A | `Boy01`, `Girl01` | `OrangeCat`, `BlackCat` | `NeonCity01`, `NeonCity02` | `RetroDigital01` | Routines, tap reaction, rain, day/night, lamp on/off, hotspots, music skin (wall player and floating notes) |
| B | `CyberBoy` | `CyberCat` (A's orange cat reused) | `CyberCity01` | `CyberClock` (A's clock reused) | Hotspots only. No routines for the character, no rain, day or lamp-off art, no music skin (falls back to the plain card) |

## How to switch

- **For one launch:** add the launch argument `-artSet B` (or `-artSet A`).
- **As the default:** change `"active"` in `LoFiRoom/Assets/art-sets.json`, then rebuild. This is the only place the default is decided.
- **To check which set a scene belongs to:** its `manifest.json` has `"artSet"`.

`art-sets.json`:

```json
{
  "active": "A",
  "sets": {
    "A": { "name": "Lo-fi room (three-quarter view from behind)", "scene": "StudyRoom01" },
    "B": { "name": "Cyberpunk side desk (experimental)", "scene": "CyberDesk01" }
  }
}
```

It is the one hand-edited file under `LoFiRoom/Assets`; everything else there is generated.

## How a set is held together

- The scene manifest names a `perspective` tag. A pack is offered in a scene only if its manifest has the same tag, so packs from different sets never mix.
- Pack folder names must be unique across all sets (`Boy01` and `CyberBoy`, not two `Boy01`).
- The app saves one configuration. Its pack names belong to the set that was last run; a name the current set does not have falls back to that set's first pack, and the fallback is saved. So switching sets resets the character, pet and scenery choice.

## Adding set C

1. Pick a scene folder name and a new perspective tag, for example `SideProfile01` and `side-profile-v1`.
2. Put the sources in `ArtLab/type-c-<name>/`: raw images, `.aseprite` files, a `.pack.json` sidecar per pack, and an export script. Copy `ArtLab/type-b-cyberdesk/` as the starting point; `cut_layers.py` and `export.py` hold all its coordinates.
3. The export script writes `Scenes/<folder>/` (with `"artSet": "C"`, canvas, safe rectangle, the seven anchors, foreground pieces, optional hotspots, rooms, rain and a `music` skin) and runs `Tools/aseprite_export.py` for each pack with `LoFiRoom/Assets` as the out root.
4. Add `"C"` to `art-sets.json` and a row to both tables above.
5. Add a log `docs/logs/art-C-<name>.md` and a line in `docs/logs/worklog.md`.
6. Run the tests on the iPad, then launch with `-artSet C`.

Rules that every set must meet are in `CLAUDE.md` ("Layered sprite rendering", "Reusable engine vs art"): characters and pets contain no furniture, anything hiding a body is a foreground piece, anchors sit inside the safe rectangle.

## Removing a set

Delete its folders under `LoFiRoom/Assets/` (see the tables), its `ArtLab/type-<x>-<name>/` folder, its entry in `art-sets.json`, and its rows here. `testArtSetsAreChosenByTheRegistry` names the sets it expects and needs the same edit.
