import AppIntents
import SwiftData
import WidgetKit

/// Ticks a gift off the Shopping List widget without opening the app.
///
/// The app already has `MarkGiftStatusIntent` for Siri and Shortcuts, but that one takes a
/// `GiftEntity` — a Spotlight-indexed, transferable thing that only makes sense inside the app.
/// A widget button needs nothing but the identifier under the row it is drawn in.
struct MarkGiftAcquiredIntent: AppIntent {

    static var title: LocalizedStringResource = "Mark Gift Acquired"
    /// It is a button on a widget, not something to offer in the Shortcuts editor — the app's own
    /// "Change Gift Status" action covers that, with every status to choose from.
    static var isDiscoverable = false

    @Parameter(title: "Gift")
    var giftID: String

    init() {}

    init(gift: GiftSnapshot) {
        self.giftID = gift.id.uuidString
    }

    @MainActor
    func perform() throws -> some IntentResult {
        guard let id = UUID(uuidString: giftID),
              let container = widgetModelContainer,
              let gift = Gift.model(for: id, in: container.mainContext) else {
            // The gift was deleted between the timeline being written and the button being pressed.
            // Reloading is all there is to do — the row is about to disappear anyway.
            WidgetCenter.shared.reloadAllTimelines()
            return .result()
        }

        gift.status = .acquired
        try container.mainContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }

}
