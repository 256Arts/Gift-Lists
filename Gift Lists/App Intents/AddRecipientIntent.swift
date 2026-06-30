//
//  AddRecipientIntent.swift
//  Holiday Gifts List
//
//  Created by Claude on 2026-06-29.
//

import AppIntents
import SwiftData

/// Creates a new person to track gifts for.
struct AddRecipientIntent: AppIntent {

    static var title: LocalizedStringResource = "Add Recipient"
    static var description = IntentDescription("Creates a new person to track gifts for.")

    @Parameter(title: "Name", requestValueDialog: "Who would you like to add?")
    var name: String

    @Parameter(title: "Birthday")
    var birthday: Date?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) as a recipient") {
            \.$birthday
        }
    }

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<RecipientEntity> & ProvidesDialog {
        let context = sharedModelContainer.mainContext

        let existing = (try? context.fetch(FetchDescriptor<Recipient>())) ?? []
        let nextSortOrder = (existing.compactMap(\.sortOrder).max() ?? -1) + 1

        let recipient = Recipient(name: name, sortOrder: nextSortOrder, birthday: birthday)
        context.insert(recipient)
        try context.save()

        return .result(value: RecipientEntity(recipient), dialog: "Added \(name) to your recipients.")
    }
}
