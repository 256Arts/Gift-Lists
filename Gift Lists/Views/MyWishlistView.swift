//
//  MyWishlistView.swift
//  Holiday Gifts List
//
//  Created by 256 Arts Developer on 2024-12-04.
//

import SwiftUI
import SwiftData
#if canImport(AdmobSwiftUI)
import AdmobSwiftUI
#endif

struct MyWishlistView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Recipient> { $0.name == "<Me>" }) var mes: [Recipient]
    @Query var gifts: [Gift]
    
    @State var showingNewGift = false
    @State var newGiftSortOrder = 0
    
    // Ads
    #if canImport(AdmobSwiftUI)
    @StateObject private var nativeViewModel = NativeAdViewModel(adUnitID: "ca-app-pub-8282547272443688/3840728576")
    #endif
    
    var me: Recipient? {
        mes.first
    }
    
    var body: some View {
        List {
            ForEach(me?.gifts?.sorted() ?? []) { gift in
                GiftRow(gift: gift, showStatus: false)
            }
            
            Button("New Gift", systemImage: "plus") {
                if me == nil {
                    modelContext.insert(Recipient(name: Recipient.userName, sortOrder: -1))
                }
                newGiftSortOrder = (gifts.max(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 0 })?.sortOrder ?? 0) + 1
                showingNewGift = true
            }
            #if os(watchOS)
            .foregroundStyle(.tint)
            #endif
            
            #if canImport(AdmobSwiftUI)
            if #available(iOS 26.0, *), ExperienceManager.shared.shouldShowAds, me?.gifts?.count ?? 0 >= 5 {
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
        .headerProminence(.increased)
        .navigationTitle("My Wishlist")
        .sheet(isPresented: $showingNewGift) {
            NavigationStack {
                NewGiftView(recipient: me, sortOrder: newGiftSortOrder)
            }
        }
    }
}
