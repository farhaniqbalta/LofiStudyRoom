# Lo-Fi Room

A quiet, customizable, living 2D pixel-art lo-fi study room for iPad. It runs as a full-screen foreground app that looks like an animated screensaver: a character studies at a desk, a cat sleeps on the window sill, a city glows outside, and the clock in the room shows the real time. It is not a game, and it is built to stay open for hours on little power.

Built with SwiftUI and SpriteKit. No backend and no third-party dependencies.

## Status

| Milestone | What | State |
|---|---|---|
| M0 | SpriteKit room, integer pixel scaling, anchors | Done |
| M1 | Swappable sprite packs, layered scene, real pixel clock, saved setup | Done |
| Engine-first (M2 + M3a) | Routine scheduler, tap interactions, customization panel, time and weather | Next |
| M3b | Spotify now-playing | Later |
| Art pass | Art-direction experiments, replacing stand-ins | Later |
| M4 | Power tuning and polish | Later |

Progress notes are in [`docs/logs/worklog.md`](docs/logs/worklog.md).

## Build and test

You need Xcode 27, [XcodeGen](https://github.com/yonaskolb/XcodeGen), Python 3 and an iPad on iPadOS 26 or later. Tests run on the device.

```sh
export DEVELOPMENT_TEAM=<your Apple team ID>
IPAD=<your device UDID>            # xcrun devicectl list devices

xcodegen generate
xcodebuild test -project LoFiRoom.xcodeproj -scheme LoFiRoom \
  -destination "platform=iOS,id=$IPAD" -allowProvisioningUpdates -derivedDataPath build
```

Launch options: `-character Girl01`, `-pet BlackCat`, `-scenery NeonCity02`, `-fps 12`, `-debugAnchors YES`.

## Repository map

| Path | Contents |
|---|---|
| `LoFiRoom/` | App source: `Domain`, `Application`, `Infrastructure`, `Rendering`, `Presentation` |
| `LoFiRoom/Assets/` | Generated sprite packs (do not edit by hand) |
| `LoFiRoomTests/` | Unit tests |
| `ArtSource/` | Raw generated images the packs are built from |
| `Tools/` | `build_art.py` builds the packs; `preview.py` composites the layers without a device |
| `docs/spec/` | The locked MVP specification, design brief and review report |
| `docs/logs/` | Per-milestone work logs |
| `docs/plans/` | Implementation plans |
| `CLAUDE.md` | Working directions for AI coding agents |

## How the scene is put together

The room is a stack of independent sprite layers: scenery behind the window, the room itself (its window glass is transparent), the character and pet, foreground furniture that hides part of the character, then in-world objects such as the clock. Each character, pet, city view and clock skin is a folder with a `manifest.json` and a sprite sheet, so adding or replacing one needs no code change.

## Art credits

The room, characters, cat and city views were generated with [PixelLab](https://pixellab.ai) and are subject to PixelLab's [Terms of Service](https://pixellab.ai/termsofservice). The black cat, animation frames, clock digits and the chair cut-out are produced by `Tools/build_art.py`. This art is a first pass and will change.

## Licence

No licence has been chosen yet; all rights reserved.
