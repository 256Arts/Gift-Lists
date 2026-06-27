//
//  Recipient.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2022-11-19.
//

import Foundation
import SwiftData

@Model
final class Recipient {
    
    static let userName = "<Me>"
    
    var name: String?
    var sortOrder: Int?
    var birthday: Date?
    var spendGoal: Double?
    var gifts: [Gift]?
    
    var isMe: Bool {
        name == Recipient.userName
    }
    
    @Transient
    var nextBirthday: Date? {
        guard let birthday else { return nil }
        
        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.month, .day], from: birthday)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now) ?? .now
        return calendar.nextDate(after: yesterday, matching: components, matchingPolicy: .nextTime)
    }
    
    @Transient
    var age: Int? {
        guard let birthday else { return nil }
        return Calendar.autoupdatingCurrent.dateComponents([.year], from: birthday, to: .now).year
    }

    @Transient
    var daysUntilBirthday: Int? {
        if let nextBirthday {
            let calendar = Calendar.autoupdatingCurrent
            return calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: nextBirthday).day
        } else {
            return nil
        }
    }
    
    init(name: String, sortOrder: Int, birthday: Date? = nil, spendGoal: Double? = nil) {
        self.name = name
        self.sortOrder = sortOrder
        self.birthday = birthday
        self.spendGoal = spendGoal
        self.gifts = []
    }
    
}

enum RecipientSort: String, CaseIterable, Identifiable {
    case alphabetical
    case nearestBirthday
    case customOrder
    
    static let defaultSort = Self.customOrder
    
    var id: Self { self }
    var title: String {
        switch self {
        case .alphabetical:
            "Alphabetical"
        case .nearestBirthday:
            "Nearest Birthday"
        case .customOrder:
            "Created Date"
        }
    }
}

enum RecipientSummaryInfo: String, CaseIterable, Identifiable {
    case totalSpent
    case giftCount
    
    static let defaultInfo = Self.totalSpent
    
    var id: Self { self }
    var title: String {
        self == .totalSpent ? "Total Spent" : "Number of Gifts"
    }
}

extension [Recipient] {
    func sorted(by sort: RecipientSort) -> [Recipient] {
        sorted(by: {
            switch sort {
            case .alphabetical:
                $0.name?.localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
            case .nearestBirthday:
                if $0.daysUntilBirthday == $1.daysUntilBirthday {
                    $0.name?.localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
                } else {
                    $0.daysUntilBirthday ?? Int.max < $1.daysUntilBirthday ?? Int.max
                }
            case .customOrder:
                if let sort0 = $0.sortOrder {
                    sort0 < $1.sortOrder ?? 0
                } else {
                    $0.name?.localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
                }
            }
        })
    }
}
