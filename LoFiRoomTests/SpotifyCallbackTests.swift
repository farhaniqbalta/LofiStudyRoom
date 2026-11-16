import XCTest
@testable import LoFiRoom

final class SpotifyCallbackTests: XCTestCase {
    func testOnlyOurRedirectIsACallback() {
        for s in ["lofiroom://spotify-callback?code=x", "lofiroom://spotify-callback#access_token=x"] {
            XCTAssertTrue(SpotifyRemoteAdapter.isCallback(URL(string: s)!), s)
        }
        for s in ["lofiroom://anything", "lofiroom://", "https://spotify-callback", "otherapp://spotify-callback"] {
            XCTAssertFalse(SpotifyRemoteAdapter.isCallback(URL(string: s)!), s)
        }
    }

    func testStaleCoverIsDropped() {
        XCTAssertTrue(MusicArtwork.shouldApply(requested: "a", current: "a", cancelled: false))
        XCTAssertFalse(MusicArtwork.shouldApply(requested: "a", current: "b", cancelled: false))
        XCTAssertFalse(MusicArtwork.shouldApply(requested: "a", current: "a", cancelled: true))
    }
}
