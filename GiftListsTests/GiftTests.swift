import Foundation
import SwiftData
import Testing

/// An in-memory store, so relationships behave as they do in the app and nothing touches disk.
///
/// Suites hold on to it: a context outlived by its container crashes on the next insert.
func makeContainer() throws -> ModelContainer {
    try ModelContainer(
        for: Gift.self, Recipient.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

@MainActor
struct GiftSortTests {

    let container: ModelContainer

    init() throws {
        container = try makeContainer()
    }

    @Test func statusComesFirstThenPriceThenTitle() throws {
        let gifts = [
            Gift(title: "Given", sortOrder: 0, price: 500, status: .given),
            Gift(title: "banana", sortOrder: 1, price: 10),
            Gift(title: "Apple", sortOrder: 2, price: 10),
            Gift(title: "Pricey idea", sortOrder: 3, price: 99),
            Gift(title: "Wrapped", sortOrder: 4, price: 1, status: .wrapped),
            Gift(title: "Shipping", sortOrder: 5, price: 1, status: .inTransit),
        ]
        gifts.forEach(container.mainContext.insert)

        #expect(gifts.sorted().map(\.title) == ["Given", "Wrapped", "Shipping", "Pricey idea", "Apple", "banana"])
    }

    @Test func missingStatusAndPriceSortAsIdeaAndZero() throws {
        let legacy = Gift(title: "Legacy", sortOrder: 0, price: 0)
        legacy.status = nil
        legacy.price = nil
        let cheap = Gift(title: "Cheap", sortOrder: 1, price: 1)
        [legacy, cheap].forEach(container.mainContext.insert)

        #expect([legacy, cheap].sorted().map(\.title) == ["Cheap", "Legacy"])
    }

}

@MainActor
struct GiftListTests {

    let container: ModelContainer

    init() throws {
        container = try makeContainer()
    }

    @Test func shoppingListHoldsOnlyIdeasForOtherPeople() throws {
        let me = Recipient(name: Recipient.userName, sortOrder: 0)
        let friend = Recipient(name: "Sam", sortOrder: 1)
        let holidays = Event(name: "Holidays", date: nil, specialCase: .holidays)
        let birthday = Event(name: "Birthday", date: nil, specialCase: .birthday)
        let gifts = [
            Gift(title: "Book", sortOrder: 0, price: 20, recipient: friend, event: holidays),
            Gift(title: "Scarf", sortOrder: 1, price: 30, recipient: friend, event: birthday),
            Gift(title: "Bought", sortOrder: 2, price: 40, status: .acquired, recipient: friend, event: holidays),
            Gift(title: "Wish", sortOrder: 3, price: 50, recipient: me, event: holidays),
            Gift(title: "Unassigned", sortOrder: 4, price: 5),
        ]
        [me, friend].forEach(container.mainContext.insert)
        [holidays, birthday].forEach(container.mainContext.insert)
        gifts.forEach(container.mainContext.insert)

        #expect(gifts.shoppingList().map(\.title) == ["Scarf", "Book", "Unassigned"])
        #expect(gifts.shoppingList(for: holidays).map(\.title) == ["Book"])
        #expect(gifts.wishlist.map(\.title) == ["Wish"])
    }

    @Test func searchMatchesTitleNotesAndRecipientButNotMe() throws {
        let me = Recipient(name: Recipient.userName, sortOrder: 0)
        let friend = Recipient(name: "Jordan", sortOrder: 1)
        let gifts = [
            Gift(title: "Headphones", sortOrder: 0, price: 0, recipient: me),
            Gift(title: "Mug", sortOrder: 1, price: 0, notes: "Blue glaze", recipient: friend),
        ]
        [me, friend].forEach(container.mainContext.insert)
        gifts.forEach(container.mainContext.insert)

        #expect(gifts.matching("  ").count == 2)
        #expect(gifts.matching("phones").map(\.title) == ["Headphones"])
        #expect(gifts.matching("GLAZE").map(\.title) == ["Mug"])
        #expect(gifts.matching("jordan").map(\.title) == ["Mug"])
        #expect(gifts.matching("Me").isEmpty)
    }

    @Test func amazonURLSearchesForTheTitle() throws {
        let gift = Gift(title: "Lego & Friends", sortOrder: 0, price: 0)
        let components = try #require(gift.amazonURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })

        #expect(components.host?.hasPrefix("www.amazon.") == true)
        #expect(components.path == "/s")
        #expect(components.queryItems == [URLQueryItem(name: "k", value: "Lego & Friends")])

        gift.title = nil
        #expect(gift.amazonURL == nil)
    }

}

struct StatusStorageTests {

    @Test(arguments: [Set<Status>(), [.given], [.idea, .wrapped], Set(Status.allCases)])
    func storageValueRoundTrips(statuses: Set<Status>) {
        #expect(Set<Status>(storageValue: statuses.storageValue) == statuses)
    }

    @Test func storageValueIsOrderedAndIgnoresUnknownValues() {
        #expect(Set<Status>([.given, .idea]).storageValue == "idea,given")
        #expect(Set<Status>(storageValue: "given,bogus,,idea") == [.idea, .given])
    }

}
