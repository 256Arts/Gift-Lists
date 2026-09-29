import AppIntents
import SwiftData
import CoreTransferable
import CoreSpotlight
import UniformTypeIdentifiers

/// A `Recipient` surfaced to Siri, Spotlight, and Shortcuts.
struct RecipientEntity: IndexedEntity {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Recipient")
    }

    static var defaultQuery = RecipientEntityQuery()

    let id: UUID
    let name: String
    let giftCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: giftCount == 1 ? "1 gift" : "\(giftCount) gifts"
        )
    }

    /// Spotlight metadata so the recipient is findable by name in search.
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .contact)
        attributes.title = name
        attributes.contentDescription = giftCount == 1 ? "1 gift" : "\(giftCount) gifts"
        return attributes
    }

    @MainActor
    init(_ recipient: Recipient) {
        self.id = recipient.ensuredIdentifier
        let name = recipient.name ?? ""
        self.name = name == Recipient.userName ? "Me" : name
        self.giftCount = recipient.gifts?.count ?? 0
    }
}

extension RecipientEntity: Transferable {
    /// Lets Siri/Apple Intelligence carry the on-screen recipient into other apps and chain commands.
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.name)
    }
}

extension Recipient {
    /// Returns the stable App Intents identifier, assigning one to legacy records that predate it.
    @MainActor
    var ensuredIdentifier: UUID {
        if let identifier { return identifier }
        let new = UUID()
        identifier = new
        return new
    }

    @MainActor
    static func model(for id: UUID, in context: ModelContext) -> Recipient? {
        var descriptor = FetchDescriptor<Recipient>(predicate: #Predicate { $0.identifier == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}

struct RecipientEntityQuery: EntityStringQuery {

    @MainActor
    func entities(for identifiers: [UUID]) throws -> [RecipientEntity] {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Recipient>(predicate: #Predicate { recipient in
            if let id = recipient.identifier { identifiers.contains(id) } else { false }
        })
        return try context.fetch(descriptor).map(RecipientEntity.init)
    }

    @MainActor
    func entities(matching string: String) throws -> [RecipientEntity] {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Recipient>(predicate: #Predicate { recipient in
            (recipient.name ?? "").localizedStandardContains(string)
        })
        return try context.fetch(descriptor)
            .filter { !$0.isMe }
            .map(RecipientEntity.init)
    }

    @MainActor
    func suggestedEntities() throws -> [RecipientEntity] {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Recipient>(predicate: #Predicate { $0.name != "<Me>" })
        return try context.fetch(descriptor)
            .sorted(by: .customOrder)
            .map(RecipientEntity.init)
    }
}
