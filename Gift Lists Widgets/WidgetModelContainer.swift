import Foundation
import SwiftData

/// The widgets' handle on the same store the app writes to.
///
/// Built through `GiftListsStore`, like `sharedModelContainer`, so the two processes agree about
/// where the gifts are. Unlike the app's, it does not sync — see `GiftListsStore.Role` — so a gift
/// ticked off from a widget reaches other devices the next time the app runs.
@MainActor
let widgetModelContainer: ModelContainer? = try? GiftListsStore.makeContainer(for: .widget)

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
