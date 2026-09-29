import Foundation
import SwiftData
import WidgetKit

/// Keeps the widgets in step with the store the app is writing to.
///
/// The widgets read the same store the app does, so they go stale the moment anything is edited.
/// Saves arrive in bursts — SwiftData autosaves while a sheet is being filled in — and WidgetKit
/// budgets reloads, so this waits for the burst to end rather than spending a reload per keystroke.
@MainActor
enum WidgetRefresh {

    private static var pending: Task<Void, Never>?

    /// Watches the store for the life of the app, reloading the widgets once the writing stops.
    static func observeSaves() async {
        for await _ in NotificationCenter.default.notifications(named: ModelContext.didSave) {
            schedule()
        }
    }

    private static func schedule() {
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

}
