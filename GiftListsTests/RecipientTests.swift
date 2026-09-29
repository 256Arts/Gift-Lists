import Foundation
import SwiftData
import Testing

@MainActor
struct RecipientBirthdayTests {

    let calendar = Calendar.autoupdatingCurrent

    /// `years` ago, shifted by `days`. Multiples of four years keep a Feb 29 today from landing on
    /// a non-leap year.
    func date(yearsAgo years: Int, days: Int = 0) -> Date {
        let shifted = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: .now))!
        return calendar.date(byAdding: .year, value: -years, to: shifted)!
    }

    @Test func birthdayTodayIsZeroDaysAway() {
        let recipient = Recipient(name: "Today", sortOrder: 0, birthday: date(yearsAgo: 28))

        #expect(recipient.daysUntilBirthday == 0)
        #expect(recipient.age == 28)
        #expect(recipient.nextBirthday.map(calendar.isDateInToday) == true)
    }

    @Test func birthdayTomorrowIsOneDayAwayAndNotYetCounted() {
        let recipient = Recipient(name: "Tomorrow", sortOrder: 0, birthday: date(yearsAgo: 12, days: 1))

        #expect(recipient.daysUntilBirthday == 1)
        #expect(recipient.age == 11)
    }

    @Test func birthdayYesterdayIsNearlyAYearAway() throws {
        let recipient = Recipient(name: "Yesterday", sortOrder: 0, birthday: date(yearsAgo: 32, days: -1))

        let days = try #require(recipient.daysUntilBirthday)
        #expect((363...365).contains(days))
        #expect(recipient.age == 32)
    }

    @Test func leapDayBirthdayStillHasANextBirthday() throws {
        let leapDay = try #require(calendar.date(from: DateComponents(year: 2000, month: 2, day: 29)))
        let recipient = Recipient(name: "Leap", sortOrder: 0, birthday: leapDay)

        let next = try #require(recipient.nextBirthday)
        let components = calendar.dateComponents([.month, .day], from: next)
        #expect([DateComponents(month: 2, day: 29), DateComponents(month: 3, day: 1)].contains(components))
        #expect(try #require(recipient.daysUntilBirthday) <= 366)
    }

    @Test func noBirthdayMeansNoBirthdayInfo() {
        let recipient = Recipient(name: "Unknown", sortOrder: 0)

        #expect(recipient.nextBirthday == nil)
        #expect(recipient.daysUntilBirthday == nil)
        #expect(recipient.age == nil)
    }

    @Test func meIsTheUserSentinel() {
        #expect(Recipient(name: Recipient.userName, sortOrder: 0).isMe)
        #expect(!Recipient(name: "Me", sortOrder: 0).isMe)
    }

}

@MainActor
struct RecipientSortTests {

    let container: ModelContainer

    init() throws {
        container = try makeContainer()
    }

    let calendar = Calendar.autoupdatingCurrent

    func birthday(inDays days: Int) -> Date {
        let shifted = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: .now))!
        return calendar.date(byAdding: .year, value: -20, to: shifted)!
    }

    @Test func alphabeticalIgnoresCase() throws {
        let recipients = [
            Recipient(name: "charlie", sortOrder: 0),
            Recipient(name: "Alex", sortOrder: 1),
            Recipient(name: "blake", sortOrder: 2),
        ]
        recipients.forEach(container.mainContext.insert)

        #expect(recipients.sorted(by: .alphabetical).map(\.name) == ["Alex", "blake", "charlie"])
    }

    @Test func nearestBirthdayPutsUnknownBirthdaysLastAndTiesByName() throws {
        let recipients = [
            Recipient(name: "No Birthday", sortOrder: 0),
            Recipient(name: "Later", sortOrder: 1, birthday: birthday(inDays: 40)),
            Recipient(name: "Soon B", sortOrder: 2, birthday: birthday(inDays: 3)),
            Recipient(name: "Soon A", sortOrder: 3, birthday: birthday(inDays: 3)),
        ]
        recipients.forEach(container.mainContext.insert)

        #expect(recipients.sorted(by: .nearestBirthday).map(\.name) == ["Soon A", "Soon B", "Later", "No Birthday"])
    }

    @Test func customOrderFollowsSortOrder() throws {
        let recipients = [
            Recipient(name: "Third", sortOrder: 2),
            Recipient(name: "First", sortOrder: 0),
            Recipient(name: "Second", sortOrder: 1),
        ]
        recipients.forEach(container.mainContext.insert)

        #expect(recipients.sorted(by: .customOrder).map(\.name) == ["First", "Second", "Third"])
    }

}
