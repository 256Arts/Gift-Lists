import SwiftUI

/// A gift's product photo, cropped to a rounded square.
struct GiftThumbnail: View {

    let data: Data
    var size: CGFloat = 36

    var body: some View {
        if let image = LinkPreview.image(from: data) {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(.rect(cornerRadius: size / 5))
                .privacySensitive()
        }
    }
}
