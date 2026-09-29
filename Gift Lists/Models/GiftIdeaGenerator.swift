#if canImport(FoundationModels) && !os(watchOS)
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

/// Generates gift ideas for a recipient using the on-device model, from their age, budget, past and
/// current gifts (and those gifts' notes), the occasion, and any interests the user types in.
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

    func generate(for recipient: Recipient, event: Event? = nil, interests: String = "") async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let prompt = prompt(for: recipient, event: event, interests: interests)
            let response = try await session.respond(to: prompt, generating: SuggestedGiftList.self)

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
        Tailor ideas to the recipient's age, interests, and the occasion. \
        Never repeat ideas they already have or were given before, and never exceed their budget.
        """

    private func prompt(for recipient: Recipient, event: Event?, interests: String) -> String {
        var lines = ["Suggest gift ideas for \(recipient.name ?? "someone")."]
        if let age = recipient.age {
            lines.append("They are \(age) years old.")
        }
        switch event?.specialCase {
        case .birthday:
            lines.append("The gifts are for their birthday.")
        case .holidays:
            lines.append("The gifts are for the winter holidays.")
        case nil:
            if let name = event?.name, !name.isEmpty {
                lines.append("The gifts are for this occasion: \(name).")
            }
        }
        let interests = interests.trimmingCharacters(in: .whitespacesAndNewlines)
        if !interests.isEmpty {
            lines.append("Their interests: \(interests).")
        }
        if let spendGoal = recipient.spendGoal, spendGoal > 0 {
            lines.append("Their total budget is \(Int(spendGoal)) \(Locale.current.currencyID), so every estimated price must be at most that.")
        }

        let gifts = recipient.gifts ?? []
        let given = gifts.filter { $0.status == .given }.compactMap(\.title)
        let current = gifts.filter { $0.status != .given }
        if !given.isEmpty {
            lines.append("They were already given these in the past, so don't suggest them again: \(given.joined(separator: ", ")).")
        }
        if !current.isEmpty {
            lines.append("They already have these gift ideas: \(current.compactMap(\.title).joined(separator: ", ")).")
            lines.append("Suggest different ideas that complement these without duplicating them.")
        }
        let notes = gifts.compactMap(\.notes).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if !notes.isEmpty {
            lines.append("Notes about their gifts, which may hint at their tastes: \(notes.joined(separator: " / ")).")
        }
        return lines.joined(separator: " ")
    }
}
#endif
