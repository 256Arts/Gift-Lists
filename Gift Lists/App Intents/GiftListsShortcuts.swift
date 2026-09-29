import AppIntents

/// Registers the app's intents with Siri, Spotlight, and the Shortcuts app,
/// each with natural-language phrases for invocation.
struct GiftListsShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddGiftIntent(),
            phrases: [
                "Add a gift to \(.applicationName)",
                "Add a gift in \(.applicationName)",
                "New gift in \(.applicationName)"
            ],
            shortTitle: "Add Gift",
            systemImageName: "gift"
        )
        AppShortcut(
            intent: AddRecipientIntent(),
            phrases: [
                "Add a recipient to \(.applicationName)",
                "Add a person to \(.applicationName)"
            ],
            shortTitle: "Add Recipient",
            systemImageName: "person.badge.plus"
        )
        AppShortcut(
            intent: MarkGiftStatusIntent(),
            phrases: [
                "Change a gift's status in \(.applicationName)",
                "Update a gift in \(.applicationName)"
            ],
            shortTitle: "Change Gift Status",
            systemImageName: "checkmark.circle"
        )
    }
}
