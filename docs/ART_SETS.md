# Art sets

An **art set** is one complete look for the room: a scene plus the characters, pets, scenery and clock drawn for it. Sets are lettered (A, B, C, ...). The engine is the same for all of them; no Swift changes are needed to add or switch a set.

## Registry

| Set | Name | Status | Scene folder | Perspective tag | Sources | Build command | Log |
|---|---|---|---|---|---|---|---|
| **A** | Lo-fi room (three-quarter view from behind) | **Active.** PixelLab art with drawn poses; day rooms and day cities still stand-ins | `StudyRoom01` | `study-room-back-3q-v1` | `ArtSource/`, `ArtLab/type-a-lofi/` (cats) | `python3 Tools/build_art.py` (needs Aseprite) | [M1](logs/M1.md), [engine-first](logs/M2-engine.md), [sprite pass](logs/art-A-lofi.md) |
| **D** | Capsule desk (cozy cyberpunk, side profile) | First pass, runs with `-artSet D`; not the default | `CapsuleDesk01` | `capsule-desk-side-v1` | `ArtLab/type-d-capsule/` | `python3 ArtLab/type-d-capsule/cut_layers.py` (needs the git-ignored `layers/` only to rebuild sources), then `python3 ArtLab/type-d-capsule/export.py` | [art-D](logs/art-D-capsule.md) |
| **E** | Seaside hut (lo-fi, from behind) | First pass, runs with `-artSet E`; not the default | `SeasideHut01` | `seaside-hut-back-v1` | `ArtLab/type-e-seaside/` | `python3 ArtLab/type-e-seaside/cut_rooms.py`, then `python3 ArtLab/type-e-seaside/export.py` | [art-E](logs/art-E-seaside.md) |

What each set contains (folders under `LoFiRoom/Assets/`):

| Set | Characters | Pets | Scenery | Clock | Extras |
|---|---|---|---|---|---|
| A | `Boy01`, `Girl01` | `OrangeCat`, `BlackCat` | `NeonCity01`, `NeonCity02` | `RetroDigital01` | Routines, tap reaction, rain, day/night, lamp on/off, hotspots, music skin (wall player and floating notes) |
| D | `CapsuleBoy` (study, drink, rest, lean) | `CapsuleCat` (drawn for this room) | `CapsuleCity01` (night, day) | `CapsuleClock` (A's clock reused) | Hotspots, lamp-off room, chair armrest in front of the boy, rain, music skin (wall tablet and notes), day rooms by script tint. No girl yet |
| E | `SeasideBoy` (study, drink, stretch, rest), `SeasideBoyShirtless` (study only) | none yet | `SeasideView01` (night, day = sunset) | `SeasideClock` (A's digits in amber on a teak bezel) | Day and night rooms, actor tints, sea shimmer, rain, waves sound beside the rain. music skin (tapping the chest opens a teak player). No lamp-off art (lit rooms stand in); only the chest is tappable |

## How to switch

- **In the app:** Settings → Art set. The choice is saved and applies the next time the app opens (the room is built once at launch).
- **For one launch:** add the launch argument `-artSet D`, `-artSet E` (or `-artSet A`).
- **As the default:** change `"active"` in `LoFiRoom/Assets/art-sets.json`, then rebuild. This is the only place the default is decided.
- **To check which set a scene belongs to:** its `manifest.json` has `"artSet"`.

`art-sets.json`:

```json
{
  "active": "A",
  "sets": {
    "A": { "name": "Lo-fi room (three-quarter view from behind)", "scene": "StudyRoom01" },
    "D": { "name": "Capsule desk (cozy cyberpunk, side profile)", "scene": "CapsuleDesk01" },
    "E": { "name": "Seaside hut (lo-fi, from behind)", "scene": "SeasideHut01" }
  }
}
```

It is the one hand-edited file under `LoFiRoom/Assets`; everything else there is generated.

## How a set is held together

- The scene manifest names a `perspective` tag. A pack is offered in a scene only if its manifest has the same tag, so packs from different sets never mix.
- Pack folder names must be unique across all sets (`Boy01` and `CapsuleBoy`, not two `Boy01`).
- The app saves one configuration. Its pack names belong to the set that was last run; a name the current set does not have falls back to that set's first pack, and the fallback is saved. So switching sets resets the character, pet and scenery choice.

## Adding set C

1. Pick a scene folder name and a new perspective tag, for example `SideProfile01` and `side-profile-v1`.
2. Put the sources in `ArtLab/type-c-<name>/`: raw images, `.aseprite` files, a `.pack.json` sidecar per pack, and an export script. Copy `ArtLab/type-d-capsule/` (Aseprite sources) or `ArtLab/type-e-seaside/` (packs written straight from PNGs) as the starting point; their `export.py` holds the coordinates.
3. The export script writes `Scenes/<folder>/` (with `"artSet": "C"`, canvas, safe rectangle, the seven anchors, foreground pieces, optional hotspots, rooms, rain and a `music` skin) and runs `Tools/aseprite_export.py` for each pack with `LoFiRoom/Assets` as the out root.
4. Add `"C"` to `art-sets.json` and a row to both tables above.
5. Add a log `docs/logs/art-C-<name>.md` and a line in `docs/logs/worklog.md`.
6. Run the tests on the iPad, then launch with `-artSet C`.

Rules that every set must meet are in `CLAUDE.md` ("Layered sprite rendering", "Reusable engine vs art"): characters and pets contain no furniture, anything hiding a body is a foreground piece, anchors sit inside the safe rectangle.

## Removed sets

- **B**, cyberpunk side desk (a spike from 2026-11-15), removed on 2026-11-27 at the user's request. Its log stays: [art-B](logs/art-B-cyberdesk.md); its sources are in git history before that date.

## Removing a set

Delete its folders under `LoFiRoom/Assets/` (see the tables), its `ArtLab/type-<x>-<name>/` folder, its entry in `art-sets.json`, and its rows here. `testArtSetsAreChosenByTheRegistry` names the sets it expects and needs the same edit.
