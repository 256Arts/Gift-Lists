# Gift Lists

<img src="https://www.256arts.com/giftlists/icon_giftslist.png" alt="Gift Lists icon" width="128" align="right">

Track gift ideas, who they're for, and the occasions they're for — from idea to wrapped to given — with a shopping list across every event and a wishlist of your own.

[Download on the App Store](https://apps.apple.com/app/holiday-gifts-list/id6444738623) · [256arts.com/giftlists](https://www.256arts.com/giftlists/)

<img src="https://www.256arts.com/giftlists/shot1.webp" alt="The gift list filtered to the holidays, with a wallpaper and countdown" width="300"> <img src="https://www.256arts.com/giftlists/shot4.webp" alt="The Shopping List tab showing gifts still to buy across every event" width="300">

## Features

- **Apple Intelligence gift ideas** — generate specific, purchasable suggestions tailored to a recipient's age, interests, budget, and occasion, without repeating past or current gifts.
- **Budgets and prices** — set a spending goal per recipient and track estimated or actual prices per gift.
- **Shopping List** — every gift still to buy, across every recipient and event, in one list.
- **My Wishlist** — keep your own wishlist alongside everyone else's.
- **Gift status tracking** — move gifts from idea to in transit, acquired, wrapped, and given.
- **Face ID lock** — optionally require Face ID or Touch ID to open the app.
- **Siri & Shortcuts** — add a gift or recipient, or change a gift's status, by voice or Shortcuts.
- **Widgets and Apple Watch** — Home Screen widgets for the Shopping List and My Wishlist, plus a watchOS companion app.
- iPhone, iPad, Mac, Apple Vision Pro, and Apple Watch.

## Building

Open `Gift Lists.xcodeproj` and run the **Gift Lists** scheme (**Gift Lists Watch App** for the watch). Ads come from the optional `AdmobSwiftUI` package, gated behind `canImport`, so the app builds without it.

Unit tests: `xcodebuild test -project "Gift Lists.xcodeproj" -scheme "Gift Lists" -destination 'platform=macOS' -only-testing:GiftListsTests`

App Store screenshots: `Scripts/screenshots.sh` (needs the shared runner from the `Scripts` repo beside this one).

See [AGENTS.md](AGENTS.md) for architecture and conventions.
