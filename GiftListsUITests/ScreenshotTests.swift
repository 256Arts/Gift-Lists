import XCTest

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

        // Recipients land collapsed, exactly as a real user finds them, so the first shot expands the
        // top two by hand. Waiting on a seeded row first keeps the capture from beating the store.
        XCTAssertTrue(waitForControl("Recipient.Noelle", timeout: 30).exists, "seeded content never appeared")
        expandRecipient("Noelle")
        expandRecipient("Chris")
        settle()
        capture("01-gifts")

        // The wallpaper and the countdown only appear once the list is filtered to an event, which is
        // a sidebar tab on the Mac and the navigation title's menu on iOS. visionOS publishes no
        // tappable title — only More and Add Recipient — so the event filter cannot be reached there.
        #if !os(visionOS)
        selectHolidaysEvent()
        settle()
        capture("02-holidays")
        #endif

        // Tapping a gift opens its details. Not on the Mac: there it is a floating popover, a window
        // of its own, so it photographs detached from the app rather than as one picture.
        #if !os(macOS)
        activate(waitForControl("Gift.Espresso Machine"), "the featured gift")
        settle()
        capture("03-gift-details")
        dismissDetails()
        #endif

        activate(waitForControl("My Wishlist"), "My Wishlist tab")
        settle()
        capture("04-wishlist")

        activate(waitForControl("Shopping List"), "Shopping List tab")
        settle()
        capture("05-shopping")
    }

    // MARK: - Driving

    /// Filters the gifts list down to the Holidays event, which is what brings out the wallpaper and
    /// the countdown. Each event gets its own sidebar tab on the Mac; elsewhere the picker hangs off
    /// the navigation title, whose button is labelled "<title>, Actions Menu".
    private func selectHolidaysEvent() {
        #if os(macOS)
        activate(waitForControl("Holidays Gifts"), "the Holidays tab")
        #else
        let titleMenu = app.navigationBars.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "All Gifts")).firstMatch
        activate(titleMenu, "the navigation title menu")
        activate(waitForControl("Holidays"), "the Holidays event filter")
        #endif

        // A different event means a different list, so the rows come back collapsed.
        expandRecipient("Noelle")
        expandRecipient("Chris")
    }

    /// Opens a recipient's gifts, and leaves an already-open one alone.
    ///
    /// Expanding is a toggle, and iOS keeps the disclosure state across an event switch, so a blind
    /// second tap would shut the group the previous shot just opened. Both platforms publish the
    /// state — a chevron named "collapsed" on iOS, a triangle whose value is 0 on the Mac.
    private func expandRecipient(_ name: String) {
        let identifier = "Recipient.\(name)"
        #if os(macOS)
        let title = app.staticTexts[identifier]
        XCTAssertTrue(title.waitForExistence(timeout: 15), "never found \(name)'s row")

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

    /// Tabs, rows, and toolbar segments surface as different element types per platform — a tab is a
    /// `Button` on iOS and a `RadioButton` on macOS, and a list row is a `Cell` — so look through the
    /// types that can actually be activated rather than guessing one.
    private func control(_ label: String) -> XCUIElement {
        for query in [app.buttons, app.radioButtons, app.descendants(matching: .tab), app.cells, app.staticTexts] {
            // An identifier set on a row propagates to every text inside it, so a gift's title and
            // its price both answer to the row's name — take the first rather than failing the click.
            let byIdentifier = query.matching(identifier: label)
            // `element(boundBy:)` rather than `firstMatch`: the latter short-circuits the query and
            // hands back an element that reports itself absent even when the query matched one.
            if byIdentifier.count > 0 { return byIdentifier.element(boundBy: 0) }
            let byLabel = query[label]
            if byLabel.exists { return byLabel }
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
        #if os(macOS)
        captureWindow(named: name)
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

    #if os(macOS)

    /// Asks the shell running the tests to photograph the window, and waits for it.
    ///
    /// The good capture is `screencapture -l`, which reads the window's own buffer: correctly masked
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

    private func captureWindow(named name: String) {
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
