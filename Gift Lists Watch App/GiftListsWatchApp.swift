import SwiftData
import SwiftUI

@main
struct GiftListsWatchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GiftsListTab()
            }
        }
        .modelContainer(modelContainer)
    }

    // A screenshot run brings its own deterministic seed — the same one the other platforms are shot
    // against, in whatever configuration — so the watch shots read as the same lists. Other Debug
    // simulator runs keep the preview seed.
    private let modelContainer: ModelContainer = {
        if ScreenshotMode.isActive {
            return ScreenshotMode.container
        }
        #if targetEnvironment(simulator) && DEBUG
        return previewContainer
        #else
        return try! ModelContainer(for: Gift.self, Recipient.self)
        #endif
    }()
}
