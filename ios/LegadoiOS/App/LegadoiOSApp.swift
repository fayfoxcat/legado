import SwiftUI

@main
struct LegadoiOSApp: App {
    @StateObject private var library = LibraryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .tint(.orange)
        }
    }
}
