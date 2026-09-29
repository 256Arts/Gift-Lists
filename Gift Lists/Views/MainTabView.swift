import SwiftUI
import SwiftData

/// Which tab is showing. Only exists so something outside the view — a widget's deep link — can
/// choose one.
enum MainTab: Hashable {
    case gifts
    case wishlist
    case shopping
    #if os(macOS)
    /// macOS gives every event its own tab; iOS and visionOS filter within the one gifts tab.
    case event(PersistentIdentifier)
    #endif

    /// The tab a `giftlists://` link asks for, or `nil` if it asks for something else.
    init?(url: URL) {
        switch url.host() {
        case "wishlist":
            self = .wishlist
        case "shopping":
            self = .shopping
        case "gifts":
            self = .gifts
        default:
            return nil
        }
    }
}

struct MainTabView: View {

    @Query(sort: \Event.name) var events: [Event]

    @State private var selection = MainTab.gifts

    var body: some View {
        TabView(selection: $selection) {
            #if os(macOS)
            Tab("All Gifts", systemImage: "gift", value: MainTab.gifts) {
                NavigationStack {
                    GiftsListTab()
                }
            }

            ForEach(events) { event in
                Tab("\(event.name ?? "") Gifts", systemImage: "gift", value: MainTab.event(event.persistentModelID)) {
                    NavigationStack {
                        GiftsListTab(eventFilter: event)
                    }
                }
            }

            TabSection {
                Tab("My Wishlist", systemImage: "heart", value: MainTab.wishlist) {
                    NavigationStack {
                        MyWishlistView()
                    }
                }

                Tab("Shopping List", systemImage: "list.bullet", value: MainTab.shopping) {
                    NavigationStack {
                        ShoppingList()
                    }
                }
            }
            #else
            Tab("Gifts", systemImage: "gift", value: MainTab.gifts) {
                NavigationStack {
                    GiftsListTab()
                }
            }

            Tab("My Wishlist", systemImage: "heart", value: MainTab.wishlist) {
                NavigationStack {
                    MyWishlistView()
                }
            }

            Tab("Shopping List", systemImage: "list.bullet", value: MainTab.shopping) {
                NavigationStack {
                    ShoppingList()
                }
            }
            #endif
        }
//        #if os(iOS)
//        .tabBarMinimizeBehavior(.onScrollDown)
        #if os(macOS)
        .tabViewStyle(.sidebarAdaptable)
        .task {
            await ScreenshotMode.pinSidebarWidth()
        }
        #endif
        // Tapping a widget lands on the list it was showing. The universal link the app handles for
        // App Store events is a different scheme and falls through to `GiftListsApp`.
        .onOpenURL { url in
            if let tab = MainTab(url: url) {
                selection = tab
            }
        }
    }
}

#Preview {
    MainTabView()
}
