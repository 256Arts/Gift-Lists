import AppTrackingTransparency
#if canImport(AdmobSwiftUI)
import AdmobSwiftUI
#endif

/// Manages flags determining how ads and app review requests behave
final class ExperienceManager {
    
    static let shared = ExperienceManager()
    
    let giftCountsToAskForReview = [5, 20, 50, 100]
    
    var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    #if canImport(AdmobSwiftUI)
    private var adsStarted = false
    
    /// Asks for tracking consent, then starts the Google Mobile Ads SDK — never the reverse, as the
    /// SDK collects device data the moment it starts. Call once the scene is active: the system
    /// silently skips the prompt otherwise, so an undetermined result waits for the next activation.
    @MainActor
    func requestTrackingThenStartAds() async {
        guard !adsStarted else { return }
        trackingAuthorizationStatus = await ATTrackingManager.requestTrackingAuthorization()
        guard trackingAuthorizationStatus != .notDetermined else { return }
        adsStarted = true
        AdmobSwiftUI.initialize()
    }
    #endif
    
    var shouldShowAds: Bool {
        #if canImport(AdmobSwiftUI)
        // Loading an ad would start the SDK itself, ahead of the tracking prompt
        guard adsStarted else { return false }
        #if DEBUG
        // Devices running debug builds should expose their tracking ID to Google to meet TOS
        return trackingAuthorizationStatus == .authorized
        #else
        // Enable ads after the 1st app review request
        return UserDefaults.standard.integer(forKey: UserDefaults.Key.giftsCreatedCount) > giftCountsToAskForReview.first!
        #endif
        #else
        return false
        #endif
    }
    
}
