import CloudKit
import CoreData
import Foundation

/// What this device knows about its iCloud sync — for the user, and for a bug report.
///
/// SwiftData mirrors to CloudKit through `NSPersistentCloudKitContainer`, which fails silently: a
/// device whose sync has stalled simply stops sending and receiving changes, with nothing on screen
/// to say so. Every setup, import, and export it runs is announced on `eventChangedNotification`,
/// so this listens and keeps the latest outcome of each.
@MainActor @Observable
final class CloudSync {

    static let shared = CloudSync()

    /// The container the app's store mirrors to. Named explicitly: `CKContainer.default()` derives
    /// one from the bundle identifier, which is wrong for every target but the app.
    private static let container = CKContainer(identifier: "iCloud.com.jaydenirwin.holidaygiftslist")

    struct Failure {
        let operation: NSPersistentCloudKitContainer.EventType
        let date: Date
        let error: NSError
    }

    private(set) var accountStatus: CKAccountStatus?
    /// The most recent failure of each kind of operation, cleared once that kind next succeeds.
    private(set) var failures: [NSPersistentCloudKitContainer.EventType: Failure] = [:]
    /// When an import or export last succeeded. Kept across launches, so a device that stalled
    /// weeks ago says so.
    private(set) var lastSynced = UserDefaults.standard.object(forKey: UserDefaults.Key.lastCloudSync) as? Date
    private var running: Set<UUID> = []

    var isSyncing: Bool { !running.isEmpty }

    private var observers: [NSObjectProtocol] = []

    /// Call before the model container is created, or its setup event goes unheard.
    func start() {
        guard observers.isEmpty, !ScreenshotMode.isActive else { return }
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: .main) { notification in
                guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else { return }
                MainActor.assumeIsolated { self.record(event) }
            },
            center.addObserver(forName: .CKAccountChanged, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { self.refreshAccountStatus() }
            },
        ]
        refreshAccountStatus()
    }

    private func refreshAccountStatus() {
        Task {
            accountStatus = try? await Self.container.accountStatus()
        }
    }

    private func record(_ event: NSPersistentCloudKitContainer.Event) {
        guard let endDate = event.endDate else {
            running.insert(event.identifier)
            return
        }
        running.remove(event.identifier)

        if event.succeeded {
            failures[event.type] = nil
            if event.type != .setup {
                lastSynced = endDate
                UserDefaults.standard.set(endDate, forKey: UserDefaults.Key.lastCloudSync)
            }
        } else if let error = event.error {
            failures[event.type] = Failure(operation: event.type, date: endDate, error: Self.underlyingError(error))
        }
    }

    /// A CloudKit partial failure only says "some items failed"; the first item's error says why.
    private static func underlyingError(_ error: Error) -> NSError {
        if let ckError = error as? CKError, ckError.code == .partialFailure,
           let itemError = ckError.partialErrorsByItemID?.values.first {
            return itemError as NSError
        }
        return error as NSError
    }

    /// The failure to show, if sync is not working.
    var failure: Failure? {
        failures.values.max { $0.date < $1.date }
    }

    var summary: LocalizedStringResource {
        switch accountStatus {
        case .noAccount: return "Not Signed In to iCloud"
        case .restricted: return "iCloud Is Restricted"
        case .temporarilyUnavailable: return "iCloud Is Temporarily Unavailable"
        default: break
        }
        if failure != nil {
            return "Not Syncing"
        }
        if isSyncing {
            return "Syncing…"
        }
        if let lastSynced {
            return "Synced \(lastSynced, format: .relative(presentation: .named))"
        }
        return "Waiting to Sync"
    }

    var systemImage: String {
        if accountStatus.map({ $0 != .available && $0 != .couldNotDetermine }) == true || failure != nil {
            "exclamationmark.icloud"
        } else if isSyncing {
            "arrow.trianglehead.2.clockwise.icloud"
        } else {
            "checkmark.icloud"
        }
    }

    /// Plain text a user can paste into a support email: everything needed to tell a stalled
    /// device from a misconfigured container without asking them for a sysdiagnose.
    var report: String {
        let info = Bundle.main.infoDictionary
        var lines = [
            "Gift Lists \(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))",
            "Account: \(accountStatus.map(Self.describe) ?? "unknown")",
            "Last synced: \(lastSynced?.ISO8601Format() ?? "never")",
            "Syncing: \(isSyncing)",
        ]
        for failure in failures.values.sorted(by: { $0.date < $1.date }) {
            lines.append("\(Self.describe(failure.operation)) failed \(failure.date.ISO8601Format()): \(failure.error.domain) \(failure.error.code) — \(failure.error.localizedDescription)")
        }
        return lines.joined(separator: "\n")
    }

    private static func describe(_ status: CKAccountStatus) -> String {
        switch status {
        case .available: "available"
        case .noAccount: "no account"
        case .restricted: "restricted"
        case .temporarilyUnavailable: "temporarily unavailable"
        case .couldNotDetermine: "could not determine"
        @unknown default: "\(status.rawValue)"
        }
    }

    private static func describe(_ type: NSPersistentCloudKitContainer.EventType) -> String {
        switch type {
        case .setup: "Setup"
        case .import: "Import"
        case .export: "Export"
        @unknown default: "Event \(type.rawValue)"
        }
    }

}
