import SwiftUI

@main
struct LoFiRoomApp: App {
    var body: some Scene {
        WindowGroup {
            SceneContainer()
                .ignoresSafeArea()
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
                .background(.black)
        }
    }
}
