# Gift Lists

Track gift ideas, who they're for, and the occasions they're for — from idea to wrapped to given — with a shopping list across every event and a wishlist of your own.

[Download on the App Store](https://apps.apple.com/app/holiday-gifts-list/id6444738623)

## Platforms

iOS, iPadOS, macOS, and visionOS (one multiplatform app), a watchOS companion, and Home Screen widgets. Requires the 26 releases. Data syncs through iCloud.

## Building

Open `Gift Lists.xcodeproj` and run the **Gift Lists** scheme (**Gift Lists Watch App** for the watch). Ads come from the optional `AdmobSwiftUI` package, gated behind `canImport`, so the app builds without it.

Unit tests: `xcodebuild test -project "Gift Lists.xcodeproj" -scheme "Gift Lists" -destination 'platform=macOS' -only-testing:GiftListsTests`

App Store screenshots: `Scripts/screenshots.sh` (needs the shared runner from the `Scripts` repo beside this one).

See [AGENTS.md](AGENTS.md) for architecture and conventions.
