import Foundation

enum GutStatus: String, Codable, CaseIterable {
    case none
    case great
    case meh
    case rough
}

enum MoodStatus: String, Codable, CaseIterable {
    case none
    case good
    case neutral
    case bad
}

struct DailyHealthInputs: Codable {
    var hydrationCount: Int
    var selfCareSessions: Int
    var focusSprints: Int
    var gutStatus: GutStatus
    var moodStatus: MoodStatus
}
