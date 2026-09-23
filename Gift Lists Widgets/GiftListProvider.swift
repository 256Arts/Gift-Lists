import Foundation
import SwiftData
import WidgetKit

/// Reads one of the app's lists out of the shared store and hands it to WidgetKit.
///
/// There is no schedule to speak of: the list only changes when somebody edits it, and both the app
/// (`GiftListsApp`) and the widget's own tick-off button ask WidgetKit to reload when they do. The
/// one thing that moves on its own is the birthday countdown on a row, so the timeline runs to the
/// end of the day and no further.
struct GiftListProvider: TimelineProvider {

    let kind: GiftListKind

    func placeholder(in context: Context) -> GiftListEntry {
        GiftListEntry(date: .now, gifts: GiftListEntry.sample(for: kind).gifts, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (GiftListEntry) -> Void) {
        // The widget gallery has no business showing a real person's gift list, and a fresh install
        // would show it empty besides.
        guard !context.isPreview else {
            completion(GiftListEntry.sample(for: kind))
            return
        }
        Task { @MainActor in
            completion(currentEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GiftListEntry>) -> Void) {
        Task { @MainActor in
            let midnight = Calendar.autoupdatingCurrent.startOfDay(for: .now.addingTimeInterval(24 * 60 * 60))
            completion(Timeline(entries: [currentEntry()], policy: .after(midnight)))
        }
    }

    @MainActor
    private func currentEntry() -> GiftListEntry {
        let gifts = widgetModelContainer?.allGifts()
        #if DEBUG
        // On the simulator the app itself runs on the in-memory preview store, so the one on disk
        // is empty or absent and the widget would have nothing to draw while it is being worked on.
        if gifts?.isEmpty ?? true {
            return GiftListEntry.sample(for: kind)
        }
        #endif
        guard let gifts else {
            // The store could not be opened at all — most likely the app has not run since the
            // update. Sample rows would be a lie, so show the empty state and try again next reload.
            return GiftListEntry(date: .now, gifts: [])
        }
        return GiftListEntry(date: .now, gifts: kind.gifts(from: gifts).map(GiftSnapshot.init))
    }

}

extension GiftListEntry {

    /// What the widget gallery and the Xcode previews show.
    static func sample(for kind: GiftListKind) -> GiftListEntry {
        let gifts: [GiftSnapshot] = switch kind {
        case .shopping:
            [
                GiftSnapshot(title: "Espresso Machine", price: 249, recipientName: "Maya", daysUntilBirthday: 9),
                GiftSnapshot(title: "Snow Boots", price: 175, recipientName: "Chris"),
                GiftSnapshot(title: "Telescope", price: 210, recipientName: "Theo", daysUntilBirthday: 26),
                GiftSnapshot(title: "Hot Cocoa Set", price: 45, recipientName: "Nicholas"),
                GiftSnapshot(title: "Fleece Blanket", price: 95, recipientName: "Holly"),
                GiftSnapshot(title: "Board Game", price: 55, recipientName: "Theo", daysUntilBirthday: 26)
            ]
        case .wishlist:
            [
                GiftSnapshot(title: "Trail Backpack", price: 145),
                GiftSnapshot(title: "Flannel Sheets", price: 120),
                GiftSnapshot(title: "Cashmere Gloves", price: 95),
                GiftSnapshot(title: "Fountain Pen", price: 70),
                GiftSnapshot(title: "Gingerbread Kit", price: 55)
            ]
        }
        return GiftListEntry(date: .now, gifts: gifts)
    }

}
