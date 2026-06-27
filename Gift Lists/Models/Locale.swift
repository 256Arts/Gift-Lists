//
//
//  Locale.swift
//  Gift Lists
//
//  Created by 256 Arts on 2025-11-17.
//
       
import Foundation

extension Locale {
    
    var currencyID: String {
        currency?.identifier ?? "USD"
    }
    
}
