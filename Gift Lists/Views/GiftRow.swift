import SwiftUI

struct GiftRow: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var gift: Gift
    
    @State var showingDetails = false
    
    let showStatus: Bool
    
    var body: some View {
        HStack {
            Text(gift.title ?? "")
                .privacySensitive()
            
            Spacer()
            
            Text(gift.price ?? .nan, format: .currency(code: Locale.current.currencyID).precision(.fractionLength(0...2)))
                .foregroundStyle(.secondary)
                .privacySensitive()
            
            if showStatus {
                Group {
                    switch gift.status {
                    case .idea:
                        gift.status?.icon
                            .foregroundStyle(.secondary)
                            .accessibilityRepresentation {
                                Text("Idea")
                            }
                    case .inTransit:
                        gift.status?.icon
                            .foregroundStyle(Color.red)
                            .accessibilityRepresentation {
                                Text("In Transit")
                            }
                    case .acquired:
                        gift.status?.icon
                            .foregroundStyle(Color.yellow)
                            .accessibilityRepresentation {
                                Text("Acquired")
                            }
                    case .wrapped:
                        gift.status?.icon
                            .foregroundStyle(Color.green)
                            .accessibilityRepresentation {
                                Text("Wrapped")
                            }
                    case .given:
                        gift.status?.icon
                            .foregroundStyle(Color.purple)
                            .accessibilityRepresentation {
                                Text("Given")
                            }
                    case nil:
                        Image(systemName: "questionmark.square.dashed")
                            .foregroundStyle(.secondary)
                            .accessibilityRepresentation {
                                Text("Unknown Status")
                            }
                    }
                }
                .symbolVariant(.fill)
                .imageScale(.small)
                .frame(width: 20)
            }
        }
        .accessibilityRemoveTraits(.isSelected)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetails = true
        }
        #if os(watchOS)
        .sheet(isPresented: $showingDetails) {
            NavigationStack {
                GiftView(gift: gift)
            }
        }
        #else
        #if os(macOS)
        .popover(isPresented: $showingDetails, arrowEdge: .trailing) {
            GiftView(gift: gift)
                .frame(idealWidth: 300, idealHeight: 440)
        }
        #else
        .popover(isPresented: $showingDetails, arrowEdge: .leading) {
            NavigationStack {
                GiftView(gift: gift)
            }
            .frame(idealWidth: 400, idealHeight: 640)
        }
        #endif
        #endif
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                modelContext.delete(gift)
            }
        }
        #if !os(watchOS)
        .contextMenu {
            if let url = gift.amazonURL {
                Link(destination: url) {
                    Label("Search Amazon", systemImage: "magnifyingglass")
                }
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                modelContext.delete(gift)
            }
        }
        .onScreenEntity(GiftEntity.self, id: gift.identifier)
        #endif
    }
}
