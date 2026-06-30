//
//  MarkGiftStatusIntent.swift
//  Holiday Gifts List
//
//  Created by Claude on 2026-06-29.
//

import AppIntents
import SwiftData

/// Updates a gift's status, e.g. marking it acquired, wrapped, or given.
struct MarkGiftStatusIntent: AppIntent {

    static var title: LocalizedStringResource = "Change Gift Status"
    static var description = IntentDescription("Updates the status of a gift, such as marking it acquired or wrapped.")

    @Parameter(title: "Gift")
    var gift: GiftEntity

    @Parameter(title: "Status")
    var status: Status

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$gift) as \(\.$status)")
    }

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<GiftEntity> & ProvidesDialog {
        let context = sharedModelContainer.mainContext
        guard let model = Gift.model(for: gift.id, in: context) else {
            throw IntentError.notFound
        }
        model.status = status
        try context.save()

        let statusName = Status.caseDisplayRepresentations[status]?.title ?? "\(status.title)"
        return .result(
            value: GiftEntity(model),
            dialog: "Marked \(model.title ?? "the gift") as \(statusName)."
        )
    }
}
