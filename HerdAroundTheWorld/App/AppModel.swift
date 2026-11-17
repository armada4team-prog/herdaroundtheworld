import SwiftUI
import Observation
import CoreLocation

// Everything the app knows. For testing it starts with the sample data from the designs and keeps
// changes in memory. Swap the sample data for The Herd's database when it's ready (see README).
@Observable
final class AppModel {
    var companions: [Companion] = SampleData.companions
    var following: Set<String> = ["07", "2"]
    var nickname: String = ""
    var email: String? = nil
    var language: String = "en"
    var notificationPrefs = NotificationPrefs()
    var chats: [String: [ChatMessage]] = [:]
    var holding: Set<String> = []          // Companions you've logged as found and not passed on yet

    var stamps: [Stamp] = [
        Stamp(big: "#07", small: "Santa Fe", label: "Carried #07 · Oct", background: "DDF0E8", ring: "5B7869", ink: "2F4A3D", tilt: -6),
        Stamp(big: "#3", small: "Tokyo", label: "Carried #3 · Aug", background: "FBE4E2", ring: "D98C86", ink: "6B3F3A", tilt: 5),
        Stamp(big: "Wish", small: "Granted", label: "Helped #2 see the ocean", background: "F9EBB5", ring: "E0B94A", ink: "5A4C1E", tilt: -3),
        Stamp(big: "1st", small: "Hand-off", label: "Handed one to a stranger", background: "E7ECE5", ring: "6E8B7D", ink: "3F5A4C", tilt: 4)
    ]

    var activity: [ActivityItem] = [
        ActivityItem(title: "#07 just arrived in Santa Fe, NM!", meta: "Left by [TRAVELER] · 2 hours ago", symbol: "mappin.and.ellipse",
                     background: "DDF0E8", foreground: "2F4A3D", route: .companion("07", showHello: false), isToday: true),
        ActivityItem(title: "[TRAVELER 2] replied in #07’s traveler chat", meta: "“Somewhere with mountains, please!” · 4 hours ago", symbol: "bubble.left",
                     background: "F6EFE7", foreground: "3F5A4C", route: .chat("07"), isToday: true),
        ActivityItem(title: "Two new stamps: Passed on #3 and Wish granted", meta: "Added to your Passport after a quick look", symbol: "star",
                     background: "FBE4E2", foreground: "6B3F3A", route: nil, isToday: true),
        ActivityItem(title: "#2’s wish came true: they saw the ocean!", meta: "Lisbon, Portugal · 5 days ago", symbol: "star",
                     background: "F9EBB5", foreground: "5A4C1E", route: .companion("2", showHello: false), isToday: false),
        ActivityItem(title: "#07 passed 1,000 miles", meta: "A new milestone for the herd · 6 days ago", symbol: "flag",
                     background: "E7ECE5", foreground: "3F5A4C", route: .companion("07", showHello: false), isToday: false)
    ]

    // Shown at the top of Activity: the one gentle reminder from a Companion you're holding.
    var reminderFrom: String? = "07"

    init() {
        chats["07"] = [
            ChatMessage(who: "The Herd · made them in Aurora, CO", text: "Welcome to #07’s chat! Everyone who carries them can talk here. Say hi to the travelers before you.", kind: .herd),
            ChatMessage(who: "[TRAVELER 2] · Traveler 4 · Boise, ID", text: "I miss this little one already! Where are they headed next?", kind: .traveler),
            ChatMessage(who: "Sam R. · Traveler 5 · Moab, UT", text: "They loved the arches. Somewhere with mountains, please!", kind: .traveler)
        ]
    }

    // MARK: Lookups

    func companion(_ number: String) -> Companion? {
        let clean = AppModel.cleanNumber(number)
        return companions.first { AppModel.cleanNumber($0.number) == clean }
    }

    var originals: [Companion] { companions.filter(\.isOriginal).sorted { (Int($0.number) ?? 0) < (Int($1.number) ?? 0) } }
    var followed: [Companion] { companions.filter { following.contains($0.number) } }

    // The 10 Companions with the most stops, most recently moved first when tied.
    var mostActive: [Companion] {
        Array(companions.sorted {
            if $0.stopCount != $1.stopCount { return $0.stopCount > $1.stopCount }
            return AppModel.daysAgo($0.lastMoved) < AppModel.daysAgo($1.lastMoved)
        }.prefix(10))
    }

    var companionsCarried: Int { stamps.filter { $0.big.hasPrefix("#") }.count }
    var wishesGranted: Int { stamps.filter { $0.big == "Wish" }.count }
    var milesCarried: Int { 640 }
    var herdSize: Int { 14 }

    func matches(_ companion: Companion, filter: MapFilter) -> Bool {
        switch filter {
        case .all, .nearMe: return true
        case .following: return following.contains(companion.number)
        case .originals: return companion.isOriginal
        case .movedThisWeek: return companion.movedThisWeek
        case .waiting: return companion.status == .waiting
        case .quiet: return companion.status == .quiet
        case .adopted: return companion.status == .adopted
        case .retired: return companion.status == .retired
        case .wishesGranted: return companion.wishGranted
        }
    }

    // MARK: Actions

    func toggleFollow(_ number: String) {
        if following.contains(number) { following.remove(number) } else { following.insert(number) }
    }

