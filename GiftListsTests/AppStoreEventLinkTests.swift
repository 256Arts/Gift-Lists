import Foundation
import Testing

struct AppStoreEventLinkTests {

    @Test func parsesTitleAndDestination() throws {
        let url = URL(string: "https://www.256arts.com/giftlists/appstoreevent?title=Fall%20Giving&destination=wishlist")!
        let link = try #require(AppStoreEventLink(url: url))

        #expect(link.title == "Fall Giving")
        #expect(link.destination == .wishlist)
    }

    @Test func barePathHasNoTitleOrDestination() throws {
        let url = URL(string: "https://www.256arts.com/giftlists/appstoreevent")!
        let link = try #require(AppStoreEventLink(url: url))

        #expect(link.title == nil)
        #expect(link.destination == nil)
    }

    @Test func unknownDestinationFallsBackToNilRatherThanFailing() throws {
        let url = URL(string: "https://www.256arts.com/giftlists/appstoreevent?destination=somethingNew")!
        let link = try #require(AppStoreEventLink(url: url))

        #expect(link.destination == nil)
    }

    @Test func duplicateParamsKeepTheLastOne() throws {
        let url = URL(string: "https://www.256arts.com/giftlists/appstoreevent?destination=gifts&destination=shopping&title=A&title=B")!
        let link = try #require(AppStoreEventLink(url: url))

        #expect(link.destination == .shopping)
        #expect(link.title == "B")
    }

    @Test func blankTitleIsNilNotEmptyString() throws {
        let url = URL(string: "https://www.256arts.com/giftlists/appstoreevent?title=%20&destination=shopping")!
        let link = try #require(AppStoreEventLink(url: url))

        #expect(link.title == nil)
        #expect(link.destination == .shopping)
    }

    @Test func wrongDomainIsRejected() {
        let url = URL(string: "https://evil.example.com/giftlists/appstoreevent?destination=wishlist")!

        #expect(AppStoreEventLink(url: url) == nil)
    }

    @Test func wrongPathIsRejected() {
        let url = URL(string: "https://www.256arts.com/giftlists/somethingElse?destination=wishlist")!

        #expect(AppStoreEventLink(url: url) == nil)
    }

    @Test func unrelatedURLIsRejected() {
        let url = URL(string: "giftlists://wishlist")!

        #expect(AppStoreEventLink(url: url) == nil)
    }

}
