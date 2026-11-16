# Audio

## Rain sound

| | |
|---|---|
| Use | Optional rain loop played on top of Spotify (Settings → Sound: Off / When raining / Always, with its own volume) |
| File | `LoFiRoom/LocalAudio/rain.mp3` (copied from `docs/sound/rain.mp3`) |
| Source | "Calming Rain" by liecio, Pixabay: https://pixabay.com/ (downloaded 2026-11-16) |
| Licence | Pixabay Content License: free to use in an app, but not to redistribute as a standalone file |
| In git? | **No.** `docs/sound/` and `LoFiRoom/LocalAudio/` are git-ignored, so the public repo does not hand out the raw file |

A fresh clone builds without it: `project.yml` lists `LoFiRoom/LocalAudio` as an optional folder, and the app hides the Sound settings when the file is missing.

To set it up on a new machine: put the file at `LoFiRoom/LocalAudio/rain.mp3`, then run `xcodegen generate`.

## Rules

- The rain plays mixed with other audio (`AVAudioSession` category `.playback`, option `.mixWithOthers`): Spotify keeps playing at full volume.
- It fades in and out over 1.5 s and stops when the app is not active. There is no background audio mode.
- Nothing in the room reacts to the audio (spec §1.6: no audio-reactive visuals).
- Built-in ambient audio was listed as post-MVP in `docs/spec/MVP_REVIEW_REPORT.md` §7; the user asked for it on 2026-11-16.
