# Lo-Fi Room

A quiet, customizable, living 2D pixel-art lo-fi study room for iPad. It runs as a full-screen foreground app that looks like an animated screensaver: a character studies at a desk, a cat sleeps on the window sill, a city glows outside, and the clock in the room shows the real time. It is not a game, and it is built to stay open for hours on little power.

Built with SwiftUI and SpriteKit. No backend. The only third-party dependency is Spotify's iOS SDK, for the optional now-playing card.

## Features

- A layered pixel-art room: character, cat, city behind the window, real `HH:mm` clock on the desk.
- Occasional routines (drink, stretch, rest) and a cat that reacts when tapped. How often routines happen is a setting.
- Tap the lamp, window, cat or monitor. Tap empty room to reveal the settings gear.
- Time and weather follow the real day and a chosen city (Open-Meteo), or are set by hand.
- Optional Spotify now-playing player on the wall (remote-controls the Spotify app).
- Optional rain sound mixed on top of Spotify, with its own volume.
- Pauses itself in the background; lower frame rate under Low Power Mode or heat.

## Status

| Milestone | What | State |
|---|---|---|
| M0 | SpriteKit room, integer pixel scaling, anchors | Done |
| M1 | Swappable sprite packs, layered scene, real pixel clock, saved setup | Done |
| Engine-first (M2 + M3a) | Routines, taps, settings panel, time and weather, power policy | Done |
| M3b | Spotify now-playing | Done |
| Art set A | Real poses, cat reactions, lamp-off room | Mostly done; day rooms and day city views are still stand-ins |
| M4 | Energy measurement, power tuning, polish | Not started |

Progress notes are in [`docs/logs/worklog.md`](docs/logs/worklog.md).

## Build and test

You need Xcode 27, [XcodeGen](https://github.com/yonaskolb/XcodeGen), Python 3 and an iPad on iPadOS 26 or later. Tests run on the device.

```sh
export DEVELOPMENT_TEAM=<your Apple team ID>
export SPOTIFY_CLIENT_ID=<your Spotify app's client ID>   # optional; without it the music card says Spotify is not set up
# optional: put a rain loop at LoFiRoom/LocalAudio/rain.mp3 (see docs/AUDIO.md); without it the Sound settings are hidden
IPAD=<your device UDID>            # xcrun devicectl list devices

xcodegen generate
xcodebuild test -project LoFiRoom.xcodeproj -scheme LoFiRoom \
  -destination "platform=iOS,id=$IPAD" -allowProvisioningUpdates -derivedDataPath build
```

Launch options include `-character Girl01`, `-pet BlackCat`, `-scenery NeonCity02`, `-time night`, `-weather rain`, `-lamp off`, `-routineSpeed 20`, `-fps 12`, `-debugAnchors YES`; the full list is in `CLAUDE.md`.

In the app: tap the cat, lamp, window or monitor; tap empty room to reveal the settings gear at the top-right.

## Repository map

| Path | Contents |
|---|---|
| `LoFiRoom/` | App source: `Domain`, `Application`, `Infrastructure`, `Rendering`, `Presentation` |
| `LoFiRoom/Assets/` | Generated sprite packs (do not edit by hand) |
| `LoFiRoomTests/` | Unit tests |
| `ArtSource/` | Raw generated images art set A is built from |
| `ArtLab/` | Aseprite sources: art set A's cats (`type-a-lofi`), art sets D (`type-d-capsule`) and E (`type-e-seaside`), and the pipeline proof of concept (`aseprite`) |
| `ArtLab/aseprite/` | Editable `.aseprite` sources and their exported packs (pipeline proof of concept, see `docs/ASEPRITE_WORKFLOW.md`) |
| `Tools/` | `build_art.py` builds art set A; `aseprite_export.py` exports Aseprite sources; `preview.py` composites the layers without a device; `make_icon.py` makes the app icon |
| `docs/spec/` | The locked MVP specification, design brief and review report |
| `docs/ART_SETS.md`, `docs/ASEPRITE_WORKFLOW.md`, `docs/AUDIO.md` | How art sets, the Aseprite pipeline and the rain sound work |
| `docs/logs/` | Per-milestone work logs |
| `docs/plans/` | Implementation plans |
| `CLAUDE.md` | Working directions for AI coding agents |

## How the scene is put together

The room is a stack of independent sprite layers: scenery behind the window, the room itself (its window glass is transparent), the character and pet, foreground furniture that hides part of the character, then in-world objects such as the clock. Each character, pet, city view and clock skin is a folder with a `manifest.json` and a sprite sheet, so adding or replacing one needs no code change.

## Art sets

The room has more than one look. Set A (lo-fi room) is the default; set D (capsule desk) and set E (seaside hut) are first passes you can see with the launch option `-artSet D` or `-artSet E`, or in Settings → Art set. The registry is in [`docs/ART_SETS.md`](docs/ART_SETS.md).

## Art credits

The Spotify logo is Spotify's official asset, shown as their developer design guidelines require. The rain sound is not in this repository (see `docs/AUDIO.md`).

The room, characters, cat and city views were generated with [PixelLab](https://pixellab.ai) and are subject to PixelLab's [Terms of Service](https://pixellab.ai/termsofservice). The black cat, animation frames, clock digits and the chair cut-out are produced by `Tools/build_art.py`. This art is a first pass and will change.

## Licence

No licence has been chosen yet; all rights reserved.
