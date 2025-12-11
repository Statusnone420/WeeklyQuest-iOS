import SwiftUI
import UIKit

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    @ObservedObject private var dailyRatingsStore: DailyHealthRatingsStore
    private let healthBarViewModel: HealthBarViewModel
    private let focusViewModel: FocusViewModel
    @State private var cardScale: CGFloat = 0.95
    @State private var cardOpacity: Double = 0

    private let hydrationPresets = [4, 6, 8, 10, 12]
    
    private func playStartHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        // bup
        generator.impactOccurred(intensity: 0.4)

        // bup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            generator.impactOccurred(intensity: 0.7)
        }

        // BUMP (finish)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            generator.impactOccurred(intensity: 1.0)
        }
    }

    init(viewModel: OnboardingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _dailyRatingsStore = ObservedObject(initialValue: viewModel.dailyRatingsStore)
        self.healthBarViewModel = viewModel.healthBarViewModel
        self.focusViewModel = viewModel.focusViewModel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color.black,
                        Color(red: 0.1, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    onboardingCard {
                        switch viewModel.currentStep {
                        case .welcome:
                            welcomeStep
                        case .name:
                            nameStep
                        case .hydration:
                            hydrationStep
                        case .dailyVitals:
                            modernDailyVitalsStep
                        case .howItWorks:
                            howItWorksStep
                        }
                    }
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 500)

                    Spacer()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }
        .onChange(of: viewModel.currentStep) { oldValue, newValue in
            // Subtle scale animation on step change
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cardScale = 0.98
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                cardScale = 1.0
            }
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // App icon or hero element
            HStack {
                Spacer()
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .cyan.opacity(0.4), radius: 15)
                
                Spacer()
            }

            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome to")
                    .font(.title3.weight(.medium))
                    .foregroundColor(Color.white.opacity(0.7))
                
                Text("WeeklyQuest")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Turn your week into clear quests with XP, levels, and an HP bar that updates you.")
                    .font(.body)
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureBullet(icon: "timer", color: .mint, text: "Start focus sessions for work, gaming, chores, and self-care.")
                featureBullet(icon: "heart.fill", color: .red, text: "Your HP updates automatically based off changes you make.")
                featureBullet(icon: "trophy.fill", color: .yellow, text: "Complete daily (resets at midnight automatically) to earn XP and level up. Weekly quests too!")
            }
            .padding(.vertical, 8)

            VStack(spacing: 12) {
                primaryButton(title: "Get started", icon: "arrow.right") {
                    playStartHaptic()              // 🔔 bump-bump-BUMP
                    viewModel.currentStep = .name  // existing behavior
                }

                Button("Skip for now") {
                    viewModel.skip()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.white.opacity(0.6))
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Step indicator
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(index == 1 ? Color.mint : Color.white.opacity(0.2))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Pick your game name")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("You can change this in the Player Card on the Player tab.")
                    .font(.body)
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineSpacing(3)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("THINK OF SOME BADASS CHARACTER NAME")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.white.opacity(0.5))
                    
                    TextField("Player Juan", text: $viewModel.playerName)
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .textInputAutocapitalization(.words)
                        .foregroundColor(.white)
                        .tint(.mint)
                }

                primaryButton(
                    title: "Next", 
                    icon: "arrow.right",
                    isDisabled: viewModel.playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    viewModel.goToNextStep()
                }
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hydrationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Step indicator
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(index == 2 ? Color.mint : Color.white.opacity(0.2))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "drop.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                        )
                    Text("Daily water goal")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("Pick a goal and hit it to complete quests and keep your HP up!")
                    .font(.body)
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineSpacing(3)
            }

            VStack(spacing: 16) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(hydrationPresets, id: \.self) { cups in
                        Button {
                            viewModel.selectedHydrationGoalCups = cups
                        } label: {
                            VStack(spacing: 8) {
                                Text("\(cups)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                Text("glasses")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(viewModel.selectedHydrationGoalCups == cups 
                                        ? LinearGradient(colors: [.mint, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        viewModel.selectedHydrationGoalCups == cups ? Color.mint : Color.white.opacity(0.2), 
                                        lineWidth: viewModel.selectedHydrationGoalCups == cups ? 2 : 1
                                    )
                            )
                            .foregroundColor(viewModel.selectedHydrationGoalCups == cups ? .black : .white)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.mint)
                        Text("\(viewModel.selectedHydrationGoalCups) glasses (8oz each) per day")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding(.top, 4)

                    primaryButton(title: "Next", icon: "arrow.right") {
                        viewModel.goToNextStep()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var howItWorksStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Step indicator
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(index == 4 ? Color.mint : Color.white.opacity(0.2))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(colors: [.mint, .green], startPoint: .top, endPoint: .bottom)
                        )
                    Text("You're all set!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("Here's a quick refresher on how WeeklyQuest works:")
                    .font(.body)
                    .foregroundColor(Color.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 16) {
                featureBullet(icon: "list.bullet.rectangle.fill", color: .mint, text: "Complete daily and weekly quests automatically based on your progress.")
                featureBullet(icon: "timer", color: .cyan, text: "Start timers for work, chores, and self-care to stay focused.")
                featureBullet(icon: "heart.fill", color: .red, text: "Keep your HP honest by tracking sleep, mood, and gut each day.")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("YOUR SETUP")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                
                VStack(spacing: 0) {
                    summaryRow(title: "Name", value: viewModel.playerName.isEmpty ? QuestChatStrings.PlayerCard.defaultName : viewModel.playerName, isFirst: true)
                    Divider().background(Color.white.opacity(0.1))
                    summaryRow(title: "Water goal", value: "\(viewModel.selectedHydrationGoalCups) glasses/day")
                    Divider().background(Color.white.opacity(0.1))
                    summaryRow(title: "Mood", value: ratingLabel(for: currentRatings.mood))
                    Divider().background(Color.white.opacity(0.1))
                    summaryRow(title: "Gut", value: ratingLabel(for: currentRatings.gut))
                    Divider().background(Color.white.opacity(0.1))
                    summaryRow(title: "Sleep", value: ratingLabel(for: currentRatings.sleep))
                    Divider().background(Color.white.opacity(0.1))
                    summaryRow(title: "Activity", value: activityLabel(for: currentRatings.activity), isLast: true)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
            }
            .padding(.top, 8)

            primaryButton(title: "Enter WeeklyQuest", icon: "arrow.right") {
                viewModel.completeOnboarding()
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentRatings: DailyHealthRatings { dailyRatingsStore.ratings() }
    
    /// Modern inline vitals step - custom UI to match onboarding aesthetic
    private var modernDailyVitalsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Step indicator
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(index == 3 ? Color.mint : Color.white.opacity(0.2))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(colors: [.red, .pink], startPoint: .top, endPoint: .bottom)
                        )
                    Text("Daily Setup")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text("Update these in the Player Card on the daily and your HP will be updated automatically.")
                    .font(.body)
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineSpacing(3)
            }

            // Modern vitals sliders container
            VStack(spacing: 16) {
                Text("EVERYTHING IS KEPT LOCALLY ON YOUR DEVICE")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Use the embedded component with better styling
                DailyVitalsSlidersView(
                    dailyRatingsStore: dailyRatingsStore,
                    healthBarViewModel: healthBarViewModel,
                    focusViewModel: focusViewModel
                )
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                        
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
            }

            primaryButton(title: "Continue", icon: "arrow.right") {
                viewModel.completeDailyVitalsStep()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { viewModel.seedDailyVitalsIfNeeded() }
    }

    private func ratingLabel(for rating: Int?) -> String {
        guard let rating else { return "Not set" }
        return HealthRatingMapper.label(for: rating)
    }

    private func activityLabel(for rating: Int?) -> String {
        guard let rating else { return "Not set" }
        return HealthRatingMapper.activityLabel(for: rating)
    }

    private func summaryRow(title: String, value: String, isFirst: Bool = false, isLast: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func featureBullet(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.85))
                .lineSpacing(2)
        }
    }

    private func bulletRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.mint)
                .frame(width: 10, height: 10)
                .padding(.top, 4)
            Text(text)
                .font(.body)
                .foregroundColor(Color.white.opacity(0.85))
        }
        .padding(.vertical, 2)
    }

    private func primaryButton(title: String, icon: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.headline.bold())
                
                if let icon {
                    Image(systemName: icon)
                        .font(.headline.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: isDisabled 
                        ? [Color.mint.opacity(0.3)] 
                        : [Color.mint, Color.cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(isDisabled ? Color.white.opacity(0.5) : .black)
            .cornerRadius(16)
            .shadow(color: isDisabled ? .clear : Color.mint.opacity(0.3), radius: 12, y: 4)
        }
        .disabled(isDisabled)
    }

    private func onboardingCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    content()
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(radius: 20)
    }

    private var cardBackground: some View {
        ZStack {
            // Base glass effect
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
            
            // Gradient overlay for depth
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Border
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
    }
}

#Preview {
    let container = DependencyContainer.shared
    OnboardingView(viewModel: container.makeOnboardingViewModel())
        .preferredColorScheme(.dark)
}

// Modern onboarding with gradient background, step indicators, icon accents, and glass-effect cards.
// XP is batched and awarded after onboarding completes to ensure proper quest checks and level-up modals.
