import SwiftUI
import SwiftData
import TipKit
import LocalAuthentication

struct AddRecipientTip: Tip {
    var title: Text { Text("Add a Recipient") }
    var message: Text? { Text("Create a list for each person you want to give gifts to.") }
    var image: Image? { nil }
}

struct GiftsListTab: View {
    
    @AppStorage(UserDefaults.Key.requireAuthenication) private var requireAuthenication = false
    @AppStorage(UserDefaults.Key.recipientSummaryInfo) private var recipientSummaryInfoValue = RecipientSummaryInfo.defaultInfo.rawValue
    @AppStorage(UserDefaults.Key.showEventWallpaper) private var showEventWallpaper = true
    @AppStorage(UserDefaults.Key.showHolidayCountdown) private var showHolidayCountdown = true
    @AppStorage(UserDefaults.Key.recipientSortBy) private var recipientSortByValue = RecipientSort.defaultSort.rawValue
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityAssistiveAccessEnabled) private var isAssistiveAccessEnabled
    
    @Query(filter: #Predicate<Recipient> { $0.name != "<Me>" }) var recipients: [Recipient]
    @Query(sort: \Event.name) var events: [Event]
    
    @State var recipientSortByPreference: RecipientSort
    @State var includeGivenGifts = false
    @State var showingNewGiftWithoutRecipient = false
    @State private var showingManageEvents = false
    #if os(macOS)
    let eventFilter: Event?
    #else
    @State var eventFilter: Event?
    #endif
    @State var newGiftSortOrder = 0
    @State var showingNewRecipient = false
    @State var newRecipientSortOrder = 0
    @State var editingRecipient: Recipient?
    @State var recipientName = ""
    
    /// Recipient which will be added to a new gift the user is creating
    @State var newGiftRecipient: Recipient?
    /// Recipient to generate Apple Intelligence gift ideas for
    @State var generatingIdeasRecipient: Recipient?
    
    init(eventFilter: Event? = nil) {
        self.recipientSortByPreference = .init(rawValue: UserDefaults.standard.string(forKey: UserDefaults.Key.recipientSortBy) ?? "") ?? .defaultSort
        self.eventFilter = eventFilter
    }
    
    private var biometryType: LABiometryType {
        LAContext().biometryType
    }

    #if !os(watchOS)
    private var addRecipientButton: some View {
        Button("Add Recipient", systemImage: "person.badge.plus") {
            newRecipientSortOrder = (recipients.max(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 0 })?.sortOrder ?? 0) + 1
            showingNewRecipient = true
        }
        .popoverTip(AddRecipientTip())
    }
    #endif

    var body: some View {
        Group {
            #if os(macOS)
            GiftsList(
                recipientSortByPreference: $recipientSortByPreference,
                includeGivenGifts: $includeGivenGifts,
                showingNewGiftWithoutRecipient: $showingNewGiftWithoutRecipient,
                showingManageEvents: $showingManageEvents,
                eventFilter: eventFilter,
                newGiftSortOrder: $newGiftSortOrder,
                showingNewRecipient: $showingNewRecipient,
                newRecipientSortOrder: $newRecipientSortOrder,
                editingRecipient: $editingRecipient,
                recipientName: $recipientName,
                newGiftRecipient: $newGiftRecipient,
                generatingIdeasRecipient: $generatingIdeasRecipient
            )
            #else
            GiftsList(
                recipientSortByPreference: $recipientSortByPreference,
                includeGivenGifts: $includeGivenGifts,
                showingNewGiftWithoutRecipient: $showingNewGiftWithoutRecipient,
                showingManageEvents: $showingManageEvents,
                eventFilter: $eventFilter,
                newGiftSortOrder: $newGiftSortOrder,
                showingNewRecipient: $showingNewRecipient,
                newRecipientSortOrder: $newRecipientSortOrder,
                editingRecipient: $editingRecipient,
                recipientName: $recipientName,
                newGiftRecipient: $newGiftRecipient,
                generatingIdeasRecipient: $generatingIdeasRecipient
            )
            #endif
        }
        .scrollContentBackground(eventWallpaper == nil ? .visible : .hidden)
        .background(alignment: .top) {
            backgroundView()
        }
        .headerProminence(.increased)
        #if !os(watchOS)
        .safeAreaInset(edge: .bottom) {
            countdownView()
        }
        #endif
        .navigationTitle(title)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarTitleMenu {
            Picker("Event Filter", selection: $eventFilter) {
                ForEach(events) { event in
                    Text(event.name ?? "")
                        .tag(event as Event?)
                }
                
                Text("All")
                    .tag(nil as Event?)
            }
            Button("Manage Events", systemImage: "ellipsis") {
                showingManageEvents = true
            }
        }
        #endif
        .toolbar {
            #if os(watchOS)
            ToolbarItem(placement: .topBarLeading) {
                Button("Add Recipient", systemImage: "person.badge.plus") {
                    showingNewRecipient = true
                }
            }
            #elseif os(macOS)
            ToolbarItem(placement: .primaryAction) {
                addRecipientButton
            }
            #else
            // The primary action stays pinned at the trailing edge no matter how tight the bar gets.
            ToolbarItem(placement: .topBarPinnedTrailing) {
                addRecipientButton
            }
            // Secondary settings always live in the overflow menu.
            ToolbarOverflowMenu {
                secondaryActions()
            }
            #endif
        }
        .sheet(isPresented: $showingNewGiftWithoutRecipient) {
            NavigationStack {
                NewGiftView(recipient: nil, sortOrder: newGiftSortOrder)
            }
        }
        .sheet(item: $newGiftRecipient) { recipient in
            NavigationStack {
                NewGiftView(recipient: recipient, sortOrder: newGiftSortOrder, event: eventFilter)
            }
        }
        .sheet(isPresented: $showingNewRecipient) {
            NavigationStack {
                NewRecipientView(sortOrder: newRecipientSortOrder)
            }
        }
        .sheet(item: $editingRecipient) { recipient in
            NavigationStack {
                RecipientView(recipient: recipient)
            }
        }
        #if canImport(FoundationModels) && !os(watchOS)
        .sheet(item: $generatingIdeasRecipient) { recipient in
            if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                NavigationStack {
                    GiftIdeasView(recipient: recipient)
                }
            }
        }
        #endif
        #if !os(watchOS)
        .sheet(isPresented: $showingManageEvents) {
            NavigationStack {
                ManageEventsView()
            }
        }
        #endif
        .onChange(of: recipientSortByPreference) { _, newValue in
            recipientSortByValue = newValue.rawValue
        }
        .task {
            await cleanupEvents()
        }
    }
    
    private var recipientSortBy: RecipientSort {
        if eventFilter?.specialCase == .birthday {
            .nearestBirthday
        } else {
            recipientSortByPreference
        }
    }
    
    private var title: String {
        if let name = eventFilter?.name {
            "\(name) Gifts"
        } else {
            "All Gifts"
        }
    }
    
    private var eventWallpaper: Image? {
        showEventWallpaper ? eventFilter?.specialCase?.wallpaper : nil
    }
    
    private var nextHoliday: Date? {
        let calendar = Calendar.current
        let holidayMonth = 12
        let holidayDay = 25
        let today = calendar.dateComponents([.year, .month, .day], from: .now)
        let year: Int = if today.month! < holidayMonth || (today.month == holidayMonth && today.day! < holidayDay) {
            today.year!
        } else {
            today.year! + 1
        }
        return calendar.date(from: DateComponents(year: year, month: holidayMonth, day: holidayDay))
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
    
    @ViewBuilder
    private func backgroundView() -> some View {
        eventWallpaper?
            .resizable()
            .scaledToFill()
            #if os(macOS)
            .overlay(Material.ultraThin, in: Rectangle())
            #elseif os(visionOS)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.6666), location: 0),
                        .init(color: .black.opacity(0), location: 0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            #endif
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func countdownView() -> some View {
        if showHolidayCountdown, eventFilter?.specialCase == .holidays, let nextHoliday {
            HStack {
                Text(nextHoliday, style: .relative)
                Text("left")
            }
            .font(.footnote)
            .foregroundStyle(showEventWallpaper ? Color.white : .primary)
            .padding()
        }
    }
    
    #if os(iOS) || os(visionOS)
    @ViewBuilder
    private func secondaryActions() -> some View {
        Toggle("Require \(biometryType.name ?? "")", systemImage: biometryType.systemImageName ?? "", isOn: $requireAuthenication)
        
        if eventFilter?.specialCase?.wallpaper != nil, !isAssistiveAccessEnabled {
            Toggle("Show Wallpaper", systemImage: "photo", isOn: $showEventWallpaper)
        }
        
        if eventFilter?.specialCase == .holidays, !isAssistiveAccessEnabled {
            Toggle("Show Countdown", systemImage: "timer", isOn: $showHolidayCountdown)
        }
        
        Section {
            Button(includeGivenGifts ? "Hide Given Gifts" : "Show Given Gifts", systemImage: includeGivenGifts ? "eye.slash" : "eye") {
                includeGivenGifts.toggle()
            }
            
            Picker(selection: $recipientSummaryInfoValue) {
                ForEach(RecipientSummaryInfo.allCases) { info in
                    Text(info.title)
                        .tag(info.rawValue)
                }
            } label: {
                Text("Recipient Shows")
                if let info = RecipientSummaryInfo(rawValue: recipientSummaryInfoValue) {
                    Text(info.title)
                }
                Image(systemName: "person")
            }
            
            if eventFilter?.specialCase != .birthday {
                Picker(selection: $recipientSortByPreference) {
                    ForEach(RecipientSort.allCases) { sort in
                        Text(sort.title)
                            .tag(sort)
                    }
                } label: {
                    Text("Sort By")
                    Text(recipientSortByPreference.title)
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .pickerStyle(.menu)
        
        if !isAssistiveAccessEnabled {
            // In submenu since there are already lots of menu items
            Menu("About App", systemImage: "info.circle") {
                Link(destination: URL(string: "https://www.256arts.com/")!) {
                    Label("Developer Website", systemImage: "safari")
                }
                Link(destination: URL(string: "https://www.256arts.com/joincommunity/")!) {
                    Label("Join Community", systemImage: "bubble.left.and.bubble.right")
                }
                Link(destination: URL(string: "https://github.com/256Arts/Gift-Lists")!) {
                    Label("Contribute on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
        }
    }
    #endif
    
}

#Preview {
    GiftsListTab()
        #if DEBUG
        .modelContainer(previewContainer)
        #endif
}
