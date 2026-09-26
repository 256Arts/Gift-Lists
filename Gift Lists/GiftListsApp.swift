import SwiftUI
import SwiftData
import TipKit
import LocalAuthentication
#if canImport(AdmobSwiftUI)
import AdmobSwiftUI
#endif

@main
struct GiftListsApp: App {
    
    @AppStorage(UserDefaults.Key.requireAuthenication) private var requireAuthenication = false
    @AppStorage(UserDefaults.Key.recipientSummaryInfo) private var recipientSummaryInfoValue = RecipientSummaryInfo.defaultInfo.rawValue
    @AppStorage(UserDefaults.Key.showEventWallpaper) private var showEventWallpaper = true
    @AppStorage(UserDefaults.Key.showHolidayCountdown) private var showHolidayCountdown = true
    @AppStorage(UserDefaults.Key.recipientSortBy) private var recipientSortByValue = RecipientSort.defaultSort.rawValue
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var biometrics = BiometricAuthentication()
    @State private var showingEvent = false
    
    private var biometryType: LABiometryType {
        LAContext().biometryType
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .redacted(reason: biometrics.isAuthenticated ? [] : .privacy)
                .task {
                    // A screenshot run skips all of this: a tip popover or the tracking alert would
                    // land on top of a shot, and the demo data has no business in Spotlight.
                    guard !ScreenshotMode.isActive else { return }
                    
                    // Configure and load your tips at app launch.
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])

                    // Surface gifts, recipients, and events to Spotlight / Siri.
                    await SpotlightIndexer.reindexAll()
                }
                .task {
                    // A screenshot run writes to a throwaway store; reloading the widgets off it
                    // would push demo gifts onto the machine taking the shots.
                    guard !ScreenshotMode.isActive else { return }
                    await WidgetRefresh.observeSaves()
                }
                .alert("Event Intro", isPresented: $showingEvent) {
                    Button("OK") { }
                } message: {
                    Text("Now let's celebrate by adding some gifts to the list and trying out the new features!")
                }
                .onOpenURL { url in
                    if url.path().contains("giftlists/appstoreevent") {
                        showingEvent = true
                    }
                }
                .screenshotModeStatus()
        }
        #if os(macOS)
        .defaultSize(CGSize(width: 600, height: 600))
        #else
        .defaultSize(CGSize(width: 500, height: 700))
        #endif
        .commands {
            CommandGroup(after: .newItem) {
                Toggle("Require \(biometryType.name ?? "")", systemImage: biometryType.systemImageName ?? "", isOn: $requireAuthenication)
            }
            
            CommandGroup(before: .toolbar) {
                Toggle("Show Wallpaper", systemImage: "photo", isOn: $showEventWallpaper)
                
                Toggle("Show Countdown", systemImage: "timer", isOn: $showHolidayCountdown)
                
                StatusFilterMenu()
                
                Picker("Recipient Shows", systemImage: "person", selection: $recipientSummaryInfoValue) {
                    ForEach(RecipientSummaryInfo.allCases) { info in
                        Text(info.localizedTitle)
                            .tag(info.rawValue)
                    }
                }
                
                Picker("Sort By", systemImage: "arrow.up.arrow.down", selection: $recipientSortByValue) {
                    ForEach(RecipientSort.allCases) { sort in
                        Text(sort.localizedTitle)
                            .tag(sort.rawValue)
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                Task {
                    await biometrics.authenticate()
                    // After unlocking, so the Face ID sheet can't swallow the tracking prompt
                    #if canImport(AdmobSwiftUI)
                    guard !ScreenshotMode.isActive else { return }
                    await ExperienceManager.shared.requestTrackingThenStartAds()
                    #endif
                }
            case .background:
                #if !os(macOS)
                biometrics.isAuthenticated = false
                #endif
            default:
                break
            }
        }
    }
}
