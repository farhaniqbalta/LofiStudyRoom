# Polish and audio

**Status:** Built and tested on the iPad (132 tests). Awaiting the user's hand check (sound, sliders, logo with a track playing).
**Date:** 2026-11-16
**Branch:** `feature/polish-and-audio` (built on top of `fix/review-findings`, PR #3)

## Done

1. **App icon.** A 128×128 crop of art set A (lamp, clock, monitor, the boy in headphones) scaled 8× with nearest-neighbour to 1024×1024. `python3 Tools/make_icon.py` regenerates it into `LoFiRoom/App/Resources.xcassets/AppIcon.appiconset`.
2. **Spotify logo.** Spotify's official full logo, white (their rule for non-black/white backgrounds), vector PDF from https://developer.spotify.com/documentation/design, as the image set `SpotifyLogo`. It replaces the word "Spotify" in the wall player's attribution slot (210×57 device px on the 11-inch iPad; minimum is 70 px) and sits under the artist in the plain card. Never on the artwork.
3. **Animation frequency.** Settings → Animation: a logarithmic slider from Rare (0.5×) to Often (20×), saved as `RoomConfig.routineFrequency` (default 1×). Applies at once; `-routineSpeed N` still overrides it for one launch. Changing the speed restarts the routine cooldowns (fix for a bug found in review: slowing down after a long fast run left the character idle for hours).
4. **Rain sound.** Settings → Sound: Off / When raining / Always (default When raining) and a volume slider (default 40%). Mixed on top of Spotify, fades in and out over 1.5 s, stops when the app is not active. The file is not in the repo; see [`docs/AUDIO.md`](../AUDIO.md).
5. **Docs.** README (features, status, setup), `CLAUDE.md` (current status instead of the old milestone text), worklog, Aseprite workflow status, new `docs/AUDIO.md`.

## Results

- `Executed 132 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (subagent twice at 131, lead after the cooldown fix at 132).
- The Spotify client ID and the rain file are not in any tracked file.

## Not verified on the device

- The rain sound is audible and mixes with Spotify (cannot be heard from the Mac).
- The Animation and Sound sections of the settings panel (below the fold in screenshots).
- The Spotify logo with a track playing (the screenshot had no track).

## Scope note

Built-in ambient audio was listed as post-MVP in the review report (§7); the user asked for it on 2026-11-16.
