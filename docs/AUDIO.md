# Audio

## Rain sound

| | |
|---|---|
| Use | Optional rain loop played on top of Spotify (Settings → Sound: Off / When raining / Always, with its own volume) |
| File | `LoFiRoom/LocalAudio/rain.mp3` (copied from `docs/sound/rain.mp3`) |
| Source | "Calming Rain" by liecio, Pixabay: https://pixabay.com/ (downloaded 2026-11-16) |
| Licence | Pixabay Content License: free to use in an app, but not to redistribute as a standalone file |
| In git? | **No.** `docs/sound/` and `LoFiRoom/LocalAudio/` are git-ignored, so the public repo does not hand out the raw file |

## Ocean waves (art set E)

| | |
|---|---|
| Use | Set E's room sound, beside the rain loop (scene manifest `ambient`: file `ocean-waves`, name "Waves"). Settings → Sound: "Waves sound" on/off and its own volume |
| File | `LoFiRoom/LocalAudio/ocean-waves.mp3` (copied from `docs/sound/ocean-waves.mp3`), 92 s stereo loop |
| Source | "Gentle Ocean Waves" by Dragon Studio, supplied by the user as `dragon-studio-gentle-ocean-waves-499666.mp3` (2026-11-26). The file has no tags; the name follows Pixabay's download naming (creator, title, id 499666), so Pixabay is assumed. **The user should confirm the source** |
| Licence | Assumed Pixabay Content License, as for the rain: use in the app, no redistribution as a standalone file |
| In git? | **No**, same folders as the rain |

## Per-room sound

A scene manifest may add its own looping sound: `"ambient": {"file": "<name in LocalAudio, no .mp3>", "name": "<label>"}`. It plays beside the rain loop, ignores the weather, and has its own switch and volume in Settings → Sound (`roomSoundOn`, `roomSoundVolume`, shared across sets). Rain keeps Off / When raining / Always. A missing file hides the room sound's controls. The file is chosen at launch with the room.

A fresh clone builds without it: `project.yml` lists `LoFiRoom/LocalAudio` as an optional folder, and the app hides the Sound settings when the file is missing.

To set it up on a new machine: put the file at `LoFiRoom/LocalAudio/rain.mp3`, then run `xcodegen generate`.

## Rules

- The rain plays mixed with other audio (`AVAudioSession` category `.playback`, option `.mixWithOthers`): Spotify keeps playing at full volume.
- It fades in and out over 1.5 s and stops when the app is not active. There is no background audio mode.
- Nothing in the room reacts to the audio (spec §1.6: no audio-reactive visuals).
- Built-in ambient audio was listed as post-MVP in `docs/spec/MVP_REVIEW_REPORT.md` §7; the user asked for it on 2026-11-16.
