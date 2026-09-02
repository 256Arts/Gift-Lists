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

    /// The recipient the shots expand, and the gift they open. Named here because the UI test looks
    /// them up by accessibility identifier.
    static let featuredRecipientName = "Noelle"
    static let featuredGiftTitle = "Espresso Machine"

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

    /// Birthdays are pinned to real years so a recipient's age does not drift between runs. The
    /// holiday countdown counts to the next December 25th and so still moves with the calendar.
    private static let calendar = Calendar(identifier: .gregorian)

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
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

        let noelle = Recipient(name: featuredRecipientName, sortOrder: 0, birthday: date(1994, 7, 14), spendGoal: 400)
        let chris = Recipient(name: "Chris", sortOrder: 1, birthday: date(1989, 12, 25), spendGoal: 250)
        let nicholas = Recipient(name: "Nicholas", sortOrder: 2, birthday: date(1997, 3, 6))
        let amara = Recipient(name: "Amara", sortOrder: 3, birthday: date(2001, 9, 2), spendGoal: 150)
        let theo = Recipient(name: "Theo", sortOrder: 4, birthday: date(2015, 5, 20))
        let me = Recipient(name: Recipient.userName, sortOrder: -1)
        for recipient in [noelle, chris, nicholas, amara, theo, me] {
            context.insert(recipient)
        }

        // Order within a recipient is the app's own (status, then price, then name), so these are
        // written in whatever order reads best rather than in display order.
        let gifts = [
            Gift(title: featuredGiftTitle, sortOrder: 0, price: 249, status: .wrapped, recipient: noelle, event: holidays),
            Gift(title: "Wool Scarf", sortOrder: 1, price: 65, status: .acquired, recipient: noelle, event: holidays),
            Gift(title: "Film Camera", sortOrder: 2, price: 180, status: .inTransit, recipient: noelle, event: holidays),
            Gift(title: "Pottery Class", sortOrder: 3, price: 90, status: .idea, recipient: noelle, event: holidays),

            Gift(title: "Chef's Knife", sortOrder: 4, price: 140, status: .wrapped, recipient: chris, event: holidays),
            Gift(title: "Vinyl Record", sortOrder: 5, price: 35, status: .acquired, recipient: chris, event: holidays),
            Gift(title: "Hiking Boots", sortOrder: 6, price: 175, status: .idea, recipient: chris, event: holidays),

            Gift(title: "Noise Cancelling Headphones", sortOrder: 7, price: 349, status: .inTransit, recipient: nicholas, event: holidays),
            Gift(title: "Desk Lamp", sortOrder: 8, price: 80, status: .acquired, recipient: nicholas, event: holidays),
            Gift(title: "Cast Iron Skillet", sortOrder: 9, price: 45, status: .idea, recipient: nicholas, event: holidays),

            Gift(title: "Watercolour Set", sortOrder: 10, price: 60, status: .wrapped, recipient: amara, event: holidays),
            Gift(title: "Weighted Blanket", sortOrder: 11, price: 95, status: .idea, recipient: amara, event: holidays),

            Gift(title: "LEGO Space Station", sortOrder: 12, price: 120, status: .acquired, recipient: theo, event: holidays),
            Gift(title: "Telescope", sortOrder: 13, price: 210, status: .idea, recipient: theo, event: holidays),

            Gift(title: "Running Shoes", sortOrder: 14, price: 150, status: .idea, recipient: noelle, event: birthday),
            Gift(title: "Cookbook", sortOrder: 15, price: 40, status: .acquired, recipient: chris, event: birthday),
            Gift(title: "Board Game", sortOrder: 16, price: 55, status: .idea, recipient: theo, event: birthday),

            // The wishlist tab reads these, and the Shopping List deliberately excludes them.
            Gift(title: "Mechanical Keyboard", sortOrder: 17, price: 165, status: .idea, recipient: me, event: holidays),
            Gift(title: "Espresso Grinder", sortOrder: 18, price: 230, status: .idea, recipient: me, event: holidays),
            Gift(title: "Linen Sheets", sortOrder: 19, price: 120, status: .idea, recipient: me, event: holidays),
            Gift(title: "Trail Backpack", sortOrder: 20, price: 145, status: .idea, recipient: me, event: birthday),
            Gift(title: "Fountain Pen", sortOrder: 21, price: 70, status: .idea, recipient: me, event: birthday)
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
