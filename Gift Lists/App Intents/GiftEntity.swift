//
//  GiftEntity.swift
//  Holiday Gifts List
//
//  Created by Claude on 2026-06-29.
//

import AppIntents
import SwiftData
import CoreTransferable
import CoreSpotlight
import UniformTypeIdentifiers

/// A `Gift` surfaced to Siri, Spotlight, and Shortcuts.
struct GiftEntity: IndexedEntity {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Gift")
    }

    static var defaultQuery = GiftEntityQuery()

    let id: UUID
    let title: String
    let price: Double
    let status: Status
    /// Resolved recipient name, with the user's own wishlist normalized to "Me".
    let recipientName: String?

    var displayRepresentation: DisplayRepresentation {
        if let recipientName {
            DisplayRepresentation(title: "\(title)", subtitle: "For \(recipientName)")
        } else {
            DisplayRepresentation(title: "\(title)")
        }
    }

    /// Spotlight metadata so the gift is findable by name and recipient in search.
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = title
        attributes.contentDescription = recipientName.map { "For \($0)" }
        attributes.keywords = [recipientName, status.title].compactMap { $0 }
        return attributes
    }

    @MainActor
    init(_ gift: Gift) {
        self.id = gift.ensuredIdentifier
        self.title = gift.title ?? ""
        self.price = gift.price ?? 0
        self.status = gift.status ?? .idea
        self.recipientName = gift.recipient?.name.map { $0 == Recipient.userName ? "Me" : $0 }
    }
}

extension GiftEntity: Transferable {
    /// A plain-text form so Siri/Apple Intelligence can lift the on-screen gift into other apps
    /// (e.g. "message this gift idea to Mom") and chain commands across apps.
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.transferText)
    }

    var transferText: String {
        recipientName.map { "\(title) for \($0)" } ?? title
    }
}

extension Gift {
    /// Returns the stable App Intents identifier, assigning one to legacy records that predate it.
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

struct GiftEntityQuery: EntityStringQuery {

    @MainActor
    func entities(for identifiers: [UUID]) throws -> [GiftEntity] {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Gift>(predicate: #Predicate { gift in
            if let id = gift.identifier { identifiers.contains(id) } else { false }
        })
        return try context.fetch(descriptor).map(GiftEntity.init)
    }

    @MainActor
    func entities(matching string: String) throws -> [GiftEntity] {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Gift>(predicate: #Predicate { gift in
            (gift.title ?? "").localizedStandardContains(string)
        })
        return try context.fetch(descriptor).map(GiftEntity.init)
    }

    @MainActor
    func suggestedEntities() throws -> [GiftEntity] {
        let context = sharedModelContainer.mainContext
        let gifts = try context.fetch(FetchDescriptor<Gift>())
        return gifts.sorted().map(GiftEntity.init)
    }
}
