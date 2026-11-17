import SwiftUI
import CoreLocation

// One place a Companion has been. Only a city or a public place is ever stored, never a street address.
struct Stop: Identifiable, Hashable {
    let id = UUID()
    var city: String
    var place: String? = nil          // e.g. "Café on the plaza" (only for public places)
    var latitude: Double
    var longitude: Double
    var leftBy: String? = nil         // traveler nickname
    var when: String = ""
    var note: String? = nil           // the traveler's chapter

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum CompanionStatus: String, CaseIterable, Hashable {
    case moving       // moved recently
    case waiting      // left somewhere, waiting to be found
    case quiet        // no log for 2 months
    case adopted      // found a home
    case retired      // journey ended (broke or lost)

    var label: String {
        switch self {
        case .moving: return "On the move"
        case .waiting: return "Waiting to be found"
        case .quiet: return "Quiet lately"
        case .adopted: return "Adopted"
        case .retired: return "Retired"
        }
    }
}

struct Companion: Identifiable, Hashable {
    let number: String                 // "07", "2", …
    var name: String? = nil            // written by The Herd; shown as "#07" until set
    var glaze: String                  // figure colour
    var accent: String                 // map dot colour
    var blob: String                   // soft background colour
    var isOriginal: Bool = false
    var status: CompanionStatus = .moving
    var wish: String                   // "see the ocean"
    var wishGranted: Bool = false
    var lastMoved: String              // "3 days ago"
    var movedThisWeek: Bool = false
    var stops: [Stop]
    var travelers: Int
    var blurb: String = "A short blurb about this Companion, the same words printed on the tiny scroll they carry."
    var originStory: String = "Their origin story, written by The Herd: the same words on their tiny scroll."

    var id: String { number }
    var displayName: String { name ?? "#\(number)" }
    var label: String { "#\(number) · \(displayName)" }
    var glazeColor: Color { Color(hex: glaze) }
    var accentColor: Color { Color(hex: accent) }
    var blobColor: Color { Color(hex: blob) }
    var current: Stop? { stops.last }
    var wishSentence: String { "I want to \(wish)." }
    var shareURL: URL { URL(string: "https://theherdstudio.com/c/\(number)")! }

    var miles: Int {
        guard stops.count > 1 else { return 0 }
        var meters: Double = 0
        for i in 1..<stops.count {
            let a = CLLocation(latitude: stops[i - 1].latitude, longitude: stops[i - 1].longitude)
            let b = CLLocation(latitude: stops[i].latitude, longitude: stops[i].longitude)
            meters += a.distance(from: b)
        }
        return Int(meters / 1609.34)
    }

    var stopCount: Int { max(stops.count - 1, 0) }   // the first entry is the studio in Aurora
}

// Filters on the map, matching the website map's colours.
enum MapFilter: String, CaseIterable, Identifiable {
    case all, following, nearMe, originals, movedThisWeek, waiting, quiet, adopted, retired, wishesGranted

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .following: return "Following"
        case .nearMe: return "Near me"
        case .originals: return "Originals #0–5"
        case .movedThisWeek: return "Moved this week"
        case .waiting: return "Waiting to be found"
        case .quiet: return "Quiet lately"
        case .adopted: return "Adopted"
        case .retired: return "Retired"
        case .wishesGranted: return "Wishes granted"
        }
    }

    var background: String {
        switch self {
        case .all, .following, .nearMe: return "FDF8F3"
        case .originals: return "FBE4E2"
        case .movedThisWeek: return "DDF0E8"
        case .waiting: return "DCEAF5"
        case .quiet: return "EDE6DC"
        case .adopted: return "E6DDF5"
        case .retired: return "F8DCC8"
        case .wishesGranted: return "F9EBB5"
        }
    }

    var foreground: String {
        switch self {
        case .all, .following, .nearMe: return "3F5A4C"
        case .originals: return "6B3F3A"
        case .movedThisWeek: return "2F4A3D"
        case .waiting: return "2D4A63"
        case .quiet: return "4A4440"
        case .adopted: return "4A3D63"
        case .retired: return "6B4430"
        case .wishesGranted: return "5A4C1E"
        }
    }

    var dot: String? {
        switch self {
        case .all, .following, .nearMe: return nil
        case .originals: return "D98C86"
        case .movedThisWeek: return "6BBFA3"
        case .waiting: return "6A9BC3"
        case .quiet: return "A69C90"
        case .adopted: return "9C86C9"
        case .retired: return "D08A5E"
        case .wishesGranted: return "E0B94A"
        }
    }
}

struct Stamp: Identifiable, Hashable {
    let id = UUID()
    var big: String
    var small: String
    var label: String
    var background: String
    var ring: String
    var ink: String
    var tilt: Double
    var isEmpty: Bool = false
}

struct ActivityItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var meta: String
    var symbol: String
    var background: String
    var foreground: String
    var route: Route?
    var isToday: Bool
}

struct ChatMessage: Identifiable, Hashable {
    enum Kind { case herd, traveler, me }
    let id = UUID()
    var who: String
    var text: String
    var kind: Kind
}

enum CheckIn: String, Hashable {
    case appAlert, email, none
}

// Everywhere the app can navigate to.
enum Route: Hashable {
    case companion(String, showHello: Bool)
    case found(String)
    case passOn(String)
    case wish(String)
    case sent(String)
    case broke(String)
    case chat(String)
    case story(String)
    case learn
    case notificationSettings
}

struct NotificationPrefs: Hashable {
    var carriedMoves = true
    var followedMoves = true
    var wishesGranted = true
    var chatReplies = true
    var newStamps = true
    var monthlyReminder = true
    var byEmail = false
    var quietHours = true
}
