//
//  PreviewContainer.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2023-10-22.
//

#if DEBUG
import SwiftData
import Foundation

@MainActor
let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Gift.self, configurations: config)
    let calendar = Calendar.current
    
    let birth = Event(name: "Birthday", date: .distantPast)
    let holly = Event(name: "Holidays", date: calendar.date(from: DateComponents(month: 12, day: 25)))
    for event in [birth, holly] {
        container.mainContext.insert(event)
    }
    
    let chris = Recipient(name: "Chris", sortOrder: 2, birthday: calendar.date(from: DateComponents(month: 12, day: 25)))
    let noelle = Recipient(name: "Noelle", sortOrder: 1, birthday: calendar.date(from: DateComponents(month: 7, day: 14)))
    let nick = Recipient(name: "Nicholas", sortOrder: 0, birthday: calendar.date(from: DateComponents(month: 3, day: 6)))
    for recip in [chris, noelle, nick] {
        container.mainContext.insert(recip)
    }
    
    let gifts = [
        Gift(title: "Door Mat", sortOrder: 0, price: 25, status: .wrapped, recipient: nick, event: birth),
        Gift(title: "Throw Pillow", sortOrder: 1, price: 25, status: .acquired, recipient: nick, event: birth),
        Gift(title: "Picnic Set", sortOrder: 2, price: 75, status: .idea, recipient: nick, event: birth),
        Gift(title: "AirTags", sortOrder: 3, price: 100, status: .wrapped, recipient: noelle, event: birth),
        Gift(title: "Frying Pans", sortOrder: 4, price: 100, status: .inTransit, recipient: noelle, event: birth),
        Gift(title: "Beach Shorts", sortOrder: 5, price: 50, status: .idea, recipient: noelle, event: birth),
        Gift(title: "Cake", sortOrder: 6, price: 25, status: .inTransit, recipient: chris, event: birth),
        Gift(title: "Chocolate Bar", sortOrder: 7, price: 10, status: .idea, recipient: chris, event: birth),
        
        Gift(title: "Yoga Mat", sortOrder: 0, price: 25, status: .wrapped, recipient: nick, event: holly),
        Gift(title: "Blanket", sortOrder: 1, price: 25, status: .acquired, recipient: nick, event: holly),
        Gift(title: "Candle", sortOrder: 2, price: 25, status: .idea, recipient: nick, event: holly),
        Gift(title: "iPad", sortOrder: 3, price: 500, status: .wrapped, recipient: noelle, event: holly),
        Gift(title: "Baking Pans", sortOrder: 4, price: 100, status: .inTransit, recipient: noelle, event: holly),
        Gift(title: "Winter Sweater", sortOrder: 5, price: 100, status: .idea, recipient: noelle, event: holly),
        Gift(title: "LEGO Death Star", sortOrder: 6, price: 1000, status: .inTransit, recipient: chris, event: holly),
        Gift(title: "Hot Chocolate", sortOrder: 7, price: 20, status: .idea, recipient: chris, event: holly)
    ]
    for gift in gifts {
        container.mainContext.insert(gift)
    }
    
    return container
}()
#endif
