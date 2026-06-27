//
//  RecipientRow.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2025-03-20.
//

import SwiftUI

struct RecipientRow: View {
    
    let recipient: Recipient
    let showBirthday: Bool
    let filteredGifts: [Gift]
    
    private var spentTotal: Double {
        filteredGifts.filter({ $0.status != .idea && $0.status != .given }).reduce(0.0, { $0 + ($1.price ?? 0) })
    }
    
    @AppStorage(UserDefaults.Key.recipientSummaryInfo) private var recipientSummaryInfoRaw = ""
    
    private var recipientSummaryInfo: RecipientSummaryInfo {
        .init(rawValue: recipientSummaryInfoRaw) ?? .defaultInfo
    }
    
    @Environment(\.modelContext) private var modelContext
    
    @Binding var recipientName: String
    @Binding var editingRecipient: Recipient?
    
    var body: some View {
        LabeledContent {
            HStack {
                if showBirthday, let daysUntil = recipient.daysUntilBirthday {
                    ViewThatFits {
                        Text("\(daysUntil) days left")
                        Text("\(daysUntil) days")
                        Text("\(daysUntil)d")
                    }
                }
                
                if recipientSummaryInfo == .giftCount {
                    Text("\(filteredGifts.count) Gifts")
                } else if let goal = recipient.spendGoal {
                    Text(
                        "\(spentTotal.formatted(.currency(code: Locale.current.currencyID).precision(.fractionLength(0...2)))) / \(goal.formatted(.currency(code: Locale.current.currencyID).precision(.fractionLength(0...2))))"
                    )
                        .accessibilityLabel("Spent")
                        .accessibilityValue(
                            "\(spentTotal.formatted(.currency(code: Locale.current.currencyID).precision(.fractionLength(0...2)))) of \(goal.formatted(.currency(code: Locale.current.currencyID).precision(.fractionLength(0...2)))) goal"
                        )
                        .privacySensitive()
                } else {
                    Text("\(spentTotal.formatted(.currency(code: Locale.current.currencyID).precision(.fractionLength(0...2)))) spent")
                        .accessibilityLabel("Spent")
                        .accessibilityValue(spentTotal.formatted(.currency(code: Locale.current.currencyID).precision(.fractionLength(0...2))))
                        .privacySensitive()
                }
            }
            .lineLimit(1)
            .font(.footnote)
            .foregroundStyle(.secondary)
        } label: {
            Label(recipient.name ?? "", systemImage: "person.fill")
                .fontWeight(.medium)
                .foregroundStyle(filteredGifts.isEmpty ? .secondary : .primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                modelContext.delete(recipient)
            }
        }
        #if !os(watchOS)
        .contextMenu {
            Button("Edit Recipient", systemImage: "pencil") {
                recipientName = recipient.name ?? ""
                editingRecipient = recipient
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                modelContext.delete(recipient)
            }
        }
        #endif
    }
}
