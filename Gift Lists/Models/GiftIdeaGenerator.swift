//
//  GiftIdeaGenerator.swift
//  Gift Lists
//
//  Created by 256 Arts on 2026-06-26.
//

#if canImport(FoundationModels)
import Foundation
import FoundationModels

/// A single gift suggestion produced by Apple Intelligence.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable
struct SuggestedGift: Equatable, Identifiable {

    var id: String { title }

    @Guide(description: "A specific, purchasable product, e.g. \"Cast iron skillet\" — never a category or an activity")
    let title: String

    @Guide(description: "A rough estimated price as a number in the local currency")
    let estimatedPrice: Int
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable
private struct SuggestedGiftList {

    @Guide(description: "Distinct gift ideas tailored to the recipient", .count(5))
    let gifts: [SuggestedGift]
}

/// Generates gift ideas for a recipient from their name, age, and existing list using the on-device model.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@MainActor @Observable
final class GiftIdeaGenerator {

    var suggestions: [SuggestedGift] = []
    var isGenerating = false
    var errorMessage: String?

    /// Whether Apple Intelligence is enabled and ready on this device.
    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    func generate(for recipient: Recipient) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(to: prompt(for: recipient), generating: SuggestedGiftList.self)

            // Drop anything already on the recipient's list (or already suggested this session)
            let taken = Set((recipient.gifts ?? []).compactMap { $0.title?.localizedLowercase } + suggestions.map { $0.title.localizedLowercase })
            suggestions += response.content.gifts.filter { !taken.contains($0.title.localizedLowercase) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static let instructions = """
        You suggest thoughtful, specific gift ideas for a person. \
        Every suggestion must be a real, purchasable product — never a category, gift card, or activity. \
        Tailor ideas to the recipient's age, and never repeat ideas they already have.
        """

    private func prompt(for recipient: Recipient) -> String {
        var lines = ["Suggest gift ideas for \(recipient.name ?? "someone")."]
        if let age = recipient.age {
            lines.append("They are \(age) years old.")
        }
        let existing = (recipient.gifts ?? []).compactMap(\.title)
        if !existing.isEmpty {
            lines.append("They already have these gift ideas: \(existing.joined(separator: ", ")).")
            lines.append("Suggest different ideas that complement these without duplicating them.")
        }
        return lines.joined(separator: " ")
    }
}
#endif
