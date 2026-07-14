import AppIntents
import SwiftData

/// Adds a new gift to the list, optionally tied to a recipient and event.
struct AddGiftIntent: AppIntent {

    static var title: LocalizedStringResource = "Add Gift"
    static var description = IntentDescription("Adds a new gift idea to your list.")

    @Parameter(title: "Title", requestValueDialog: "What gift would you like to add?")
    var title: String

    @Parameter(title: "Recipient")
    var recipient: RecipientEntity?

    @Parameter(title: "Event")
    var event: EventEntity?

    @Parameter(title: "Price")
    var price: Double?

    @Parameter(title: "Status", default: .idea)
    var status: Status

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) for \(\.$recipient)") {
            \.$event
            \.$price
            \.$status
        }
    }

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<GiftEntity> & ProvidesDialog {
        let context = sharedModelContainer.mainContext

        let recipientModel = recipient.flatMap { Recipient.model(for: $0.id, in: context) }
        let eventModel = event.flatMap { Event.model(for: $0.id, in: context) }

        let existing = (try? context.fetch(FetchDescriptor<Gift>())) ?? []
        let nextSortOrder = (existing.compactMap(\.sortOrder).max() ?? -1) + 1

        let gift = Gift(
            title: title,
            sortOrder: nextSortOrder,
            price: price ?? 0,
            status: status,
            recipient: recipientModel,
            event: eventModel
        )
        context.insert(gift)
        try context.save()

        // Keep the review-prompt threshold (ExperienceManager) in sync with gifts created in-app.
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: UserDefaults.Key.giftsCreatedCount) + 1, forKey: UserDefaults.Key.giftsCreatedCount)

        let dialog: IntentDialog = if let name = recipientModel?.name, name != Recipient.userName {
            "Added \(title) for \(name)."
        } else {
            "Added \(title) to your gift list."
        }
        return .result(value: GiftEntity(gift), dialog: dialog)
    }
}
