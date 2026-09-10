import Foundation
import SwiftData
#if os(macOS)
import AppKit
#endif

/// Deterministic demo state for App Store screenshots, switched on by the `-screenshotMode` launch
/// argument the UI test passes.
///
/// A fresh install has no recipients, so a shot of the gifts list would otherwise be the empty
/// state. The seed lands in an *in-memory* store, so a screenshot run neither shows nor disturbs
/// whatever lists are on the machine taking the shots.
enum ScreenshotMode {

    /// Whether this launch is a screenshot run. Read by `sharedModelContainer` and `GiftListsApp`.
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotMode")
    }

    /// The recipients each shot expands, and the gift the details shot opens. Named here because the
    /// UI test looks them up by accessibility identifier.
    ///
    /// Each event has its own cast, so the two lists share no rows; the pair named for an event leads
    /// it and is the pair the walk opens.
    static let holidayRecipientNames = ["Noelle", "Chris"]
    static let birthdayRecipientNames = ["Maya", "Daniel"]
    /// Sits on Maya's Birthday list, which is what the details shot is taken over.
    static let featuredGiftTitle = "Espresso Machine"
    /// The watch takes its details shot on a different gift. Its list cannot be filtered to an event
    /// — watchOS draws no affordance for the title menu the other platforms filter from — so the
    /// walk photographs the list the user lands on, and the featured gift has to be one already
    /// visible on it rather than one several screens down under a later recipient.
    static let watchFeaturedGiftTitle = "Holiday Sweater"

    /// A throwaway store holding nothing but the seed.
    ///
    /// `cloudKitDatabase: .none` is not optional. In-memory only keeps the seed off disk; without it
    /// SwiftData still picks up the CloudKit container from the app's entitlements and syncs the real
    /// account's recipients and gifts down into the very store the shots are taken from.
    @MainActor
    static let container: ModelContainer = {
        let container = try! ModelContainer(
            for: Gift.self, Recipient.self, Event.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        seed(container.mainContext)
        return container
    }()

    private static let calendar = Calendar(identifier: .gregorian)

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// A birthday that falls `days` from today, in a pinned birth year.
    ///
    /// The Birthday list sorts by nearest birthday, so fixed calendar dates would rotate the
    /// recipients past each other over the year and photograph a different list every season.
    /// Holding the *distance* fixed pins the order — and the "N days left" each row shows — while
    /// the pinned year keeps the recipient's age from drifting.
    private static func upcomingBirthday(in days: Int, bornIn year: Int) -> Date {
        let next = calendar.date(byAdding: .day, value: days, to: .now)!
        var components = calendar.dateComponents([.month, .day], from: next)
        components.year = year
        // February 29th exists in the current year but not in most birth years; the 28th always does.
        if components.month == 2, components.day == 29 {
            components.day = 28
        }
        return calendar.date(from: components)!
    }

    /// Fills `context` with lists worth photographing: enough recipients to fill a tall window, a
    /// spread of statuses so the colored status icons all appear, and unbought ideas so the Shopping
    /// List is not empty either.
    ///
    /// The two special events are inserted here rather than left to `cleanupEvents()`, which would
    /// otherwise create them a second later and make the first shots a race.
    @MainActor
    static func seed(_ context: ModelContext) {
        let birthday = Event(name: "Birthday", date: .distantPast, specialCase: .birthday)
        let holidays = Event(name: "Holidays", date: date(2026, 12, 25), specialCase: .holidays)
        for event in [birthday, holidays] {
            context.insert(event)
        }

        // Each event gets its own cast, so the holiday and birthday shots share no rows: Noelle,
        // Chris, Nicholas and Holly have gifts only for the holidays, Maya, Daniel, Amara and Theo
        // only for the birthdays. `GiftsList` drops a recipient with nothing for the filtered event
        // from the other event's shot in screenshot mode.
        //
        // The holiday cast leads the Gifts tab by creation order; the birthday cast leads the
        // Birthday tab by having the nearest birthdays. Each list's first two are the ones the walk
        // expands.
        let noelle = Recipient(name: holidayRecipientNames[0], sortOrder: 0, birthday: upcomingBirthday(in: 96, bornIn: 1994), spendGoal: 400)
        let chris = Recipient(name: holidayRecipientNames[1], sortOrder: 1, birthday: upcomingBirthday(in: 121, bornIn: 1989), spendGoal: 250)
        let nicholas = Recipient(name: "Nicholas", sortOrder: 2, birthday: upcomingBirthday(in: 68, bornIn: 1997))
        let holly = Recipient(name: "Holly", sortOrder: 3, birthday: upcomingBirthday(in: 196, bornIn: 1992), spendGoal: 200)
        let maya = Recipient(name: birthdayRecipientNames[0], sortOrder: 4, birthday: upcomingBirthday(in: 9, bornIn: 1996), spendGoal: 500)
        let daniel = Recipient(name: birthdayRecipientNames[1], sortOrder: 5, birthday: upcomingBirthday(in: 26, bornIn: 1988), spendGoal: 250)
        let amara = Recipient(name: "Amara", sortOrder: 6, birthday: upcomingBirthday(in: 145, bornIn: 2001), spendGoal: 150)
        let theo = Recipient(name: "Theo", sortOrder: 7, birthday: upcomingBirthday(in: 233, bornIn: 2015))
        let me = Recipient(name: Recipient.userName, sortOrder: -1)
        for recipient in [noelle, chris, nicholas, holly, maya, daniel, amara, theo, me] {
            context.insert(recipient)
        }

        // Order within a recipient is the app's own (status, then price, then name), so these are
        // written in whatever order reads best rather than in display order.
        //
        // The holiday gifts are themed and the birthday ones everyday, so the two list shots read as
        // genuinely different lists rather than one list twice.
        let gifts = [
            // The watch takes its details shot on this one; see watchFeaturedGiftTitle.
            Gift(title: watchFeaturedGiftTitle, sortOrder: 1, price: 65, status: .acquired, recipient: noelle, event: holidays),
            Gift(title: "Ice Skates", sortOrder: 2, price: 180, status: .inTransit, recipient: noelle, event: holidays),
            Gift(title: "Spiced Candle Set", sortOrder: 3, price: 90, status: .idea, recipient: noelle, event: holidays),
            Gift(title: "iPad", sortOrder: 4, price: 349, status: .idea, recipient: noelle, event: holidays),

            Gift(title: "Wool Peacoat", sortOrder: 5, price: 140, status: .wrapped, recipient: chris, event: holidays),
            Gift(title: "Peppermint Bark Box", sortOrder: 6, price: 35, status: .acquired, recipient: chris, event: holidays),
            Gift(title: "Snow Boots", sortOrder: 7, price: 175, status: .idea, recipient: chris, event: holidays),

            Gift(title: "Snowboard", sortOrder: 8, price: 349, status: .inTransit, recipient: nicholas, event: holidays),
            Gift(title: "Advent Calendar", sortOrder: 9, price: 80, status: .acquired, recipient: nicholas, event: holidays),
            Gift(title: "Hot Cocoa Set", sortOrder: 10, price: 45, status: .idea, recipient: nicholas, event: holidays),

            Gift(title: "Ornament Set", sortOrder: 11, price: 60, status: .wrapped, recipient: holly, event: holidays),
            Gift(title: "Cashmere Scarf", sortOrder: 12, price: 85, status: .acquired, recipient: holly, event: holidays),
            Gift(title: "Fleece Blanket", sortOrder: 13, price: 95, status: .idea, recipient: holly, event: holidays),

            // The Birthday list carries two of the four shots, so it is stocked as deeply as the
            // holiday one. The featured gift has notes because the details shot is taken on it.
            Gift(title: featuredGiftTitle, sortOrder: 14, price: 249, notes: "Matte black, with the built-in burr grinder.", status: .acquired, recipient: maya, event: birthday),
            Gift(title: "Running Shoes", sortOrder: 15, price: 150, status: .inTransit, recipient: maya, event: birthday),
            Gift(title: "Concert Tickets", sortOrder: 16, price: 220, status: .idea, recipient: maya, event: birthday),

            Gift(title: "Chef's Knife", sortOrder: 17, price: 110, status: .wrapped, recipient: daniel, event: birthday),
            Gift(title: "Cookbook", sortOrder: 18, price: 40, status: .acquired, recipient: daniel, event: birthday),
            Gift(title: "Leather Wallet", sortOrder: 19, price: 85, status: .idea, recipient: daniel, event: birthday),

            Gift(title: "Watercolour Set", sortOrder: 20, price: 60, status: .wrapped, recipient: amara, event: birthday),
            Gift(title: "Bluetooth Speaker", sortOrder: 21, price: 120, status: .acquired, recipient: amara, event: birthday),
            Gift(title: "Sketchbook Set", sortOrder: 22, price: 45, status: .idea, recipient: amara, event: birthday),

            Gift(title: "LEGO Space Station", sortOrder: 23, price: 120, status: .acquired, recipient: theo, event: birthday),
            Gift(title: "Telescope", sortOrder: 24, price: 210, status: .idea, recipient: theo, event: birthday),
            Gift(title: "Board Game", sortOrder: 25, price: 55, status: .idea, recipient: theo, event: birthday),

            // The wishlist tab reads these, and the Shopping List deliberately excludes them.
            Gift(title: "Cashmere Gloves", sortOrder: 26, price: 95, status: .idea, recipient: me, event: holidays),
            Gift(title: "Gingerbread Kit", sortOrder: 27, price: 55, status: .idea, recipient: me, event: holidays),
            Gift(title: "Flannel Sheets", sortOrder: 28, price: 120, status: .idea, recipient: me, event: holidays),
            Gift(title: "Trail Backpack", sortOrder: 29, price: 145, status: .idea, recipient: me, event: birthday),
            Gift(title: "Fountain Pen", sortOrder: 30, price: 70, status: .idea, recipient: me, event: birthday)
        ]
        for gift in gifts {
            context.insert(gift)
        }
    }
}

