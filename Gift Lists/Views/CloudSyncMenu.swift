import SwiftUI

/// The iCloud sync status, as a submenu of the app's options: a glance at whether this device is
/// still syncing, and a report to paste into a support email when it is not.
struct CloudSyncMenu: View {

    private let sync = CloudSync.shared

    var body: some View {
        Menu {
            if let failure = sync.failure {
                Text(failure.error.localizedDescription)
            }
            Button("Copy Sync Report", systemImage: "doc.on.doc") {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(sync.report, forType: .string)
                #else
                UIPasteboard.general.string = sync.report
                #endif
            }
        } label: {
            Text("iCloud Sync")
            Text(sync.summary)
            Image(systemName: sync.systemImage)
        }
    }

}
