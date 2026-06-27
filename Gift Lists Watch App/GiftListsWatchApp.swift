//
//  GiftListsWatchApp.swift
//  Holiday Gifts List Watch Watch App
//
//  Created by 256 Arts Developer on 2023-07-24.
//

import SwiftUI

@main
struct GiftListsWatchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GiftsListTab()
            }
        }
        #if targetEnvironment(simulator)
        .modelContainer(previewContainer)
        #else
        .modelContainer(for: [Gift.self, Recipient.self])
        #endif
    }
}
