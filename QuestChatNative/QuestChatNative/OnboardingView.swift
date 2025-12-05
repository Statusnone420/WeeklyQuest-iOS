import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel

    private let hydrationPresets = [4, 6, 8, 10, 12]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    switch viewModel.currentStep {
                    case .welcome:
                        welcomeStep
                    case .name:
                        nameStep
                    case .hydration:
                        hydrationStep
                    case .moodGutSleep:
                        moodGutSleepStep
                    case .howItWorks:
                        howItWorksStep
                    }
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to QuestChat")
                .font(.largeTitle.bold())

            Text("Turn your real life into quests and level up your self-care, one small win at a time.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                bulletRow(text: "Start focus sessions for work, chores, and self-care")
                bulletRow(text: "Track sleep, mood, hydration, and gut health")
                bulletRow(text: "Earn XP, unlock badges, and fill your Health Bar IRL")
            }

            VStack(spacing: 12) {
                primaryButton(title: "Get started") {
                    viewModel.currentStep = .name
                }

                Button("Skip for now") {
                    viewModel.skip()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(20)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What should we call you?")
                .font(.title.bold())

            Text("This name will show on your Player Card.")
                .font(.body)
                .foregroundStyle(.secondary)

            TextField("Player name", text: $viewModel.playerName)
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .textInputAutocapitalization(.words)
                .foregroundColor(.white)

            primaryButton(title: "Next", isDisabled: viewModel.playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                viewModel.goToNextStep()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(20)
    }

    private var hydrationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set your daily water goal")
                .font(.title.bold())

            Text("Pick a goal that feels realistic. You can always change this later.")
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(hydrationPresets, id: \.self) { cups in
                    Button {
                        viewModel.selectedHydrationGoalCups = cups
                    } label: {
                        Text("\(cups)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedHydrationGoalCups == cups ? Color.blue.opacity(0.3) : Color.white.opacity(0.06))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .foregroundColor(.white)
                }
            }

            Text("Goal: \(viewModel.selectedHydrationGoalCups) cups per day")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            primaryButton(title: "Next") {
                viewModel.goToNextStep()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(20)
    }

    private var moodGutSleepStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How are you feeling today?")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 14) {
                Text("Mood")
                    .font(.headline)
                moodGutRow(selection: $viewModel.selectedMoodState)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Gut")
                    .font(.headline)
                moodGutRow(selection: $viewModel.selectedGutState)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Last night's sleep")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.selectedSleepValue.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Slider(value: Binding<Double>(
                    get: { Double(viewModel.selectedSleepValue.rawValue) },
                    set: { newValue in
                        if let quality = SleepQuality(rawValue: Int(newValue)) {
                            viewModel.selectedSleepValue = quality
                        }
                    }
                ), in: 0...Double(SleepQuality.allCases.count - 1), step: 1)
            }

            primaryButton(title: "Next", isDisabled: viewModel.selectedMoodState == .none || viewModel.selectedGutState == .none) {
                viewModel.goToNextStep()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(20)
    }

    private var howItWorksStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("You're ready to start")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 10) {
                bulletRow(text: "Quests: complete small quests to earn XP and badges.")
                bulletRow(text: "Focus: start timers for work, chores, and self-care.")
                bulletRow(text: "Health Bar IRL: keep your HP honest by updating sleep, mood, and gut each day.")
            }

            VStack(alignment: .leading, spacing: 6) {
                summaryRow(title: "Name", value: viewModel.playerName.isEmpty ? QuestChatStrings.PlayerCard.defaultName : viewModel.playerName)
                summaryRow(title: "Water goal", value: "\(viewModel.selectedHydrationGoalCups) cups")
                summaryRow(title: "Mood", value: label(for: viewModel.selectedMoodState))
                summaryRow(title: "Gut", value: label(for: viewModel.selectedGutState))
                summaryRow(title: "Sleep", value: viewModel.selectedSleepValue.label)
            }
            .padding()
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)

            primaryButton(title: "Enter QuestChat") {
                viewModel.completeOnboarding()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(20)
    }

    private func moodGutRow(selection: Binding<MoodStatus>) -> some View {
        HStack(spacing: 10) {
            moodOption(title: "Rough", emoji: "😫", status: .bad, selection: selection)
            moodOption(title: "Okay", emoji: "😐", status: .neutral, selection: selection)
            moodOption(title: "Good", emoji: "🙂", status: .good, selection: selection)
        }
    }

    private func moodGutRow(selection: Binding<GutStatus>) -> some View {
        HStack(spacing: 10) {
            gutOption(title: "Rough", emoji: "😫", status: .rough, selection: selection)
            gutOption(title: "Okay", emoji: "😐", status: .meh, selection: selection)
            gutOption(title: "Great", emoji: "🙂", status: .great, selection: selection)
        }
    }

    private func moodOption(title: String, emoji: String, status: MoodStatus, selection: Binding<MoodStatus>) -> some View {
        selectablePill(isSelected: selection.wrappedValue == status, title: title, emoji: emoji) {
            selection.wrappedValue = status
        }
    }

    private func gutOption(title: String, emoji: String, status: GutStatus, selection: Binding<GutStatus>) -> some View {
        selectablePill(isSelected: selection.wrappedValue == status, title: title, emoji: emoji) {
            selection.wrappedValue = status
        }
    }

    private func selectablePill(isSelected: Bool, title: String, emoji: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(emoji)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? Color.green.opacity(0.3) : Color.white.opacity(0.06))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .foregroundColor(.white)
    }

    private func label(for status: MoodStatus) -> String {
        switch status {
        case .good: return "Good"
        case .neutral: return "Okay"
        case .bad: return "Rough"
        case .none: return "Not set"
        }
    }

    private func label(for status: GutStatus) -> String {
        switch status {
        case .great: return "Great"
        case .meh: return "Okay"
        case .rough: return "Rough"
        case .none: return "Not set"
        }
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }

    private func bulletRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.mint)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(.body)
        }
    }

    private func primaryButton(title: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(isDisabled ? Color.white.opacity(0.12) : Color.mint)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .disabled(isDisabled)
    }

    private var cardBackground: some View {
        Color(uiColor: .secondarySystemBackground).opacity(0.24)
    }
}

#Preview {
    let container = DependencyContainer.shared
    OnboardingView(viewModel: container.makeOnboardingViewModel())
        .preferredColorScheme(.dark)
}
