import SwiftUI
import WidgetKit

/// What the user has asked for, ready to read out when somebody wants gift ideas.
struct WishlistWidget: Widget {

    static let kind = "WishlistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: GiftListProvider(kind: .wishlist)) { entry in
            GiftListWidgetView(kind: .wishlist, entry: entry)
        }
        .configurationDisplayName("My Wishlist")
        .description("The gifts on your own wishlist, ready when somebody asks.")
        .supportedFamilies(GiftListWidgetFamilies.supported)
    }

}

#Preview("Wishlist — Medium", as: .systemMedium) {
    WishlistWidget()
} timeline: {
    GiftListEntry.sample(for: .wishlist)
}

#Preview("Wishlist — Large", as: .systemLarge) {
    WishlistWidget()
} timeline: {
    GiftListEntry.sample(for: .wishlist)
}

#Preview("Wishlist — Small", as: .systemSmall) {
    WishlistWidget()
} timeline: {
    GiftListEntry.sample(for: .wishlist)
}
