import SwiftUI

#if !os(watchOS)
/// The Cancel button shared by the creation sheets.
struct CancelToolbarItem: ToolbarContent {
    
    let action: () -> Void
    
    @ToolbarContentBuilder
    var body: some ToolbarContent {
        #if os(iOS)
        if #available(iOS 27.0, *) {
            // Cancel is the first to collapse into the overflow menu when the bar is constrained.
            cancelItem
                .visibilityPriority(.low)
        } else {
            cancelItem
        }
        #else
        cancelItem
        #endif
    }
    
    private var cancelItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", systemImage: "xmark", action: action)
        }
    }
}
#endif
