import ActivityKit
import Foundation

@available(iOS 17.0, *)
enum FocusLiveActivityManager {
    private static var activity: Activity<FocusSessionAttributes>?

    static func start(title: String, totalSeconds: Int) async -> Activity<FocusSessionAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }

        await endAllActivities()

        let attributes = FocusSessionAttributes(sessionId: UUID())
        let now = Date()
        let endDate = now.addingTimeInterval(TimeInterval(totalSeconds))
        let contentState = FocusSessionAttributes.ContentState(
            startDate: now,
            endDate: endDate,
            isPaused: false,
            remainingSeconds: totalSeconds,
            totalSeconds: totalSeconds,
            title: title
        )
        let content = ActivityContent(state: contentState, staleDate: endDate)

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content
            )
            return activity
        } catch {
            print("Failed to start Focus Live Activity: \(error.localizedDescription)")
            return nil
        }
    }

    static func end(finalState: FocusSessionAttributes.ContentState? = nil) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let endingContent: ActivityContent<FocusSessionAttributes.ContentState>?
        if let finalState {
            endingContent = ActivityContent(state: finalState, staleDate: nil)
        } else {
            endingContent = nil
        }

        if let endingContent {
            await activity?.end(endingContent, dismissalPolicy: .immediate)
        } else {
            await activity?.end(dismissalPolicy: .immediate)
        }
        activity = nil
    }

    static func clearReference(for activity: Activity<FocusSessionAttributes>) {
        if self.activity?.id == activity.id {
            self.activity = nil
        }
    }

    private static func endAllActivities() async {
        for activity in Activity<FocusSessionAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        await MainActor.run {
            activity = nil
        }
    }
}
