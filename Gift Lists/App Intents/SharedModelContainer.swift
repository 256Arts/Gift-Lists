import SwiftData

/// The single source of truth for the app's persistent store.
///
/// Both the SwiftUI scene (`GiftListsApp`) and the App Intents that power Siri,
/// Spotlight, and the Shortcuts app read and write through this one container so
/// that a gift added by voice shows up instantly in the UI and vice versa.
@MainActor
let sharedModelContainer: ModelContainer = {
    #if targetEnvironment(simulator) || (os(macOS) && DEBUG)
    return previewContainer
    #else
    return try! ModelContainer(for: Gift.self, Recipient.self, Event.self)
    #endif
}()
