//
//  OnScreenEntity.swift
//  Holiday Gifts List
//
//  Created by Claude on 2026-06-29.
//

import SwiftUI
import AppIntents

/// `NSUserActivity` types advertised for Siri / Apple Intelligence on-screen awareness.
/// Each value must also be listed under `NSUserActivityTypes` in the app's Info.plist.
enum OnScreenActivity {
    static let viewingGift = "com.jaydenirwin.holidaygiftslist.viewingGift"
    static let viewingRecipient = "com.jaydenirwin.holidaygiftslist.viewingRecipient"
}

extension View {

    /// Advertises an App Entity as the primary content currently on screen, so Siri and Apple
    /// Intelligence can resolve spoken references like "this gift" to it (on-screen awareness).
    func advertisesOnScreen<Entity: AppEntity>(_ entity: Entity, as activityType: String, title: String) -> some View {
        userActivity(activityType) { activity in
            activity.title = title
            activity.appEntityIdentifier = EntityIdentifier(for: entity)
        }
    }

    /// Tags this view as one of several on-screen entities, letting Siri resolve references like
    /// "that one". No-ops for legacy records that predate their stable identifier.
    @ViewBuilder
    func onScreenEntity<Entity: AppEntity>(_ type: Entity.Type, id: UUID?) -> some View where Entity.ID == UUID {
        if let id {
            appEntityIdentifier(EntityIdentifier(for: type, identifier: id))
        } else {
            self
        }
    }
}
