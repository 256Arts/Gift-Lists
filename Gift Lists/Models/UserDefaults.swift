//
//  UserDefaults.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2022-11-19.
//

import Foundation

extension UserDefaults {
    
    enum Key {
        static let giftsCreatedCount = "giftsCreatedCount"
        
        static let requireAuthenication = "requireAuthenication"
        static let recipientSummaryInfo = "recipientSummaryInfo"
        static let showEventWallpaper = "showEventWallpaper"
        static let showHolidayCountdown = "showHolidayCountdown"
        static let recipientSortBy = "recipientSortBy"
        static let giftSortBy = "giftSortBy"
    }
    
}
