import Foundation
import SwiftData

/// Where the gifts actually live on disk, and how every process that needs them opens it.
///
/// The app used to keep its store at SwiftData's default path inside the app's own container, which
/// only the app could read. A widget runs in a separate process, so the store moved into an App
/// Group container both can reach; `sharedModelContainer` and the widget extension both come
/// through here so there is one description of the store rather than two that can drift.
enum GiftListsStore {

    /// The App Group both the app and its widgets are entitled to.
    ///
    /// The two platforms disagree about the spelling and there is no arguing with either: iOS
    /// requires the identifier to begin with `group.`, macOS requires it to begin with the team
    /// identifier. Same container, same contents — only the name differs.
    ///
    /// This mirrors the `APP_GROUP_IDENTIFIER` build setting, which is what the entitlements files
    /// interpolate; keep the two in step.
    static let appGroupIdentifier: String = {
        #if os(macOS)
        "VA3SY54YU8.group.com.jaydenirwin.holidaygiftslist"
        #else
        "group.com.jaydenirwin.holidaygiftslist"
        #endif
    }()

    /// The store inside the App Group. `nil` on a build that is not entitled to the group, which is
    /// the callers' cue to fall back to SwiftData's default location rather than fail to launch.
    static var url: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appending(path: storeName)
    }

    /// Where SwiftData put the store before the widgets needed to read it too.
    private static var legacyURL: URL? {
        try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appending(path: storeName)
    }

    private static let storeName = "default.store"

    /// A read-write container on whichever store this build can reach.
    ///
    /// Only the app passes `copyingLegacyStore`, and it matters that only the app does: whoever
    /// opens the group store first creates it, and a store the widget created empty would look to
    /// the app like one that had already been brought across, leaving a pre-App-Group install
    /// staring at an empty list. So the widget does not open a store that is not there yet — it
    /// has nothing to draw either way, and one launch of the app fixes it.
    @MainActor
    static func makeContainer(copyingLegacyStore: Bool = false) throws -> ModelContainer {
        if copyingLegacyStore {
            copyLegacyStoreIfNeeded()
        }

        let schema = Schema([Gift.self, Recipient.self, Event.self])
        guard let url else {
            guard copyingLegacyStore else { throw StoreError.noAppGroup }
            return try ModelContainer(for: schema)
        }
        guard copyingLegacyStore || FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw StoreError.notCreatedYet
        }
        return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
    }

    enum StoreError: Error {
        /// This build is not entitled to the App Group, so there is no shared store to read.
        case noAppGroup
        /// The app has not opened the shared store yet, and it is not the widget's place to.
        case notCreatedYet
    }

    /// Brings a pre-App-Group install's gifts across, once.
    ///
    /// Most devices would refill the relocated store from CloudKit on their own within seconds of
    /// the update, but a device signed out of iCloud has nowhere else to get its gifts from and
    /// would open to an empty list. The `-wal` and `-shm` files come too: they hold writes the
    /// `.store` has not absorbed yet, so copying the store alone silently drops the most recent
    /// ones. The originals are left in place — this copies rather than moves, so a downgrade or a
    /// failed copy still has something to fall back on.
    private static func copyLegacyStoreIfNeeded() {
        guard let url, let legacyURL else { return }

        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: url.path(percentEncoded: false)),
              fileManager.fileExists(atPath: legacyURL.path(percentEncoded: false)) else { return }

        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(filePath: legacyURL.path(percentEncoded: false) + suffix)
            let destination = URL(filePath: url.path(percentEncoded: false) + suffix)
            try? fileManager.copyItem(at: source, to: destination)
        }
    }

}
