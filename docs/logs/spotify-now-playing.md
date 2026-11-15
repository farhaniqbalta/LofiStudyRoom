# Spotify now-playing (M3b)

**Status:** Built and hand-tested. Open: how the card and artwork should fit the room's look.
**Date:** 2026-11-15
**Plan:** [`docs/plans/2026-11-15-spotify-now-playing.md`](../plans/2026-11-15-spotify-now-playing.md) · **Spike:** [`spotify-spike.md`](spotify-spike.md)

## Done

- `Domain/MusicState.swift`, `Application/MusicController.swift` (all state logic behind the `MusicRemote` protocol), `Infrastructure/SpotifyRemoteAdapter.swift` (the only file importing `SpotifyiOS` 5.0.1), `Infrastructure/KeychainToken.swift`, `Presentation/MusicCard.swift`.
- Card states: not set up, not installed, connect, connecting, connected (playing or paused), dropped ("Resume in Spotify"), reconnect.
- The app switches to Spotify only from a button tap. Opening the card or returning to the foreground makes at most one silent connect. Leaving the foreground disconnects. No polling or timers.
- The access token is kept in the Keychain. The client ID comes from `SPOTIFY_CLIENT_ID` at project generation; without it the card says "Spotify isn't set up in this build".

## Results

- `Executed 105 tests, with 0 failures` / `** TEST SUCCEEDED **` on the iPad (subagent twice, lead once).
- User hand test on the iPad (2026-11-15): connect, track info, next, previous, pause and in-app resume, drop after a pause, "Resume in Spotify", background and return, close. Reported as all working.

## Open issues

- The user wants the artwork integrated into the room's ambience; the current card is a plain system-style overlay. Design not decided.
- The "sign-in expired" case is detected from the wording of Spotify's error and has not been seen on a device.
- Not tried: Spotify not installed, signed out, offline.
- Spotify Development Mode: personal use, Premium owner, at most 5 users.
