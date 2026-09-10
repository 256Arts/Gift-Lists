import SwiftUI

@main
struct GiftListsWatchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GiftsListTab()
            }
        }
        #if targetEnvironment(simulator)
        // A screenshot run brings its own deterministic seed — the same one the other platforms are
        // shot against — so the watch shots read as the same lists. Other simulator runs keep the
        // preview seed.
        .modelContainer(ScreenshotMode.isActive ? ScreenshotMode.container : previewContainer)
        #else
        .modelContainer(for: [Gift.self, Recipient.self])
        #endif
    }
}
