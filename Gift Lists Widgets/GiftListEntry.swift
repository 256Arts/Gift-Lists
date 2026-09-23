import Foundation
import SwiftData
import WidgetKit

/// One gift, flattened out of the store.
///
/// A timeline entry outlives the `ModelContext` it was built from and is handed to WidgetKit to
/// keep, so the rows carry plain values rather than live `Gift` objects.
struct GiftSnapshot: Identifiable, Hashable {
    let id: UUID
    let title: String
    let price: Double
    /// `nil` for the user's own wishlist, where naming the recipient on every row would just repeat
    /// the widget's title back at them.
    let recipientName: String?
    /// Only set for gifts filed under a birthday, where the countdown is the point.
    let daysUntilBirthday: Int?

    @MainActor
    init(_ gift: Gift) {
        self.id = gift.ensuredIdentifier
        self.title = gift.title ?? ""
        self.price = gift.price ?? 0
        self.recipientName = gift.recipient.flatMap { $0.isMe ? nil : $0.name }
        self.daysUntilBirthday = gift.event?.specialCase == .birthday ? gift.recipient?.daysUntilBirthday : nil
    }

    init(id: UUID = UUID(), title: String, price: Double, recipientName: String? = nil, daysUntilBirthday: Int? = nil) {
        self.id = id
        self.title = title
        self.price = price
        self.recipientName = recipientName
        self.daysUntilBirthday = daysUntilBirthday
    }
}

struct GiftListEntry: TimelineEntry {
    let date: Date
    /// The whole list, in display order. The view takes as many as its family has room for and
    /// counts the rest.
    let gifts: [GiftSnapshot]
    /// Drawn behind a redaction while WidgetKit waits for real data.
    var isPlaceholder = false

    var totalPrice: Double {
        gifts.reduce(0) { $0 + $1.price }
    }
}

/// Which of the app's two lists a widget is showing.
///
/// The two are the same shape — a list of gifts with a count and a total — so they share one view
/// and differ only in what they are called, where they lead, and whether a row can be ticked off.
enum GiftListKind {
    case shopping
    case wishlist

    var title: LocalizedStringResource {
        switch self {
        case .shopping: "Shopping List"
        case .wishlist: "My Wishlist"
        }
    }

    var symbolName: String {
        switch self {
        case .shopping: "list.bullet"
        case .wishlist: "heart"
        }
    }

    /// What an empty list means. "Nothing to buy" is good news; an empty wishlist is a prompt.
    var emptyMessage: LocalizedStringResource {
        switch self {
        case .shopping: "Nothing left to buy"
        case .wishlist: "No gifts on your wishlist"
        }
    }

    var countLabel: LocalizedStringResource {
        switch self {
        case .shopping: "left to buy"
        case .wishlist: "wished for"
        }
    }

    /// Only the shopping list can be ticked off from the widget — a wishlist is a list of things to
    /// be given rather than bought, so there is nothing to mark acquired.
    var allowsMarkingAcquired: Bool {
        self == .shopping
    }

    /// Deep link into the matching tab. Registered as `giftlists://` in the app's Info.plist and
    /// handled in `MainTabView`.
    var url: URL? {
        switch self {
        case .shopping: URL(string: "giftlists://shopping")
        case .wishlist: URL(string: "giftlists://wishlist")
        }
    }

    /// Pulls this list out of `gifts`, using the same rules the app's own tab uses.
    func gifts(from gifts: [Gift]) -> [Gift] {
        switch self {
        case .shopping: gifts.shoppingList()
        case .wishlist: gifts.wishlist
        }
    }
}
