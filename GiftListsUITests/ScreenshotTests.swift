import XCTest
#if os(iOS)
import UIKit
#endif

/// Drives the app through the screens that become App Store screenshots and attaches each one to the
/// result bundle, where `Scripts/screenshots.sh` extracts them.
///
/// One test rather than one per screen: the shots are a walk through a single launch, and splitting
/// them would pay the launch — and the reseed — every time.
@MainActor
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    func testCaptureAppStoreScreenshots() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-screenshotMode"]
        app.launch()

        // Waiting on a seeded row before touching anything keeps the walk from beating the store.
        XCTAssertTrue(waitForControl("Recipient.\(Self.holidayRecipients[0])", timeout: 30).exists,
                      "seeded content never appeared")

        // The wallpaper — and, on the holidays, the countdown — only appears once the list is
        // filtered to an event, so every list shot is taken filtered.
        selectEvent("Holidays", expanding: Self.holidayRecipients)
        settle()
        capture("01-holidays")

        selectEvent("Birthday", expanding: Self.birthdayRecipients)
        settle()

        // The gift details share the birthday shot wherever they draw over the list. On the phone
        // the popover adapts to a sheet that covers it, so the two split into separate shots; on the
        // Mac the popover is a window of its own, which the window capture cannot see, so the list
        // there stands alone.
        #if os(macOS)
        capture("02-birthday")
        #else
        if detailsCoverTheList {
            capture("02-birthday")
            openFeaturedGift()
            capture("03-gift-details")
        } else {
            openFeaturedGift()
            capture("02-birthday")
        }
        dismissDetails()
        #endif

        activate(waitForControl("Shopping List"), "Shopping List tab")
        settle()
        capture("04-shopping")
    }

    // MARK: - Driving

    /// The event the list is currently filtered to, which is also its navigation title's stem.
    private var currentEvent = "All"

    /// The pair leading each event's list, which is the pair the shots open. The two events are
    /// seeded with separate casts, so the names differ per event — `ScreenshotMode` holds the same
    /// pairs on the app's side.
    private static let holidayRecipients = ["Noelle", "Chris"]
    private static let birthdayRecipients = ["Maya", "Daniel"]

    /// Filters the gifts list down to one event, which is what brings out the wallpaper and, on the
    /// holidays, the countdown. Each event gets its own sidebar tab on the Mac; elsewhere the picker
    /// hangs off the navigation title, whose button is labelled "<title>, Actions Menu".
    private func selectEvent(_ name: String, expanding recipients: [String]) {
        #if os(macOS)
        activate(waitForControl("\(name) Gifts"), "the \(name) tab")
        #elseif os(visionOS)
        // visionOS publishes no navigation title, so its filter lives in the toolbar's More menu.
        activate(waitForControl("More"), "the More menu")
        activate(waitForControl(name), "the \(name) event filter")
        #else
        // The title is the event's own once one is picked, so the menu is found under whichever
        // event the previous step left behind rather than under a fixed name.
        let title = currentEvent == "All" ? "All Gifts" : "\(currentEvent) Gifts"
        let titleMenu = app.navigationBars.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
        activate(titleMenu, "the navigation title menu")
        activate(waitForControl(name), "the \(name) event filter")
        #endif
        currentEvent = name

        // A different event means a different list, so the rows come back collapsed.
        for recipient in recipients {
            expandRecipient(recipient)
        }
    }

    /// Opens the details for the gift the details shot is taken on.
    private func openFeaturedGift() {
        activate(waitForControl("Gift.Espresso Machine"), "the featured gift")
        settle()
    }

    #if !os(macOS)
    /// Whether the gift details hide the list behind them rather than floating over it. Only the
    /// phone adapts a popover into a sheet; the iPad, and visionOS, keep it a popover.
    private var detailsCoverTheList: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }
    #endif

    /// Opens a recipient's gifts, and leaves an already-open one alone.
    ///
    /// Expanding is a toggle, and iOS keeps the disclosure state across an event switch, so a blind
    /// second tap would shut the group the previous shot just opened. Both platforms publish the
    /// state — a chevron named "collapsed" on iOS, a triangle whose value is 0 on the Mac.
    private func expandRecipient(_ name: String) {
        let identifier = "Recipient.\(name)"
        #if os(macOS)
        let title = app.staticTexts.matching(Self.identifierPredicate(identifier)).element(boundBy: 0)
        if !title.waitForExistence(timeout: 15) {
            attach(XCTAttachment(string: app.debugDescription), named: "tree-missing-\(identifier)")
            return XCTFail("never found \(name)'s row")
        }

        // The triangle carries the generic NSOutlineViewDisclosureButtonKey identifier, so the only
        // thing tying one to a recipient is sitting on the same line as their name.
        let line = title.frame.midY
        let triangles = app.disclosureTriangles
        for index in 0..<triangles.count {
            let triangle = triangles.element(boundBy: index)
            guard triangle.frame.minY <= line, line <= triangle.frame.maxY else { continue }
            if String(describing: triangle.value ?? "") == "0" {
                triangle.click()
            }
            return
        }
        XCTFail("no disclosure triangle on \(name)'s line")
        #else
        let row = waitForControl(identifier)
        XCTAssertTrue(row.exists, "never found \(name)'s row")
        if row.images["collapsed"].exists {
            row.tap()
        }
        #endif
    }

    /// The details popover has its own Done button; the tabs underneath are untappable until it goes.
    private func dismissDetails() {
        let done = waitForControl("Done", timeout: 5)
        if done.exists {
            activate(done, "Done")
            settle(seconds: 1)
        }
    }

    /// Matches an accessibility identifier the app set, whether or not the platform merged the row
    /// that carries it.
    ///
    /// An identifier set on a row propagates to every element inside it, and when AppKit decides the
    /// row reads better as one element — the Birthday list does this, its extra "N days left" text
    /// being what tips it over — it merges those children and *joins their identifiers with a
    /// hyphen*: a row named `Recipient.Noelle` answers to `Recipient.Noelle-Recipient.Noelle`. So the
    /// lookup takes the identifier as one hyphen-separated component rather than the whole string.
    private static func identifierPredicate(_ identifier: String) -> NSPredicate {
        NSPredicate(format: "identifier == %@ OR identifier BEGINSWITH %@ OR identifier CONTAINS %@",
                    identifier, identifier + "-", "-" + identifier)
    }

    /// Tabs, rows, and toolbar segments surface as different element types per platform — a tab is a
    /// `Button` on iOS and a `RadioButton` on macOS, and a list row is a `Cell` — so look through the
    /// types that can actually be activated rather than guessing one.
    private func control(_ label: String) -> XCUIElement {
        for query in [app.buttons, app.radioButtons, app.descendants(matching: .tab), app.cells, app.staticTexts] {
            // An identifier set on a row propagates to every text inside it, so a gift's title and
            // its price both answer to the row's name — take the first rather than failing the click.
            let byIdentifier = query.matching(Self.identifierPredicate(label))
            // `element(boundBy:)` rather than `firstMatch`: the latter short-circuits the query and
            // hands back an element that reports itself absent even when the query matched one.
            if byIdentifier.count > 0 { return byIdentifier.element(boundBy: 0) }
            // Same reason as the identifier lookup above, and not only for rows: a sidebar-adaptable
            // `TabView` publishes each tab twice on the iPad, once in the sidebar and once in the
            // tab bar, and `query[label]` refuses to resolve to either.
            let byLabel = query.matching(NSPredicate(format: "label == %@", label))
            if byLabel.count > 0 { return byLabel.element(boundBy: 0) }
        }
        // The Mac sidebar's tabs carry their title as a value, with no identifier or label to match.
        let byValue = app.staticTexts.matching(NSPredicate(format: "value == %@", label))
        if byValue.count > 0 { return byValue.element(boundBy: 0) }
        return app.buttons[label]   // nothing matched; let the caller's assertion name the miss
    }

    /// `control` commits to an element type based on what exists the moment it is called, so a lookup
    /// made while the app is still drawing settles on the wrong query. Keep asking instead.
    ///
    /// The waiting is `waitForExistence` rather than a `Thread.sleep` poll: the test runs on the main
    /// thread, and sleeping on it starves the run loop that resolves accessibility queries — every
    /// lookup then comes back empty however long the loop runs, even with the element on screen.
    private func waitForControl(_ label: String, timeout: TimeInterval = 15) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        var element = control(label)
        while !element.waitForExistence(timeout: 1), Date() < deadline {
            element = control(label)
        }
        return element
    }

    private func activate(_ element: XCUIElement, _ description: String) {
        if !element.waitForExistence(timeout: 15) {
            // A walk that dies on a missing element says nothing about why; the tree says everything.
            attach(XCTAttachment(string: app.debugDescription), named: "tree-missing-\(description)")
            return XCTFail("never found \(description)")
        }
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
    }

    /// Animations and async content have no element to wait on, so the shots pause instead.
    private func settle(seconds: TimeInterval = 2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Capturing

    private func capture(_ name: String) {
        // Every capture below photographs the whole screen, or the frontmost window — never this
        // app in particular. So an app that has lost the foreground yields another app's UI, filed
        // under this app's name, at the right size, with nothing to notice. The shared runner holds
        // a machine-wide lock so that cannot happen; this is the check that it held.
        XCTAssertEqual(app.state, .runningForeground,
                       "\(name): the app under test was not frontmost — another app has this device")
        #if os(macOS)
        captureExternally(named: name)
        #elseif os(visionOS)
        // visionOS has no screen for `XCUIScreen.main.screenshot()` to return — it comes back 1x1 —
        // so the runner takes the shot from outside with `simctl io screenshot`.
        captureExternally(named: name)
        #else
        // The simulator's screen already *is* the store's canvas, at the exact required pixel size.
        attach(XCTAttachment(screenshot: XCUIScreen.main.screenshot()), named: name)
        #endif
    }

    private func attach(_ attachment: XCTAttachment, named name: String) {
        attachment.name = name
        attachment.lifetime = .keepAlways   // attachments on a passing test are discarded otherwise
        add(attachment)
    }

    #if os(macOS) || os(visionOS)

    /// Asks the shell running the tests to photograph the app, and waits for it.
    ///
    /// On the Mac the good capture is `screencapture -l`, which reads the window's own buffer: correctly masked
    /// to the rounded corners, with real alpha and the system's own shadow. (`XCUIElement.screenshot()`
    /// crops the *screen* to the window's frame, so it loses the shadow — drawn outside that frame —
    /// and leaves desktop inside the corners.) But `screencapture` needs Screen Recording, which the
    /// test runner has no grant for and the terminal running `Scripts/screenshots.sh` does. So the
    /// test drives the UI and the script takes the picture.
    ///
    /// They meet in a plain directory under /tmp. That works only because the runner is deliberately
    /// unsandboxed (GiftListsUITests/GiftListsUITests.entitlements): a sandboxed runner cannot write
    /// /tmp, and its own container is unreadable to the script, so the two would have nowhere to meet.
    private static let handshakeDirectory = URL(fileURLWithPath: "/tmp/app-store-screenshots")

    private func captureExternally(named name: String) {
        let files = FileManager.default
        let handshake = Self.handshakeDirectory
        let done = handshake.appendingPathComponent("done-\(name)")
        try? files.removeItem(at: done)

        let request = handshake.appendingPathComponent("request-\(name)")
        guard files.createFile(atPath: request.path, contents: nil) else {
            return XCTFail("could not write a capture request to \(request.path)")
        }

        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            if files.fileExists(atPath: done.path) { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("timed out waiting for the script to capture \(name) — is Scripts/screenshots.sh watching \(handshake.path)?")
    }

    #endif
}
