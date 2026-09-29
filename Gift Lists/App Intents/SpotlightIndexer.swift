import SwiftData
import CoreSpotlight

/// Pushes the app's `IndexedEntity` values into Core Spotlight's on-device index.
///
/// Conforming an entity to `IndexedEntity` only describes *how* to index it —
/// the records must still be donated here so Spotlight and Siri can find a gift,
/// recipient, or event by name. Re-running this is cheap and idempotent: matching
/// identifiers are updated in place, so it's safe to call on every launch.
enum SpotlightIndexer {

    @MainActor
    static func reindexAll() async {
        let context = sharedModelContainer.mainContext
        let index = CSSearchableIndex.default()
        do {
            try await index.indexAppEntities(
                (try context.fetch(FetchDescriptor<Gift>())).map(GiftEntity.init)
            )
            try await index.indexAppEntities(
                (try context.fetch(FetchDescriptor<Recipient>()))
                    .filter { !$0.isMe }
                    .map(RecipientEntity.init)
            )
            try await index.indexAppEntities(
                (try context.fetch(FetchDescriptor<Event>())).map(EventEntity.init)
            )
        } catch {
            print("Spotlight indexing failed: \(error)")
        }
    }
}
