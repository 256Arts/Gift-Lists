import SwiftUI

struct ShoppingRow: View {
    
    @AppStorage(UserDefaults.Key.recipientSortBy) private var recipientSortByValue = RecipientSort.defaultSort.rawValue
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var gift: Gift
    
    private var recipientSortBy: RecipientSort {
        .init(rawValue: UserDefaults.standard.string(forKey: UserDefaults.Key.recipientSortBy) ?? "") ?? .defaultSort
    }
    
    var body: some View {
        NavigationLink(value: gift) {
            HStack {
                if let imageData = gift.imageData {
                    GiftThumbnail(data: imageData)
                }
                
                VStack(alignment: .leading) {
                    Text(gift.title ?? "")
                        .privacySensitive()
                    
                    if let recipient = gift.recipient {
                        HStack(spacing: 4) {
                            if let name = recipient.name {
                                Text("For \(name)")
                            }
                            if gift.event?.specialCase == .birthday, let daysUntilBirthday = recipient.daysUntilBirthday {
                                Text("in \(daysUntilBirthday) days")
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                ShoppingLink(gift: gift)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
            }
        }
        .accessibilityRemoveTraits(.isSelected)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                modelContext.delete(gift)
            }
        }
    }
}
