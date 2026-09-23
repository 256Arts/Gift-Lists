import SwiftData

/// The single source of truth for the app's persistent store.
///
/// The SwiftUI scene (`GiftListsApp`), the App Intents that power Siri, Spotlight, and the
/// Shortcuts app, and — through `GiftListsStore` — the widget extension all read and write through
/// the same store, so a gift added by voice or ticked off from a widget shows up instantly in the
/// UI and vice versa.
@MainActor
let sharedModelContainer: ModelContainer = {
    // A screenshot run gets a throwaway seeded store; every other launch keeps the real one.
    if ScreenshotMode.isActive {
        return ScreenshotMode.container
    }
    #if (targetEnvironment(simulator) || os(macOS)) && DEBUG
    return previewContainer
    #else
    return try! GiftListsStore.makeContainer(copyingLegacyStore: true)
    #endif
}()
