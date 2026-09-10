import SwiftUI
import SwiftData
#if canImport(AdmobSwiftUI)
import AdmobSwiftUI
#endif
        
struct GiftsList: View {
    
    @AppStorage(UserDefaults.Key.recipientSummaryInfo) private var recipientSummaryInfoValue = RecipientSummaryInfo.defaultInfo.rawValue
    @AppStorage(UserDefaults.Key.recipientSortBy) private var recipientSortByValue = RecipientSort.defaultSort.rawValue
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Recipient> { $0.name != "<Me>" }) var recipients: [Recipient]
    @Query var gifts: [Gift]
    @Query(sort: \Event.name) var events: [Event]
    
    @Binding var recipientSortByPreference: RecipientSort
    @Binding var includeGivenGifts: Bool
    @Binding var showingNewGiftWithoutRecipient: Bool
    @Binding var showingManageEvents: Bool
    #if os(macOS)
    let eventFilter: Event?
    #else
    @Binding var eventFilter: Event?
    #endif
    @Binding var newGiftSortOrder: Int
    @Binding var showingNewRecipient: Bool
    @Binding var newRecipientSortOrder: Int
    @Binding var editingRecipient: Recipient?
    @Binding var recipientName: String
    
    /// Recipient which will be added to a new gift the user is creating
    @Binding var newGiftRecipient: Recipient?
    /// Recipient to generate Apple Intelligence gift ideas for
    @Binding var generatingIdeasRecipient: Recipient?
    
    // Ads
    #if canImport(AdmobSwiftUI)
    @StateObject private var nativeViewModel = NativeAdViewModel(adUnitID: "ca-app-pub-8282547272443688/2273313611")
    #endif
    
    private var giftsWithoutRecipients: [Gift] {
        ((try? gifts.filter(#Predicate<Gift> {
            $0.recipient == nil
        })) ?? []).sorted()
    }
    
    var body: some View {
        List {
            ForEach(displayedRecipients) { recipient in
                #if os(watchOS)
                Section {
                    ForEach(filterAndSort(recipient.gifts ?? [])) { gift in
                        GiftRow(gift: gift, showStatus: true)
                    }

                    Button("New Gift", systemImage: "plus") {
                        newGiftSortOrder = (gifts.max(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 0 })?.sortOrder ?? 0) + 1
                        newGiftRecipient = recipient
                    }
                    .foregroundStyle(.tint)
                } header: {
                    RecipientRow(recipient: recipient, showBirthday: recipientSortBy == .nearestBirthday, filteredGifts: filterAndSort(recipient.gifts ?? []), recipientName: $recipientName, editingRecipient: $editingRecipient)
                }
                #else
                Section {
                    DisclosureGroup {
                        ForEach(filterAndSort(recipient.gifts ?? [])) { gift in
                            GiftRow(gift: gift, showStatus: true)
                        }
                        
                        HStack {
                            Button("New Gift", systemImage: "plus") {
                                newGiftSortOrder = (gifts.max(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 0 })?.sortOrder ?? 0) + 1
                                newGiftRecipient = recipient
                            }

                            #if canImport(FoundationModels) && !os(watchOS)
                            if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *), GiftIdeaGenerator.isAvailable {
                                Spacer()
                                
                                Button("Generate Ideas", systemImage: "apple.intelligence") {
                                    generatingIdeasRecipient = recipient
                                }
                                .labelStyle(.iconOnly)
                            }
                            #endif
                        }
                        .buttonStyle(.borderless)
                    } label: {
                        RecipientRow(
                            recipient: recipient,
                            showBirthday: recipientSortBy == .nearestBirthday,
                            filteredGifts: filterAndSort(recipient.gifts ?? []),
                            recipientName: $recipientName,
                            editingRecipient: $editingRecipient
                        )
                    }
                }
                #endif
            }
            
            #if !os(watchOS)
            // Same reason as `displayedRecipients`: an empty bucket is dead space in a screenshot.
            if !ScreenshotMode.isActive || !filterAndSort(giftsWithoutRecipients).isEmpty {
                DisclosureGroup {
                    ForEach(filterAndSort(giftsWithoutRecipients)) { gift in
                        GiftRow(gift: gift, showStatus: true)
                    }
                    
                    Button("New Gift", systemImage: "plus") {
                        newGiftSortOrder = (gifts.max(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 0 })?.sortOrder ?? 0) + 1
                        showingNewGiftWithoutRecipient = true
                    }
                } label: {
                    Label("Gifts with no Recipient", systemImage: "person.slash.fill")
                        .fontWeight(.medium)
                        .foregroundStyle(filterAndSort(giftsWithoutRecipients).isEmpty ? .secondary : .primary)
                }
            }
            #endif
            
            #if canImport(AdmobSwiftUI)
            if #available(iOS 26.0, *), ExperienceManager.shared.shouldShowAds, recipients.count >= 3 {
                Section {
                    NativeAdView(nativeViewModel: nativeViewModel, style: .banner)
                        .frame(height: 100)
                        .listRowInsets(.all, 0)
                        .onAppear {
                            nativeViewModel.refreshAd()
                        }
                }
            }
            #endif
        }
        #if !os(macOS)
        .listSectionSpacing(.compact)
        #endif
    }
    
    /// The recipients the list rows, in display order.
    ///
    /// Screenshot runs cast a different set of recipients for each event, so that the holiday and
    /// birthday shots read as different lists; a recipient with nothing for the filtered event is
    /// dropped there rather than photographed as an empty row. The real app keeps everyone, so that
    /// filtering to an event still shows who is on the list but has nothing yet.
    private var displayedRecipients: [Recipient] {
        let sorted = recipients.sorted(by: recipientSortBy)
        guard ScreenshotMode.isActive, eventFilter != nil else { return sorted }
        return sorted.filter { !filterAndSort($0.gifts ?? []).isEmpty }
    }
    
    private var recipientSortBy: RecipientSort {
        if eventFilter?.specialCase == .birthday {
            .nearestBirthday
        } else {
            recipientSortByPreference
        }
    }
    
    private func filterAndSort(_ gifts: [Gift]) -> [Gift] {
        gifts
            .filter { includeGivenGifts || $0.status != .given }
            .filter { eventFilter == nil || eventFilter == $0.event }
            .sorted()
    }
    
    private func cleanupEvents() async {
        // Wait for sync
        try? await Task.sleep(for: .seconds(1))
        
        if events.isEmpty {
            modelContext.insert(Event(name: "Birthday", date: .distantPast, specialCase: .birthday))
            modelContext.insert(Event(name: "Holidays", date: Calendar.current.date(from: DateComponents(month: 12, day: 25)), specialCase: .holidays))
        }
        
        // Older app versions will not have the special cases set
        if let birth = events.first(where: { $0.name == "Birthday" }) {
            birth.specialCase = .birthday
        }
        if let holly = events.first(where: { $0.name == "Holidays" }) {
            holly.specialCase = .holidays
        }
        
        // Remove duplicates
        let birthdayEvents = events.filter({ $0.specialCase == .birthday })
        for (index, event) in birthdayEvents.enumerated() {
            if index == 0 {
                // Skip first event, as this one is valid
                continue
            } else {
                modelContext.delete(event)
            }
        }
        
        let holidaysEvents = events.filter({ $0.specialCase == .holidays })
        for (index, event) in holidaysEvents.enumerated() {
            if index == 0 {
                // Skip first event, as this one is valid
                continue
            } else {
                modelContext.delete(event)
            }
        }
    }
    
}
