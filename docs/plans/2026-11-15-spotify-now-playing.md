# Spotify now-playing (M3b) — design and plan

**Goal:** tapping the monitor opens a small now-playing card that remote-controls the Spotify app. The room never depends on it.

**Spec:** `docs/spec/LOCKED_MVP_SPEC.md` §1.6. **Evidence:** `docs/logs/spotify-spike.md` (connection drops about 30 s after a pause; a silent reconnect fails; authorizing again takes about 1.5 s and resumes at the same position). **Approved by the user on 2026-11-15**, including resume by app switch.

## Design

Card states:

| State | Card shows | Buttons |
|---|---|---|
| `notConfigured` (build has no client ID) | "Spotify isn't set up in this build" | none |
| `notInstalled` | "Spotify isn't installed" | "Get Spotify" (App Store link) |
| `neverConnected` | "Connect Spotify" | Connect (app switch) |
| `connecting` | "Connecting…" | none |
| `connected`, playing | Title, artist, artwork or placeholder | Previous, Pause, Next |
| `connected`, paused | Same | Previous, Play, Next |
| `dropped` | Last track if known, dimmed; else "Spotify is paused" | "Resume in Spotify" (app switch) |
| `needsReconnect` (sign-in cancelled, denied or expired) | "Reconnect Spotify" | Reconnect (app switch) |

Rules:
- An app switch happens only from a button the user taps. Opening the card and returning to the foreground make at most one silent `connect()` each.
- Leaving the foreground disconnects. Nothing is polled; nothing animates while the card is closed.
- The access token is kept in the Keychain so a silent connect can work after a relaunch while Spotify is playing.
- Personal use only (Spotify Development Mode: Premium owner, at most 5 users). The client ID comes from the environment at project generation and is never committed.

Architecture (same shape as weather):
- `Domain/MusicState.swift`: `MusicConnection`, `NowPlaying`, `MusicState` (pure values).
- `Application/MusicController.swift`: all state logic, driven by a `MusicRemote` protocol so tests use a fake.
- `Infrastructure/SpotifyRemoteAdapter.swift`: the only file that imports `SpotifyiOS`; `Infrastructure/KeychainToken.swift`.
- `Presentation/MusicCard.swift`: SwiftUI card; replaces the "Music coming soon" stub in `RoomView`.
- `SceneCoordinator` owns the controller, forwards the computer tap, scene activity and the callback URL.

Approaches considered: Spotify App Remote (chosen: the spec asks for the official iOS integration, and the spike shows the resume hop is short); Spotify Web API (needs a second sign-in flow and polling, and cannot wake a suspended Spotify on the same iPad); Apple Music via MusicKit (no app switch and no 5-user cap, but a different service from the one the spec names).

## Tasks

1. **Logic and tests** — `MusicState`, `MusicRemote`, `MusicController`, `FakeMusicRemote`, `MusicControllerTests`; coordinator wiring (`computerTapped`, `setActive`, `handleCallback(url:)`).
2. **Spotify adapter, Keychain, card UI** — `SpotifyRemoteAdapter`, `KeychainToken`, `MusicCard`, `RoomView` (`onOpenURL`), `project.yml` (package, URL scheme, query scheme, client ID build setting), README setup note.
3. **Device check with the user** — connect, pause, wait for the drop, resume in Spotify, next/previous, background and return. Then docs and log.

Verification: the full suite on the iPad after each task; the rule check for art names; the client ID absent from tracked files.