#if os(macOS)
extension ScreenshotMode {

    /// Widens the sidebar so no tab title truncates, for screenshot runs only.
    ///
    /// The width is otherwise whatever the user last dragged it to, and the shared runner cannot
    /// reset it the way it resets the window frame: the app is sandboxed, so its saved state lives in
    /// a container the script has no access to. SwiftUI offers no hold on it either — a
    /// sidebar-adaptable `TabView` ignores `navigationSplitViewColumnWidth`, and a wide
    /// `tabViewSidebarHeader` only adds vertical space — so this reaches for the AppKit split view
    /// the style is built on. Retried because the split view is not installed at first draw.
    @MainActor
    static func pinSidebarWidth(_ width: CGFloat = 200) async {
        guard isActive else { return }

        for _ in 0..<20 {
            for window in NSApplication.shared.windows {
                guard let controller = window.contentViewController?.splitViewController,
                      let sidebar = controller.splitViewItems.first else { continue }
                sidebar.minimumThickness = width
                sidebar.maximumThickness = width
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}

private extension NSViewController {

    /// The split view controller behind `.sidebarAdaptable`, wherever SwiftUI has hung it.
    var splitViewController: NSSplitViewController? {
        if let controller = self as? NSSplitViewController { return controller }
        for child in children {
            if let found = child.splitViewController { return found }
        }
        return nil
    }
}
#endif
