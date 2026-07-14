import SwiftUI
import SwiftData

@Model
final class Event {
    
    enum SpecialCase: String, Codable {
        case birthday, holidays
        
        var icon: Image? {
            switch self {
            case .birthday:
                Image(systemName: "birthday.cake")
            case .holidays:
                Image(systemName: "snowflake")
            }
        }
        
//        @available(macOS, unavailable)
        var wallpaper: Image? {
            switch self {
            case .birthday:
                Image("birthday-background")
            case .holidays:
                Image("holidays-background")
            }
        }
    }
    
    /// Stable identifier used to reference this event from App Intents (Siri, Spotlight, Shortcuts).
    var identifier: UUID?
    var name: String?
    var date: Date?
    var specialCase: SpecialCase?
    var gifts: [Gift]?

    init(name: String, date: Date?, specialCase: SpecialCase? = nil) {
        self.identifier = UUID()
        self.name = name
        self.date = date
        self.specialCase = specialCase
        self.gifts = []
    }
    
}
