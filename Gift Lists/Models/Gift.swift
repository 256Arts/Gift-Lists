//
//  Gift.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2023-06-09.
//

import SwiftUI
import SwiftData

enum Status: String, Codable, CaseIterable, Identifiable {
    case idea, inTransit, acquired, wrapped, given
    
    var title: String {
        switch self {
        case .idea:
            "Idea"
        case .inTransit:
            "In Transit"
        case .acquired:
            "Acquired"
        case .wrapped:
            "Wrapped"
        case .given:
            "Given"
        }
    }
    
    var icon: Image {
        switch self {
        case .idea:
            Image(systemName: "lightbulb")
        case .inTransit:
            Image(systemName: "truck.box")
        case .acquired:
            Image(systemName: "house")
        case .wrapped:
            Image(systemName: "gift")
        case .given:
            Image(systemName: "face.smiling")
        }
    }
    
    var id: Self { self }
    
    var sortPriority: Int {
        switch self {
        case .idea:
            5
        case .inTransit:
            4
        case .acquired:
            3
        case .wrapped:
            2
        case .given:
            1
        }
    }
}

@Model
final class Gift {
    
    var title: String?
    var sortOrder: Int?
    var price: Double?
    var notes: String?
    var recipient: Recipient?
    var event: Event?
    var status: Status?
    
    var amazonURL: URL? {
        guard let query = title?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        
        let domain = switch Locale.autoupdatingCurrent.region?.identifier {
        case "CA": "ca"
        default: "com"
        }
        return URL(string: "https://www.amazon.\(domain)/s?k=\(query)")!
    }
    
    init(title: String, sortOrder: Int, price: Double, notes: String? = nil, status: Status = .idea, recipient: Recipient? = nil, event: Event? = nil) {
        self.title = title
        self.sortOrder = sortOrder
        self.price = price
        self.notes = notes
        self.status = status
        self.recipient = recipient
        self.event = event
    }
    
}

extension [Gift] {
    func sorted() -> [Gift] {
        sorted(by: {
            let statusSortPriority0 = ($0.status ?? .idea).sortPriority
            let statusSortPriority1 = ($1.status ?? .idea).sortPriority
            
            if statusSortPriority0 == statusSortPriority1 {
                if (($0.price ?? 0) == ($1.price ?? 0)) {
                    return $0.title?.localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
                } else {
                    return (($0.price ?? 0) > ($1.price ?? 0))
                }
            } else {
                return statusSortPriority0 < statusSortPriority1
            }
        })
    }
}
