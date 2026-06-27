//
//  ShoppingList.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2023-10-22.
//

import SwiftUI
import SwiftData
#if canImport(AdmobSwiftUI)
import AdmobSwiftUI
#endif

struct ShoppingList: View {
    
    @Query private var gifts: [Gift]
    @Query(sort: \Event.name) private var events: [Event]
    
    @State private var eventFilter: Event? = nil
    @State private var showingManageEvents = false
    
    // Ads
    #if canImport(AdmobSwiftUI)
    @StateObject private var nativeViewModel = NativeAdViewModel(adUnitID: "ca-app-pub-8282547272443688/2759580531")
    #endif

    @Environment(\.modelContext) private var modelContext
    
    private var giftIdeas: [Gift] {
        gifts.filter({ $0.status == .idea && $0.recipient?.name != "<Me>" && (eventFilter == nil || $0.event == eventFilter) }).sorted()
    }
    
    var body: some View {
        Group {
            if giftIdeas.isEmpty {
                Text("No Gift Ideas").foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(giftIdeas.sorted()) { gift in
                        ShoppingRow(gift: gift)
                    }
                    
                    #if canImport(AdmobSwiftUI)
                    if #available(iOS 26.0, *), ExperienceManager.shared.shouldShowAds, giftIdeas.count >= 5 {
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
            }
        }
        .navigationTitle(title)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarTitleMenu {
            Picker("Event Filter", selection: $eventFilter) {
                ForEach(events) { event in
                    Text(event.name ?? "").tag(event as Event?)
                }
                Text("All").tag(nil as Event?)
            }
            
            Button("Manage Events", systemImage: "ellipsis") {
                showingManageEvents = true
            }
        }
        #endif
        .navigationDestination(for: Gift.self) { gift in
            GiftView(gift: gift)
        }
        .sheet(isPresented: $showingManageEvents) {
            NavigationStack {
                ManageEventsView()
            }
        }
    }
    
    private var title: String {
        if let name = eventFilter?.name {
            "\(name) Shopping"
        } else {
            "All Shopping"
        }
    }
    
}

#Preview {
    ShoppingList()
        #if DEBUG
        .modelContainer(previewContainer)
        #endif
}
