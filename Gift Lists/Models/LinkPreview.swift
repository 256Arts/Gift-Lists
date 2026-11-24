import Foundation
import ImageIO
import LinkPresentation
import UniformTypeIdentifiers

/// What a product link's preview offers a gift: a title for an untitled gift, and a thumbnail.
struct LinkPreview {

    /// The longest edge, in pixels, of a stored thumbnail — sharp at the row's size on a 3x screen
    /// while staying small enough to sync quickly.
    static let thumbnailPixelSize = 300

    var title: String?
    var imageData: Data?

    /// Fetches the page's link preview. Throws if the page can't be loaded; a page without a title
    /// or an image just leaves that field nil.
    @MainActor
    static func fetch(for url: URL) async throws -> LinkPreview {
        let provider = LPMetadataProvider()
        provider.shouldFetchSubresources = true
        let metadata = try await provider.startFetchingMetadata(for: url)

        var imageData: Data?
        if let imageProvider = metadata.imageProvider {
            imageData = try? await imageProvider.loadData(for: .image).flatMap(thumbnail(from:))
        }
        return LinkPreview(title: metadata.title, imageData: imageData)
    }

    /// Downscales an image to `thumbnailPixelSize` and re-encodes it as JPEG.
    static func thumbnail(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    /// Decodes stored image data for display.
    static func image(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

private extension NSItemProvider {
    func loadData(for type: UTType) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadDataRepresentation(for: type) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data)
                }
            }
        }
    }
}
