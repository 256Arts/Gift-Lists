import SwiftUI
import WidgetKit

@main
struct GiftListsWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShoppingWidget()
        WishlistWidget()
    }
}
