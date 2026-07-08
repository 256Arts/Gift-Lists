//
//  NewGiftView.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2023-04-18.
//

import SwiftUI
import SwiftData
import StoreKit

struct NewGiftView: View {
    
    let recipient: Recipient?
    let sortOrder: Int
    
    @AppStorage(UserDefaults.Key.giftsCreatedCount) private var giftsCreatedCount: Int = 0
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    #if !os(watchOS)
    @Environment(\.requestReview) private var requestReview
    #endif
    
    @Query(sort: \Event.name) var events: [Event]
    
    @State var title: String = ""
    @State var price: Double = 0.0
    @State var status: Status = .idea
    @State var notes: String = ""
    @State var event: Event?

    #if !os(watchOS)
    private var cancelButton: some View {
        Button("Cancel", systemImage: "xmark") {
            dismiss()
        }
    }
    #endif

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif
                    #if !os(watchOS)
                    .font(.largeTitle)
                    #endif
                
                TextField("Price", value: $price, format: .currency(code: Locale.current.currencyID).precision(.fractionLength(0...2)))
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                
                Picker("Status", selection: $status) {
                    ForEach(Status.allCases) { status in
                        Label {
                            Text(status.title)
                        } icon: {
                            status.icon
                        }
                        .tag(status)
                    }
                }
                
                #if !os(watchOS)
                TextEditor(text: $notes)
                    .overlay(alignment: .leading) {
                        if notes.isEmpty {
                            Text("Notes")
                                .foregroundStyle(.secondary)
                        }
                    }
                #else
                if !notes.isEmpty {
                    Text(notes)
                }
                #endif
            }
            
            Section {
                Picker("Event", selection: $event) {
                    Text("None")
                        .tag(nil as Event?)
                    
                    Divider()
                    
                    ForEach(events) { event in
                        Label {
                            Text(event.name ?? "")
                        } icon: {
                            event.specialCase?.icon ?? Image("")
                        }
                        .tag(event as Event?)
                    }
                }
            }
        }
        #if !os(watchOS)
        .navigationTitle("New Gift")
        #endif
        .toolbar {
            #if os(iOS)
            // Cancel is the first to collapse into the overflow menu when the bar is constrained.
            ToolbarItem(placement: .cancellationAction) {
                cancelButton
            }
            .visibilityPriority(.low)
            #elseif !os(watchOS)
            ToolbarItem(placement: .cancellationAction) {
                cancelButton
            }
            #endif
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", systemImage: "checkmark") {
                    let gift = Gift(title: title, sortOrder: sortOrder, price: price, notes: notes, status: status, recipient: recipient, event: event)
                    modelContext.insert(gift)
                    giftsCreatedCount += 1
                    #if !os(watchOS)
                    if ExperienceManager.shared.giftCountsToAskForReview.contains(giftsCreatedCount) {
                        requestReview()
                    }
                    #endif
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Gift.self, configurations: config)
    
    return NewGiftView(recipient: nil, sortOrder: 0)
        .modelContainer(container)
}
