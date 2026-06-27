//
//  GiftView.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2022-11-19.
//

import SwiftUI
import SwiftData

struct GiftView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Recipient.name) var recipients: [Recipient]
    @Query(sort: \Event.name) var events: [Event]
    
    @Bindable var gift: Gift
    
    @State var title: String
    @State var price: Double
    @State var status: Status
    @State var notes: String
    
    init(gift: Gift) {
        self.gift = gift
        self._title = State(initialValue: gift.title ?? "")
        self._price = State(initialValue: gift.price ?? 0)
        self._status = State(initialValue: gift.status ?? .idea)
        self._notes = State(initialValue: gift.notes ?? "")
    }
    
    var body: some View {
        List {
            Section {
                TextField("Title", text: $title)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif
                    #if !os(watchOS)
                    .font(.largeTitle)
                    #endif
                    .privacySensitive()
                
                TextField("Price", value: $price, format: .currency(code: Locale.current.currencyID).precision(.fractionLength(0...2)))
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .privacySensitive()
                
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
                                .foregroundColor(.secondary)
                        }
                    }
                #else
                if !notes.isEmpty {
                    Text(notes)
                }
                #endif
            }
            Section {
                Picker("Recipient", selection: $gift.recipient) {
                    Text("None")
                        .tag(nil as Recipient?)
                    
                    Divider()
                    
                    ForEach(recipients) { recipient in
                        Label(recipient.isMe ? "Me" : recipient.name ?? "", systemImage: recipient.isMe ? "person.crop.circle" : "")
                            .tag(recipient as Recipient?)
                    }
                }
                
                Picker("Event", selection: $gift.event) {
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
            #if !os(watchOS)
            Section {
                if let url = gift.amazonURL {
                    Link(destination: url) {
                        Label("Search Amazon", systemImage: "magnifyingglass")
                    }
                }
            }
            #endif
            Section {
                Button("Delete", role: .destructive) {
                    modelContext.delete(gift)
                    dismiss()
                }
            }
        }
        .navigationTitle("Details")
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
        .onChange(of: title) { _, newValue in
            gift.title = newValue
        }
        .onChange(of: price) { _, newValue in
            gift.price = price
        }
        .onChange(of: status) { _, newValue in
            gift.status = newValue
        }
        .onChange(of: notes) { _, newValue in
            gift.notes = newValue
        }
    }
}
