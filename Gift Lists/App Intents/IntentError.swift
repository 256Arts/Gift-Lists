//
//  IntentError.swift
//  Holiday Gifts List
//
//  Created by Claude on 2026-06-29.
//

import AppIntents

/// Errors surfaced to Siri / Shortcuts when an intent can't complete.
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case notFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notFound:
            "Sorry, I couldn't find that in your gift lists."
        }
    }
}
