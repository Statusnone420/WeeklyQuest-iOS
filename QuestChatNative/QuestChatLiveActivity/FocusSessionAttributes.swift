import ActivityKit
import Foundation

@available(iOS 17.0, *)
struct FocusSessionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startDate: Date
        var endDate: Date
        var isPaused: Bool
        var remainingSeconds: Int
        var title: String
        var initialDurationInSeconds: Int
        var pausedRemainingSeconds: Int
        var hpProgress: Double
        var playerName: String
        var level: Int
        var xpProgress: Double
    }

    var sessionId: UUID
    var totalSeconds: Int
}
