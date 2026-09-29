import SwiftUI
import WidgetKit

/// Everything still to buy, across every event, with a tick-off button on each row.
struct ShoppingWidget: Widget {

    static let kind = "ShoppingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: GiftListProvider(kind: .shopping)) { entry in
            GiftListWidgetView(kind: .shopping, entry: entry)
        }
        .configurationDisplayName("Shopping List")
        .description("Gifts you still have to buy. Tick one off without opening the app.")
        .supportedFamilies(GiftListWidgetFamilies.supported)
    }

}

/// The families both widgets offer, kept in one place so they cannot drift apart.
///
/// Home Screen sizes only. A gift list is private enough that it has no business on a Lock Screen,
/// where it would be readable without unlocking the phone — the app's own biometric lock exists for
/// the same reason.
enum GiftListWidgetFamilies {
    static let supported: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]
}

#Preview("Shopping — Medium", as: .systemMedium) {
    ShoppingWidget()
} timeline: {
    GiftListEntry.sample(for: .shopping)
}

#Preview("Shopping — Large", as: .systemLarge) {
    ShoppingWidget()
} timeline: {
    GiftListEntry.sample(for: .shopping)
}

#Preview("Shopping — Small", as: .systemSmall) {
    ShoppingWidget()
} timeline: {
    GiftListEntry.sample(for: .shopping)
}

#Preview("Shopping — Empty", as: .systemMedium) {
    ShoppingWidget()
} timeline: {
    GiftListEntry(date: .now, gifts: [])
}
