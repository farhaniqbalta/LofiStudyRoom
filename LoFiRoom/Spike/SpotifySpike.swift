// THROWAWAY SPIKE: measures how Spotify's App Remote behaves on the iPad. Not the feature; delete after the test.
// Launch with `-spotifySpike YES`. Every event is shown on screen and appended to Documents/spotify-spike.log.
@preconcurrency import SpotifyiOS
import SwiftUI

@MainActor
final class SpotifySpike: NSObject, ObservableObject, @preconcurrency SPTAppRemoteDelegate, @preconcurrency SPTAppRemotePlayerStateDelegate {
    @Published var lines: [String] = []
    @Published var connected = false
    @Published var track = "-"
    @Published var paused = true

    private let remote: SPTAppRemote
    private let start = Date()
    private var pausedAt: Date?
    private var disconnectedAt: Date?
    private let logURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("spotify-spike.log")

    override init() {
        let clientID = Bundle.main.object(forInfoDictionaryKey: "SpotifyClientID") as? String ?? ""
        let configuration = SPTConfiguration(clientID: clientID, redirectURL: URL(string: "lofiroom://spotify-callback")!)
        remote = SPTAppRemote(configuration: configuration, logLevel: .info)
        super.init()
        remote.delegate = self
        log("spike started; client id present: \(!clientID.isEmpty); spotify installed: \(UIApplication.shared.canOpenURL(URL(string: "spotify:")!))")
    }

    func log(_ text: String) {
        let line = String(format: "%7.1fs  %@  %@", Date().timeIntervalSince(start), Date().formatted(date: .omitted, time: .standard), text)
        lines.append(line)
        let data = Data((line + "\n").utf8)
        if let handle = try? FileHandle(forWritingTo: logURL) {
            handle.seekToEndOfFile(); handle.write(data); try? handle.close()
        } else {
            try? data.write(to: logURL)
        }
    }

    // Actions
    func authorize() { log("authorizeAndPlayURI (app switch)"); remote.authorizeAndPlayURI("") { ok in Task { @MainActor in self.log("authorize opened Spotify: \(ok)") } } }
    func connect() { log("connect() with stored token: \(remote.connectionParameters.accessToken != nil)"); remote.connect() }
    func disconnect() { log("disconnect()"); remote.disconnect() }
    func pause() { command("pause") { $0.pause($1) } }
    func resume() { command("resume") { $0.resume($1) } }
    func next() { command("next") { $0.skip(toNext: $1) } }
    func previous() { command("previous") { $0.skip(toPrevious: $1) } }

    private func command(_ name: String, _ run: (SPTAppRemotePlayerAPI, @escaping SPTAppRemoteCallback) -> Void) {
        guard let api = remote.playerAPI else { return log("\(name): no player API (not connected)") }
        let sent = Date()
        run(api) { _, error in
            Task { @MainActor in
                self.log("\(name) -> \(error.map { "ERROR \($0.localizedDescription)" } ?? "ok") after \(String(format: "%.2f", Date().timeIntervalSince(sent)))s")
            }
        }
    }

    func handle(url: URL) {
        let parameters = remote.authorizationParameters(from: url)
        if let token = parameters?[SPTAppRemoteAccessTokenKey] {
            remote.connectionParameters.accessToken = token
            log("callback: got access token (\(token.count) chars)")
            remote.connect()
        } else {
            log("callback: no token; error: \(parameters?[SPTAppRemoteErrorDescriptionKey] ?? "none") url: \(url.absoluteString.prefix(80))")
        }
    }

    func scenePhase(_ phase: ScenePhase) {
        log("scene phase: \(phase)")
        if phase == .active, !remote.isConnected, remote.connectionParameters.accessToken != nil {
            log("foreground with a token and no connection: trying connect()")
            remote.connect()
        }
    }

    // SPTAppRemoteDelegate
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        connected = true
        log("CONNECTED" + (disconnectedAt.map { String(format: " (%.1fs after the last disconnect)", Date().timeIntervalSince($0)) } ?? ""))
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe { _, error in
            Task { @MainActor in self.log("subscribe to player state -> \(error.map { "ERROR \($0.localizedDescription)" } ?? "ok")") }
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        connected = false
        log("CONNECT FAILED: \(describe(error))")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        connected = false
        disconnectedAt = Date()
        log("DISCONNECTED: \(describe(error))" + (pausedAt.map { String(format: " — %.1fs after the last pause", Date().timeIntervalSince($0)) } ?? ""))
    }

    // SPTAppRemotePlayerStateDelegate
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        if playerState.isPaused, !paused { pausedAt = Date() }
        if !playerState.isPaused { pausedAt = nil }
        paused = playerState.isPaused
        track = "\(playerState.track.name) — \(playerState.track.artist.name)"
        log("state: \(playerState.isPaused ? "PAUSED" : "PLAYING") \(track) @\(playerState.playbackPosition / 1000)s")
    }

    private func describe(_ error: Error?) -> String {
        guard let error = error as NSError? else { return "no error" }
        let underlying = (error.userInfo[NSUnderlyingErrorKey] as? NSError).map { " / underlying: \($0.domain) \($0.code) \($0.localizedDescription)" } ?? ""
        return "\(error.domain) \(error.code) \(error.localizedDescription)\(underlying)"
    }
}

struct SpotifySpikeView: View {
    @StateObject private var spike = SpotifySpike()
    @Environment(\.scenePhase) private var phase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spotify App Remote spike").font(.title2.bold())
            Text("\(spike.connected ? "CONNECTED" : "not connected") · \(spike.paused ? "paused" : "playing") · \(spike.track)")
            HStack {
                Button("1 Authorize + play") { spike.authorize() }
                Button("Connect") { spike.connect() }
                Button("Disconnect") { spike.disconnect() }
            }
            HStack {
                Button("Previous") { spike.previous() }
                Button("Pause") { spike.pause() }
                Button("Resume") { spike.resume() }
                Button("Next") { spike.next() }
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(spike.lines.enumerated()), id: \.offset) { index, line in
                            Text(line).font(.system(size: 13, design: .monospaced)).id(index)
                        }
                    }
                }
                .onChange(of: spike.lines.count) { _, count in proxy.scrollTo(count - 1) }
            }
        }
        .buttonStyle(.borderedProminent)
        .padding(24)
        .onOpenURL { spike.handle(url: $0) }
        .onChange(of: phase) { _, new in spike.scenePhase(new) }
    }
}
