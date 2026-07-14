import Foundation

extension Locale {
    
    var currencyID: String {
        currency?.identifier ?? "USD"
    }
    
}
