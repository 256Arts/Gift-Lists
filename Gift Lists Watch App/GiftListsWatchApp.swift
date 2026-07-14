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
        .modelContainer(previewContainer)
        #else
        .modelContainer(for: [Gift.self, Recipient.self])
        #endif
    }
}
