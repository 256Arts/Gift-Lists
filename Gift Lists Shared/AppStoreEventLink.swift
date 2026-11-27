import Foundation

/// Parses the universal link an App Store in-app event opens:
/// `https://www.256arts.com/giftlists/appstoreevent`, with optional `title` and `destination`
/// query items. Lives in `Gift Lists Shared` (rather than with the rest of the app's URL handling)
/// so `GiftListsTests` — which only compiles this folder — can cover it directly.
///
/// Visiting the link never reads or writes model data; it only decides what the app should show.
struct AppStoreEventLink {

    /// An allowlisted, stable screen id — never a localized or display string. New cases must stay
    /// lowerCamelCase and keep their raw value once shipped, since App Store event schedules are
    /// authored against it ahead of time.
    enum Destination: String {
        case gifts
        case wishlist
        case shopping
    }

    /// The event's user-visible heading, already percent-decoded plain text — never a localization key.
    let title: String?

    /// `nil` when the link omits `destination` or sends a value outside the allowlist; callers should
    /// fall back to their generic intro rather than failing.
    let destination: Destination?

    init?(url: URL) {
        guard url.scheme == "https",
              url.host()?.lowercased() == "www.256arts.com",
              url.path() == "/giftlists/appstoreevent",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }

        let queryItems = components.queryItems ?? []
        // Last occurrence wins on a duplicated param, rather than erroring.
        let rawTitle = queryItems.last(where: { $0.name == "title" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines)
        title = (rawTitle?.isEmpty == false) ? rawTitle : nil
        destination = queryItems.last(where: { $0.name == "destination" })?.value.flatMap(Destination.init)
    }

}
