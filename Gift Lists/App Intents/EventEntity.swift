//
//  EventEntity.swift
//  Holiday Gifts List
//
//  Created by Claude on 2026-06-29.
//

import AppIntents
import SwiftData
import CoreTransferable
import CoreSpotlight
import UniformTypeIdentifiers

/// An `Event` (e.g. Birthday, Holidays) surfaced to Siri and Shortcuts.
struct EventEntity: IndexedEntity {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Event")
    }

    static var defaultQuery = EventEntityQuery()

    let id: UUID
    let name: String
    let date: Date?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    /// Spotlight metadata so the event is findable by name (and date) in search.
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = name
        attributes.startDate = date
        return attributes
    }

    @MainActor
    init(_ event: Event) {
        self.id = event.ensuredIdentifier
        self.name = event.name ?? ""
        self.date = event.date
    }
}

extension EventEntity: Transferable {
    /// Lets Siri/Apple Intelligence carry the on-screen event into other apps and chain commands.
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.name)
    }
}

extension Event {
    /// Returns the stable App Intents identifier, assigning one to legacy records that predate it.
    @MainActor
    var ensuredIdentifier: UUID {
        if let identifier { return identifier }
        let new = UUID()
        identifier = new
        return new
    }

    @MainActor
    static func model(for id: UUID, in context: ModelContext) -> Event? {
        var descriptor = FetchDescriptor<Event>(predicate: #Predicate { $0.identifier == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}

struct EventEntityQuery: EntityStringQuery {

    @MainActor
    func entities(for identifiers: [UUID]) throws -> [EventEntity] {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Event>(predicate: #Predicate { event in
            if let id = event.identifier { identifiers.contains(id) } else { false }
        })
        return try context.fetch(descriptor).map(EventEntity.init)
    }

    @MainActor
    func entities(matching string: String) throws -> [EventEntity] {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Event>(predicate: #Predicate { event in
            (event.name ?? "").localizedStandardContains(string)
        })
        return try context.fetch(descriptor).map(EventEntity.init)
    }

    @MainActor
    func suggestedEntities() throws -> [EventEntity] {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Event>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor).map(EventEntity.init)
    }
}
