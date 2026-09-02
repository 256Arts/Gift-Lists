import SwiftUI
import SwiftData

struct MainTabView: View {
    
    @Query(sort: \Event.name) var events: [Event]
    
    var body: some View {
        TabView {
            #if os(macOS)
            Tab("All Gifts", systemImage: "gift") {
                NavigationStack {
                    GiftsListTab()
                }
            }
            
            ForEach(events) { event in
                Tab("\(event.name ?? "") Gifts", systemImage: "gift") {
                    NavigationStack {
                        GiftsListTab(eventFilter: event)
                    }
                }
            }
            
            TabSection {
                Tab("My Wishlist", systemImage: "heart") {
                    NavigationStack {
                        MyWishlistView()
                    }
                }
                
                Tab("Shopping List", systemImage: "list.bullet") {
                    NavigationStack {
                        ShoppingList()
                    }
                }
            }
            #else
            Tab("Gifts", systemImage: "gift") {
                NavigationStack {
                    GiftsListTab()
                }
            }
            
            Tab("My Wishlist", systemImage: "heart") {
                NavigationStack {
                    MyWishlistView()
                }
            }
            
            Tab("Shopping List", systemImage: "list.bullet") {
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
    }
}

#Preview {
    MainTabView()
}
