import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Helpers

@available(iOS 17.0, *)
private func formattedTime(_ seconds: Int) -> String {
    let s = max(seconds, 0)
    let hours = s / 3600
    let minutes = (s % 3600) / 60
    let secs = s % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%d:%02d", minutes, secs)
    }
}

@available(iOS 17.0, *)
private func timeAbbrev(_ seconds: Int) -> String {
    let s = max(seconds, 0)
    if s >= 3600 { return "\(s / 3600)h" }
    if s >= 60 { return "\(s / 60)m" }
    return "\(s)s"
}

@available(iOS 17.0, *)
private func hpGradientColor(forProgress progress: Double) -> Color {
    let clamped = min(max(progress, 0), 1)
    if clamped <= 0.5 { return .green }
    if clamped <= 0.75 { return .yellow }
    return .red
}

@available(iOS 17.0, *)
private struct TimerVisualMetrics {
    let total: TimeInterval
    let remaining: TimeInterval
    let remainingSeconds: Int
    let progress: Double
    let timerColor: Color
    let hpProgress: Double

    init(context: ActivityViewContext<FocusSessionAttributes>, now: Date) {
        let state = context.state
        total = Double(state.initialDurationInSeconds)

        let pausedRemaining = Double(state.pausedRemainingSeconds)
        remaining = state.isPaused
            ? max(pausedRemaining, 0)
            : max(state.endDate.timeIntervalSince(now), 0)

        remainingSeconds = Int(ceil(remaining))
        progress = total > 0 ? min(max(1 - (remaining / total), 0), 1) : 1
        timerColor = hpGradientColor(forProgress: progress)
        hpProgress = min(max(state.hpProgress, 0), 1)
    }
}

@available(iOS 17.0, *)
private func symbolName(forTitle title: String) -> String {
    let t = title.lowercased()
    if t.contains("deep") || t.contains("focus") { return "brain.head.profile" }
    if t.contains("work") || t.contains("sprint") { return "bolt.circle" }
    if t.contains("chore") { return "house.fill" }
    if t.contains("self") || t.contains("care") { return "figure.mind.and.body" }
    if t.contains("game") { return "gamecontroller" }
    if t.contains("break") || t.contains("quick") { return "cup.and.saucer.fill" }
    return "timer"
}

@available(iOS 17.0, *)
private struct CompactHPBarView: View {
    let hpProgress: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(hpGradientColor(forProgress: hpProgress))
            .frame(width: 26, height: 5)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
            )
    }
}

@available(iOS 17.0, *)
private struct PlayerStatusSummaryView: View {
    let playerName: String
    let level: Int
    let xpProgress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(playerName)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 8) {
                Text("Lv \(level)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                ProgressView(value: min(max(xpProgress, 0), 1))
                    .progressViewStyle(.linear)
                    .tint(.cyan)
                    .frame(width: 64)
            }
        }
    }
}

// MARK: - Lock Screen / Expanded View

@available(iOS 17.0, *)
struct FocusSessionLiveActivityView: View {
    let context: ActivityViewContext<FocusSessionAttributes>

    var body: some View {
        TimelineView(.animation(minimumInterval: 1)) { timeline in
            Group {
                let visuals = TimerVisualMetrics(context: context, now: timeline.date)

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedTime(visuals.remainingSeconds))
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .allowsTightening(true)
                        Text("\(timeAbbrev(visuals.remainingSeconds)) left")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.title)
                            .font(.body)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ProgressView(value: visuals.progress)
                            .progressViewStyle(.linear)
                            .tint(visuals.timerColor)
                            .animation(.linear(duration: 0.2), value: visuals.progress)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Ends")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(context.state.endDate, style: .time)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .allowsTightening(true)
                            .frame(maxWidth: 80, alignment: .trailing)
                            .foregroundColor(.primary)
                    }
                    .frame(minWidth: 72, alignment: .trailing)
                }
                .padding()
            }
        }
    }
}

// MARK: - Widget / Dynamic Island

@available(iOS 17.0, *)
struct FocusSessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionAttributes.self) { context in
            FocusSessionLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TimelineView(.animation(minimumInterval: 1)) { timeline in
                        let visuals = TimerVisualMetrics(context: context, now: timeline.date)
                        let symbol = symbolName(forTitle: context.state.title)

                        HStack(spacing: 8) {
                            Image(systemName: symbol)
                                .symbolRenderingMode(.hierarchical)
                                .imageScale(.medium)
                                .font(.subheadline)
                                .foregroundStyle(visuals.timerColor)

                            PlayerStatusSummaryView(
                                playerName: context.state.playerName,
                                level: context.state.level,
                                xpProgress: context.state.xpProgress
                            )
                        }
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.bottom) {
                    TimelineView(.animation(minimumInterval: 1)) { timeline in
                        let visuals = TimerVisualMetrics(context: context, now: timeline.date)

                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: visuals.progress)
                                .progressViewStyle(.linear)
                                .tint(visuals.timerColor)
                                .frame(height: 4)
                                .animation(.linear(duration: 0.2), value: visuals.progress)

                            Text(formattedTime(visuals.remainingSeconds))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }
            } compactLeading: {
                TimelineView(.animation(minimumInterval: 1)) { timeline in
                    let visuals = TimerVisualMetrics(context: context, now: timeline.date)

                    Text(formattedTime(visuals.remainingSeconds))
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .fixedSize(horizontal: true, vertical: false)
                }
            } compactTrailing: {
                CompactHPBarView(hpProgress: context.state.hpProgress)
            } minimal: {
                TimelineView(.animation(minimumInterval: 1)) { timeline in
                    let visuals = TimerVisualMetrics(context: context, now: timeline.date)
                    let symbol = symbolName(forTitle: context.state.title)

                    Image(systemName: symbol)
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.medium)
                        .foregroundStyle(visuals.timerColor)
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Focus Session", as: .content, using: FocusSessionAttributes(sessionId: UUID(), totalSeconds: 1800)) {
    FocusSessionLiveActivityWidget()
} contentStates: {
    FocusSessionAttributes.ContentState(
        startDate: Date(),
        endDate: Date().addingTimeInterval(1500),
        isPaused: false,
        remainingSeconds: 1500,
        title: "Deep Work",
        initialDurationInSeconds: 1800,
        pausedRemainingSeconds: 1500,
        hpProgress: 0.75,
        playerName: "Player One",
        level: 5,
        xpProgress: 0.4
    )
}
#endif


