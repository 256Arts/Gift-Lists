import SwiftUI

// watchOS draws no menus, so the watch app keeps the stored filter (given gifts hidden) without
// offering a way to change it, the same way it does without the event filter.
#if !os(watchOS)

/// Chooses which gift statuses the gifts list shows.
///
/// The choice is stored rather than held per window, so the macOS menu bar commands and the
/// overflow menu on iOS drive the same list without threading a binding through every view.
struct StatusFilterMenu: View {

    @AppStorage(UserDefaults.Key.hiddenGiftStatuses) private var hiddenGiftStatusesValue = Status.given.rawValue

    private var isFiltering: Bool {
        !Set<Status>(storageValue: hiddenGiftStatusesValue).isEmpty
    }

    var body: some View {
        Menu {
            ForEach(Status.allCases) { status in
                Toggle(isOn: $hiddenGiftStatusesValue.showsGiftStatus(status)) {
                    Label {
                        Text(status.title)
                    } icon: {
                        status.icon
                    }
                }
            }
        } label: {
            Label("Filter by Status", systemImage: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

}

#endif
