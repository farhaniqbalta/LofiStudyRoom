# Spotify now-playing (M3b)

**Status:** Built. The first version (plain card) was hand-tested; the in-room music skin is built and screenshot-checked but not yet hand-tested with music playing.
**Date:** 2026-11-15
**Plan:** [`docs/plans/2026-11-15-spotify-now-playing.md`](../plans/2026-11-15-spotify-now-playing.md) · **Spike:** [`spotify-spike.md`](spotify-spike.md)

## Done

- `Domain/MusicState.swift`, `Application/MusicController.swift` (all state logic behind the `MusicRemote` protocol), `Infrastructure/SpotifyRemoteAdapter.swift` (the only file importing `SpotifyiOS` 5.0.1), `Infrastructure/KeychainToken.swift`, `Presentation/MusicCard.swift`.
- Card states: not set up, not installed, connect, connecting, connected (playing or paused), dropped ("Resume in Spotify"), reconnect.
- The app switches to Spotify only from a button tap. Opening the card or returning to the foreground makes at most one silent connect. Leaving the foreground disconnects. No polling or timers.
- The access token is kept in the Keychain. The client ID comes from `SPOTIFY_CLIENT_ID` at project generation; without it the card says "Spotify isn't set up in this build".

## Music skin (in-room player), added the same day

The user asked for the artwork to fit the room's ambience and for the look to be swappable per art set.

- A scene manifest may carry a `music` block: a pixel-art panel image and its frame, an icon sheet (previous, play, pause, next, close), ten named slots (artwork, title, artist, attribution, previous, toggle, next, close, message, action), two text colours, and an optional notes effect.
- `LoFiSKScene` draws the panel, icons and notes as sprites in the `objects` group; `MusicSkinOverlay` lays text, the cover and invisible tap targets (padded to 44 pt) over the slots. `MusicController` is unchanged.
- While a track is playing, small pixel notes float above the character, whether or not the panel is open. They only switch on and off; nothing follows the beat. Under Reduce Motion they are a still frame.
- A scene without a `music` block keeps the plain `MusicCard`. Art set A has a skin (drawn by `Tools/build_art.py`, listed in `standIns`); art set B has none.
- Spotify's rules: the cover is shown unaltered with rounded corners only, never covered by controls; "Spotify" is credited beside it as text.
- Debug launch argument `-showMusic YES` opens the panel at launch.

## Results

- `Executed 105 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (subagent twice, lead once).
- User hand test on the iPad (2026-11-15): connect, track info, next, previous, pause and in-app resume, drop after a pause, "Resume in Spotify", background and return, close. Reported as all working.
- After the music skin: `Executed 112 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (subagent twice, lead once). Screenshots: set A shows the pixel panel on the wall under the window with "Spotify is paused" / "Resume in Spotify" inside its slots; set B shows the plain card.

## Open issues

- The skin has not been seen on the device with a track playing: cover, title, artist, transport icons and the notes are covered by tests and the offline preview only.
- The Spotify credit is text; Spotify's guidelines ask for their logo or icon. Fine for personal use, to fix before sharing.
- Title and artist use a system monospaced font, not a pixel font, because track names can be in any script.
- On smaller iPads the 44 pt tap areas of previous, play and next could overlap.
- The "sign-in expired" case is detected from the wording of Spotify's error and has not been seen on a device.
- Not tried: Spotify not installed, signed out, offline.
- Spotify Development Mode: personal use, Premium owner, at most 5 users.