    func logFind(_ number: String, city: String, nickname: String, checkIn: CheckIn, email: String?, coordinate: CLLocationCoordinate2D? = nil) {
        self.nickname = nickname
        if let email, !email.isEmpty { self.email = email }
        holding.insert(number)
        following.insert(number)
        guard let index = companions.firstIndex(where: { $0.number == number }) else { return }
        companions[index].status = .moving
        let place = companions[index].current
        companions[index].stops.append(Stop(city: city.isEmpty ? (place?.city ?? "") : city,
                                            latitude: coordinate?.latitude ?? place?.latitude ?? 0,
                                            longitude: coordinate?.longitude ?? place?.longitude ?? 0,
                                            leftBy: nickname, when: "Just now", note: "Found by \(nickname)."))
        companions[index].lastMoved = "Just now"
        companions[index].movedThisWeek = true
        activity.insert(ActivityItem(title: "You found #\(number)!", meta: "\(city) · just now", symbol: "mappin.and.ellipse",
                                     background: "DDF0E8", foreground: "2F4A3D", route: .companion(number, showHello: false), isToday: true), at: 0)
    }

    func passOn(_ number: String, city: String, place: String?, handedToSomeone: Bool, chapter: String, nickname: String, grantedWish: Bool, coordinate: CLLocationCoordinate2D? = nil) {
        if !nickname.isEmpty { self.nickname = nickname }
        holding.remove(number)
        guard let index = companions.firstIndex(where: { $0.number == number }) else { return }
        let last = companions[index].current
        companions[index].stops.append(Stop(city: city, place: handedToSomeone ? nil : place,
                                            latitude: coordinate?.latitude ?? last?.latitude ?? 0,
                                            longitude: coordinate?.longitude ?? last?.longitude ?? 0,
                                            leftBy: nickname, when: "Just now", note: chapter.isEmpty ? nil : chapter))
        companions[index].status = handedToSomeone ? .moving : .waiting
        companions[index].lastMoved = "Just now"
        companions[index].movedThisWeek = true
        companions[index].travelers += 1
        stamps.insert(Stamp(big: "#\(number)", small: city, label: "Passed on #\(number)", background: "DDF0E8", ring: "5B7869", ink: "2F4A3D", tilt: -4), at: 0)
        if grantedWish {
            companions[index].wishGranted = true
            stamps.insert(Stamp(big: "Wish", small: "Granted", label: "Helped #\(number) \(companions[index].wish)", background: "F9EBB5", ring: "E0B94A", ink: "5A4C1E", tilt: 3), at: 0)
        }
        if reminderFrom == number { reminderFrom = nil }
    }

    func setNextWish(_ number: String, wish: String) {
        guard let index = companions.firstIndex(where: { $0.number == number }) else { return }
        var text = wish.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.lowercased().hasPrefix("i want to ") { text = String(text.dropFirst(10)) }
        if text.hasSuffix(".") { text.removeLast() }
        companions[index].wish = text
        companions[index].wishGranted = false
    }

    func reportBroken(_ number: String, lost: Bool, chipped: Bool) {
        guard let index = companions.firstIndex(where: { $0.number == number }) else { return }
        if !chipped { companions[index].status = .retired }
        holding.remove(number)
    }

    func sendChat(_ number: String, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let who = nickname.isEmpty ? "You" : nickname
        chats[number, default: []].append(ChatMessage(who: who, text: AppModel.hideContactDetails(trimmed), kind: .me))
    }

    // MARK: Helpers

    static func cleanNumber(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        let trimmed = digits.drop { $0 == "0" }
        return trimmed.isEmpty ? (digits.isEmpty ? "" : "0") : String(trimmed)
    }

    // Reads a scanned QR code ("https://theherdstudio.com/c/07") or a typed number ("07").
    static func number(fromScan payload: String) -> String? {
        if let range = payload.range(of: "/c/") {
            let rest = payload[range.upperBound...].prefix { $0.isNumber }
            return rest.isEmpty ? nil : String(rest)
        }
        let digits = payload.filter(\.isNumber)
        return digits.isEmpty || digits.count > 4 ? nil : digits
    }

    static func daysAgo(_ text: String) -> Int {
        let parts = text.split(separator: " ")
        guard let n = parts.first.flatMap({ Int($0) }) else { return text == "Just now" ? 0 : 999 }
        if text.contains("week") { return n * 7 }
        if text.contains("month") { return n * 30 }
        return n
    }

    // Phone numbers and email addresses typed into chat are hidden, as promised in the designs.
    static func hideContactDetails(_ text: String) -> String {
        var result = text
        let patterns = [
            "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}",
            "\\+?\\d[\\d\\s().-]{7,}\\d"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "[hidden]")
            }
        }
        return result
    }
}

// Which tab is showing, and the screen stack inside each tab.
@Observable
final class Router {
    enum Tab: Hashable { case home, map, scan, passport, activity }

    var tab: Tab = .home
    var paths: [Tab: [Route]] = [.home: [], .map: [], .scan: [], .passport: [], .activity: []]
    var showSignIn = false
    var showLanguage = false

    func path(for tab: Tab) -> Binding<[Route]> {
        Binding(get: { self.paths[tab] ?? [] }, set: { self.paths[tab] = $0 })
    }

    func push(_ route: Route) {
        paths[tab, default: []].append(route)
    }

    // Replace the top screen (used when a form finishes and moves to its thank-you screen).
    func replaceTop(with route: Route) {
        var stack = paths[tab] ?? []
        if !stack.isEmpty { stack.removeLast() }
        stack.append(route)
        paths[tab] = stack
    }

    func open(_ route: Route, in tab: Tab) {
        self.tab = tab
        paths[tab] = [route]
    }
}
