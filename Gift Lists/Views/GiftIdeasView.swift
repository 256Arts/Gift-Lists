//
//  GiftIdeasView.swift
//  Gift Lists
//
//  Created by 256 Arts on 2026-06-26.
//

#if canImport(FoundationModels) && !os(watchOS)
import SwiftUI

/// A modal screen that suggests gift ideas for a recipient via Apple Intelligence and adds the chosen ones.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct GiftIdeasView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recipient: Recipient

    @State private var generator = GiftIdeaGenerator()
    @State private var addedIDs: Set<String> = []

    var body: some View {
        List {
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
                Button {
                    Task { await generator.generate(for: recipient) }
                } label: {
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
                await generator.generate(for: recipient)
            }
        }
    }

    private func add(_ suggestion: SuggestedGift) {
        let sortOrder = ((recipient.gifts ?? []).max(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 0 })?.sortOrder ?? 0) + 1
        modelContext.insert(Gift(title: suggestion.title, sortOrder: sortOrder, price: Double(suggestion.estimatedPrice), status: .idea, recipient: recipient))
        addedIDs.insert(suggestion.id)
    }
}
#endif
