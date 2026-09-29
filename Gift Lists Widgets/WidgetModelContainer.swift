import Foundation
import SwiftData

/// The widgets' handle on the same store the app writes to.
///
/// Built exactly the way `sharedModelContainer` builds the app's, through `GiftListsStore`, so the
/// two processes agree about where the gifts are and how the store is configured — including
/// CloudKit, so a gift ticked off from a widget reaches the other devices without waiting for the
/// app to be opened.
@MainActor
let widgetModelContainer: ModelContainer? = try? GiftListsStore.makeContainer()

extension ModelContainer {

    /// Every gift in the store, in no particular order, or `nil` if the store could not be read.
    ///
    /// A widget refresh that cannot reach the store should show what it showed last rather than an
    /// empty list — "you have nothing left to buy" is a worse lie than a stale row.
    @MainActor
    func allGifts() -> [Gift]? {
        try? mainContext.fetch(FetchDescriptor<Gift>())
    }

}
