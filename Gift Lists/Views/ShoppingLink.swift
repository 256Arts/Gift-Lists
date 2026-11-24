import SwiftUI

/// Opens the gift's product link, or searches Amazon for its title when it has none.
struct ShoppingLink: View {

    let gift: Gift

    var body: some View {
        if let url = gift.url {
            Link(destination: url) {
                Label("Open Link", systemImage: "link")
            }
        } else if let url = gift.amazonURL {
            Link(destination: url) {
                Label("Search Amazon", systemImage: "magnifyingglass")
            }
        }
    }
}
