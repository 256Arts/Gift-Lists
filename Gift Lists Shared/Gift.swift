import SwiftUI
import SwiftData

enum Status: String, Codable, CaseIterable, Identifiable, Sendable {
    case idea, inTransit, acquired, wrapped, given
    
    var title: String {
        switch self {
        case .idea:
            "Idea"
        case .inTransit:
            "In Transit"
        case .acquired:
            "Acquired"
        case .wrapped:
            "Wrapped"
        case .given:
            "Given"
        }
    }

    var localizedTitle: LocalizedStringResource {
        switch self {
        case .idea:
            "Idea"
        case .inTransit:
            "In Transit"
        case .acquired:
            "Acquired"
        case .wrapped:
            "Wrapped"
        case .given:
            "Given"
        }
    }

    var icon: Image {
        switch self {
        case .idea:
            Image(systemName: "lightbulb")
        case .inTransit:
            Image(systemName: "truck.box")
        case .acquired:
            Image(systemName: "house")
        case .wrapped:
            Image(systemName: "gift")
        case .given:
            Image(systemName: "face.smiling")
        }
    }
    
    var id: Self { self }
    
    /// The colour the status icon carries wherever it appears — the gifts list and the widgets.
    var color: Color {
        switch self {
        case .idea:
            Color.secondary
        case .inTransit:
            Color.red
        case .acquired:
            Color.yellow
        case .wrapped:
            Color.green
        case .given:
            Color.purple
        }
    }
    
    var sortPriority: Int {
        switch self {
        case .idea:
            5
        case .inTransit:
            4
        case .acquired:
            3
        case .wrapped:
            2
        case .given:
            1
        }
    }
}

@Model
final class Gift {
    
    /// Stable identifier used to reference this gift from App Intents (Siri, Spotlight, Shortcuts).
    var identifier: UUID?
    var title: String?
    var sortOrder: Int?
    var price: Double?
    var notes: String?
    var recipient: Recipient?
    var event: Event?
    var status: Status?
    
    var amazonURL: URL? {
        guard let title else { return nil }

        let domain = Self.amazonDomains[Locale.autoupdatingCurrent.region?.identifier ?? ""] ?? "com"
        return URL(string: "https://www.amazon.\(domain)/s")!.appending(queryItems: [URLQueryItem(name: "k", value: title)])
    }

    /// Amazon storefront TLD per region. Regions without their own store fall back to `.com`.
    private static let amazonDomains: [String: String] = [
        "AE": "ae", "AT": "de", "AU": "com.au", "BE": "com.be", "BR": "com.br",
        "CA": "ca", "DE": "de", "EG": "eg", "ES": "es", "FR": "fr",
        "GB": "co.uk", "IE": "co.uk", "IN": "in", "IT": "it", "JP": "co.jp",
        "MX": "com.mx", "NL": "nl", "PL": "pl", "SA": "sa", "SE": "se",
        "SG": "sg", "TR": "com.tr",
    ]
    
    init(title: String, sortOrder: Int, price: Double, notes: String? = nil, status: Status = .idea, recipient: Recipient? = nil, event: Event? = nil) {
        self.identifier = UUID()
        self.title = title
        self.sortOrder = sortOrder
        self.price = price
        self.notes = notes
        self.status = status
        self.recipient = recipient
        self.event = event
    }
    
}

extension Gift {

    /// Returns the stable identifier the App Intents and the widgets address a gift by, assigning
    /// one to legacy records that predate it.
    @MainActor
    var ensuredIdentifier: UUID {
        if let identifier { return identifier }
        let new = UUID()
        identifier = new
        return new
    }

    @MainActor
    static func model(for id: UUID, in context: ModelContext) -> Gift? {
        var descriptor = FetchDescriptor<Gift>(predicate: #Predicate { $0.identifier == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

}

extension Gift {

    /// Whether a search query appears in the gift's title, its notes, or its recipient's name.
    ///
    /// The user's own `"<Me>"` sentinel is never matched, so searching "me" doesn't return the
    /// whole wishlist.
    func matches(searchText: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let recipientName = recipient?.isMe == false ? recipient?.name : nil
        return [title, notes, recipientName].contains { $0?.localizedStandardContains(query) == true }
    }

}

extension [Gift] {
    func sorted() -> [Gift] {
        sorted(by: {
            let statusSortPriority0 = ($0.status ?? .idea).sortPriority
            let statusSortPriority1 = ($1.status ?? .idea).sortPriority
            
            if statusSortPriority0 == statusSortPriority1 {
                if (($0.price ?? 0) == ($1.price ?? 0)) {
                    return $0.title?.localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
                } else {
                    return (($0.price ?? 0) > ($1.price ?? 0))
                }
            } else {
                return statusSortPriority0 < statusSortPriority1
            }
        })
    }
}

extension Set<Status> {
    
    /// The statuses as a comma separated list of raw values, so a set can live in `@AppStorage`.
    var storageValue: String {
        Status.allCases.filter({ contains($0) }).map(\.rawValue).joined(separator: ",")
    }
    
    init(storageValue: String) {
        self.init(storageValue.split(separator: ",").compactMap({ Status(rawValue: String($0)) }))
    }
    
}

extension Binding<String> {
    
    /// Whether the gifts list shows `status`, backed by a stored list of the *hidden* statuses.
    ///
    /// Storing what is hidden keeps "given gifts stay out of the way" as the default without
    /// touching anyone's stored setting, and a status added later shows up on its own.
    func showsGiftStatus(_ status: Status) -> Binding<Bool> {
        Binding<Bool> {
            !Set<Status>(storageValue: wrappedValue).contains(status)
        } set: { isShown in
            var hidden = Set<Status>(storageValue: wrappedValue)
            if isShown {
                hidden.remove(status)
            } else {
                hidden.insert(status)
            }
            wrappedValue = hidden.storageValue
        }
    }
    
}

extension [Gift] {

    /// The gifts still to buy for other people, in display order.
    ///
    /// The Shopping List tab and the Shopping List widget both read this, so the two can't drift
    /// apart on what counts as "still to buy" — an idea, and not one on the user's own wishlist,
    /// which is a list of things to be given rather than bought.
    func shoppingList(for event: Event? = nil) -> [Gift] {
        filter { gift in
            gift.status == .idea
                && gift.recipient?.name != Recipient.userName
                && (event == nil || gift.event == event)
        }
        .sorted()
    }

    /// The gifts matching a search query, keeping their order. An empty query matches everything.
    func matching(_ searchText: String) -> [Gift] {
        filter { $0.matches(searchText: searchText) }
    }

    /// The user's own wishlist, in display order.
    var wishlist: [Gift] {
        filter { $0.recipient?.name == Recipient.userName }.sorted()
    }

}
