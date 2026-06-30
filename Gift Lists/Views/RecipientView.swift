//
//  RecipientView.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2023-07-24.
//

import SwiftUI

struct RecipientView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var recipient: Recipient
    
    @State var name: String
    @State var hasBirthday: Bool
    @State var birthday: Date
    @State var spendGoal: Double
    
    var spentTotal: Double {
        (recipient.gifts ?? []).filter({ $0.status != .idea && $0.status != .given }).reduce(0.0, { $0 + ($1.price ?? 0) })
    }
    
    init(recipient: Recipient) {
        self.recipient = recipient
        self._name = State(initialValue: recipient.name ?? "")
        self._hasBirthday = State(initialValue: recipient.birthday != nil)
        self._birthday = State(initialValue: recipient.birthday ?? .now.addingTimeInterval(-30 * 365 * 24 * 60 * 60))
        self._spendGoal = State(initialValue: recipient.spendGoal ?? 0)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .font(.largeTitle)
                #if os(iOS)
                .textInputAutocapitalization(.words)
                #endif
                
                LabeledContent("Birthday") {
                    HStack {
                        Toggle("Birthday", isOn: $hasBirthday)
                            #if os(macOS)
                            .toggleStyle(.switch)
                            #endif
                        if hasBirthday {
                            DatePicker("Birthday", selection: $birthday, in: Date.distantPast...Date.now, displayedComponents: .date)
                        }
                    }
                    .labelsHidden()
                }
            }
            
            Section {
                LabeledContent("Spent") {
                    Text(spentTotal, format: .currency(code: Locale.current.currencyID).precision(.fractionLength(0...2)))
                }
                
                LabeledContent("Budget") {
                    TextField(
                        "Budget",
                        value: $spendGoal,
                        format: .currency(code: Locale.current.currencyID).precision(.fractionLength(0...2))
                    )
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("Recipient")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark") {
                    dismiss()
                }
            }
        }
        .onChange(of: name) { _, newValue in
            recipient.name = newValue
        }
        .onChange(of: hasBirthday) { _, newValue in
            if newValue {
                recipient.birthday = birthday
            } else {
                recipient.birthday = nil
            }
        }
        .onChange(of: birthday) { _, newValue in
            if hasBirthday {
                recipient.birthday = newValue
            } else {
                recipient.birthday = nil
            }
        }
        .onChange(of: spendGoal) { _, newValue in
            if newValue > 0 {
                recipient.spendGoal = newValue
            } else {
                recipient.spendGoal = nil
            }
        }
        #if !os(watchOS)
        .advertisesOnScreen(RecipientEntity(recipient), as: OnScreenActivity.viewingRecipient, title: recipient.name ?? "Recipient")
        #endif
    }
}
