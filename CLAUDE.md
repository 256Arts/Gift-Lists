# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Gift Lists (bundle id `com.jaydenirwin.holidaygiftslist`, internally "Holiday Gifts List") is a SwiftUI app for tracking gifts, recipients, and gifting events. It is a single Xcode project with two targets: the main multiplatform app (iOS, macOS, visionOS) and a companion watchOS app. There is no Swift Package manifest — dependencies are managed through the Xcode project.

## Build & Run

This is an Xcode project (`Gift Lists.xcodeproj`); there is no test target. Schemes: `Gift Lists` (main app) and `Gift Lists Watch App`. Normally just build and run from Xcode, or via `xcodebuild -project "Gift Lists.xcodeproj" -scheme "Gift Lists" build`.

## Architecture

**Persistence is SwiftData.** The three `@Model` classes — `Gift`, `Recipient`, `Event` — are the entire data layer. There are no view models or repositories; views query and mutate the model context directly via `@Query` / `@Environment(\.modelContext)`.

- A `Gift` belongs to an optional `Recipient` and an optional `Event`, and has a `Status` (idea → inTransit → acquired → wrapped → given). Custom `Array` sort extensions (`[Gift].sorted()`, `[Recipient].sorted(by:)`) encode the display ordering rules — status priority then price then name for gifts; user-selectable sort for recipients.
- `Recipient` uses the sentinel name `"<Me>"` (see `Recipient.userName` / `isMe`) to represent the user's own wishlist. The "My Wishlist" tab filters on this. Birthday-related computed properties are `@Transient`.
- **All model properties are optional.** This is a SwiftData lightweight-migration requirement — preserve it when adding properties, and handle nil throughout (the existing code uses `??` defaults extensively).

**Model container selection is environment-dependent**: the simulator (and macOS DEBUG) loads `previewContainer` (in-memory, seeded with sample data from `Preview Content/PreviewContainer.swift`), while real devices use a persistent CloudKit-backed container. The iOS/macOS/visionOS app routes this through one accessor — `sharedModelContainer` (`App Intents/SharedModelContainer.swift`) — so the SwiftUI scene and the App Intents read/write the same store. (`GiftListsWatchApp` still inlines its own container, with a leaner `[Gift, Recipient]` schema.) When changing the model schema, update `PreviewContainer.swift` too or previews/simulator runs will break.

**App Intents power Siri / Spotlight / Shortcuts** (`App Intents/`, main app only — excluded from the watch target via `project.pbxproj` membership exceptions). `Gift`/`Recipient`/`Event` each expose an `AppEntity` + `EntityStringQuery` keyed by a stable `identifier: UUID?` added to the model (legacy nil records are backfilled lazily via `ensuredIdentifier`); `Status` is an `AppEnum`. Action intents (`AddGiftIntent`, `AddRecipientIntent`, `MarkGiftStatusIntent`) run `@MainActor` against `sharedModelContainer.mainContext`; `GiftListsShortcuts` registers the spoken phrases. Keep this code platform-agnostic enough to compile, but it is excluded from watchOS — add new intent files to the watch membership-exception list in the project file.

**Settings are `@AppStorage`** keyed by string constants centralized in `UserDefaults.Key` (`Models/UserDefaults.swift`). On macOS these are surfaced as menu-bar commands in `GiftListsApp`; add new keys there to keep them in one place.

**Platform branching is pervasive via `#if os(...)`.** macOS uses a sidebar `TabView` with a per-event tab plus All Gifts/Wishlist/Shopping; iOS/visionOS use a flatter three-tab layout (see `MainTabView`). Expect to handle macOS separately for navigation, window sizing, and wallpaper behavior.

**Privacy/biometric gating:** `BiometricAuthentication` (Face ID / Touch ID) blurs the UI via `.redacted(reason: .privacy)` until authenticated, re-locking on background. Controlled by the `requireAuthenication` setting (note the existing spelling of that key — match it).

**Ads & app review** are centralized in `ExperienceManager` (singleton). Ads come from the optional `AdmobSwiftUI` dependency, gated behind `#if canImport(AdmobSwiftUI)` so the app builds and runs without it. `shouldShowAds` and review-prompt thresholds (`giftCountsToAskForReview`, keyed on `giftsCreatedCount`) live here — don't scatter this logic into views.

## Conventions

- File naming follows SwiftData/SwiftUI roles: `Models/` holds `@Model` types and shared enums/extensions; `Views/` holds SwiftUI views, with `*Row` views for list cells and `New*View` for creation sheets.
- Keep new ad/tracking code inside `#if canImport(AdmobSwiftUI)` guards so non-ad builds keep working.
- `Gift.amazonURL` builds a region-aware Amazon search link — region logic lives on the model, not in views.
