# Spotify App Remote spike

**Status:** Done. Throwaway code on branch `spike/spotify-app-remote`; not merged. The feature (M3b) is not started.
**Date:** 2026-11-15
**Device:** iPad Pro 11-inch (M1), iPadOS 27.0.1, Spotify app installed with Premium. SDK: `SpotifyiOS` 5.0.1 (Swift package).

## What was tested

A debug screen (`-spotifySpike YES`) with Authorize, Connect, Disconnect, Previous, Pause, Resume, Next and a timestamped event log. One run by the user.

## Measurements

| Event | Result |
|---|---|
| First authorize (app switch to Spotify, system "open Spotify?" prompt, approve, return) | 6.3 s from tap to token; connected 0.2 s later |
| Player state after connecting | Arrived at once: playing, track and artist, position |
| Pause command | Acknowledged in 0.04 s |
| Connection after a pause | **Dropped 31.3 s after the pause** (`com.spotify.app-remote -1002 Connection terminated` / transport `-2001 End of stream`), with the test app in the foreground the whole time |
| Resume after the drop | Not possible: no player API |
| `connect()` with the stored token after the drop | **Failed at once** (`-1000 Connection attempt failed` / transport `-2000 Stream error`) |
| Authorize again after the drop | Worked: switch to Spotify and back in 1.5 s with no prompt, connected, **playback resumed at the same position** |

## Conclusions

1. The review report's risk R2 is confirmed on this iPad: about 30 seconds after a pause the connection is gone, and only an app switch brings it back.
2. The app switch is short (about 1.5 s after the first time) and resumes where the track stopped, so a "Resume in Spotify" button is a workable design.
3. A silent reconnect attempt is still worth making first (it costs nothing), but it must not be relied on.
4. Commands and state updates are fast while connected; no polling is needed.

## Not tested

- Resume inside the 30-second window (expected to work in-app).
- Next and Previous.
- A long stretch of continuous playback (does the connection drop while playing?).
- Spotify not installed, signed out, offline, authorization denied.
- Energy cost of holding the connection.

## Setup notes for the feature

- Spotify dashboard: redirect URI `lofiroom://spotify-callback`, bundle ID `com.lofiroom.app`.
- The client ID is not a secret but stays out of the repo: `SPOTIFY_CLIENT_ID` in `CLAUDE.local.md` → build setting → `SpotifyClientID` in the built Info.plist (the tracked `LoFiRoom/Info.plist` holds only `$(SPOTIFY_CLIENT_ID)`).
- Info.plist needs the `lofiroom` URL scheme and `spotify` in `LSApplicationQueriesSchemes`.
- Development Mode: personal use, Premium owner, at most 5 users.
