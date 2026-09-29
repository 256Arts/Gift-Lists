#if canImport(FoundationModels) && !os(watchOS)
import SwiftUI

/// A modal screen that suggests gift ideas for a recipient via Apple Intelligence and adds the chosen ones.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct GiftIdeasView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recipient: Recipient
    /// The occasion the list is filtered to, if any — steers the ideas and tags the gifts added.
    var event: Event? = nil

    @State private var generator = GiftIdeaGenerator()
    @State private var addedIDs: Set<String> = []
    @State private var interests = ""

    var body: some View {
        List {
            Section {
                TextField("Interests", text: $interests, prompt: Text("Hiking, coffee, board games…"))
                    .onSubmit(generate)
                    .submitLabel(.go)
            } footer: {
                Text("Optional. Describe what \(recipient.name ?? "they") enjoy for more personal ideas.")
            }

            Section {
                ForEach(generator.suggestions) { suggestion in
                    let isAdded = addedIDs.contains(suggestion.id)
                    Button {
                        add(suggestion)
                    } label: {
                        LabeledContent {
                            Text(Double(suggestion.estimatedPrice), format: .currency(code: Locale.current.currencyID).precision(.fractionLength(0...2)))
                                .foregroundStyle(.secondary)
                        } label: {
                            Label(suggestion.title, systemImage: isAdded ? "checkmark.circle.fill" : "plus.circle")
                        }
                    }
                    .disabled(isAdded)
                }
            } footer: {
                if let errorMessage = generator.errorMessage {
                    Text(errorMessage)
                }
            }

            if !generator.isGenerating {
                Button(action: generate) {
                    Label(generator.suggestions.isEmpty ? "Generate Gift Ideas" : "Suggest More", systemImage: "sparkles")
                }
            }
        }
        .overlay {
            if generator.isGenerating, generator.suggestions.isEmpty {
                ProgressView("Generating Ideas…")
            } else if generator.suggestions.isEmpty, generator.errorMessage == nil {
                ContentUnavailableView("No Ideas Yet", systemImage: "sparkles", description: Text("Generate gift ideas tailored to \(recipient.name ?? "this person")."))
            }
        }
        .navigationTitle("Gift Ideas")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") {
                    dismiss()
                }
            }
        }
        .task {
            if generator.suggestions.isEmpty {
                await generator.generate(for: recipient, event: event, interests: interests)
            }
        }
    }

    private func generate() {
        guard !generator.isGenerating else { return }
        Task { await generator.generate(for: recipient, event: event, interests: interests) }
    }

    private func add(_ suggestion: SuggestedGift) {
        let sortOrder = ((recipient.gifts ?? []).max(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 0 })?.sortOrder ?? 0) + 1
        modelContext.insert(Gift(title: suggestion.title, sortOrder: sortOrder, price: Double(suggestion.estimatedPrice), status: .idea, recipient: recipient, event: event))
        addedIDs.insert(suggestion.id)
    }
}
#endif
