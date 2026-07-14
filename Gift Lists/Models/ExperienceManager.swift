import AppTrackingTransparency

/// Manages flags determining how ads and app review requests behave
final class ExperienceManager {
    
    static let shared = ExperienceManager()
    
    let giftCountsToAskForReview = [5, 20, 50, 100]
    
    var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    var shouldShowAds: Bool {
        #if canImport(AdmobSwiftUI)
        #if DEBUG
        // Devices running debug builds should expose their tracking ID to Google to meet TOS
        trackingAuthorizationStatus == .authorized
        #else
        // Enable ads after the 1st app review request
        UserDefaults.standard.integer(forKey: UserDefaults.Key.giftsCreatedCount) > giftCountsToAskForReview.first!
        #endif
        #else
        false
        #endif
    }
    
}
