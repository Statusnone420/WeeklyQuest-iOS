import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LevelUpModalView: View {
    let levelUp: PendingLevelUp
    let onDismiss: () -> Void
    let onOpenTalents: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseScale: CGFloat = 0.9
    @State private var pulseOpacity: Double = 0.0
    @State private var flashOpacity: Double = 0.0
    @State private var iconScale: CGFloat = 0.0
    @State private var iconRotation: Double = 0.0
    @State private var showLevelBadge: Bool = false
    
    // Randomized once and persisted for the lifetime of this modal
    @State private var randomHeadline: String
    @State private var randomGradient: LinearGradient
    
    init(levelUp: PendingLevelUp, onDismiss: @escaping () -> Void, onOpenTalents: (() -> Void)? = nil) {
        self.levelUp = levelUp
        self.onDismiss = onDismiss
        self.onOpenTalents = onOpenTalents
        
        // Roll once; persist via @State so it doesn't change during re-renders
        _randomHeadline = State(initialValue: Self.rollHeadline(for: levelUp.tier))
        _randomGradient = State(initialValue: Self.rollGradient())
    }

    var body: some View {
        ZStack {
            // dimmed background
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            // Flash effect for jackpot
            if levelUp.tier == .jackpot {
                Color.white
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
            }

            ZStack {
                // Randomized gradient glow ring
                RadialGradient(
                    gradient: Gradient(colors: [gradientColor.opacity(gradientOpacity), Color.clear]),
                    center: .center,
                    startRadius: 10,
                    endRadius: gradientEndRadius
                )
                .frame(width: gradientSize, height: gradientSize)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
                .blur(radius: gradientBlur)
                .allowsHitTesting(false)
                
                // Secondary randomized gradient for extra flair
                randomGradient
                    .opacity(0.15)
                    .frame(width: gradientSize * 0.8, height: gradientSize * 0.8)
                    .blur(radius: 40)
                    .scaleEffect(pulseScale * 0.9)
                    .opacity(pulseOpacity * 0.7)
                    .allowsHitTesting(false)

                VStack(spacing: tierSpacing) {
                    // Tier-specific icon
                    if let icon = tierIcon {
                        Image(systemName: icon)
                            .font(.system(size: iconSize))
                            .foregroundStyle(iconGradient)
                            .scaleEffect(iconScale)
                            .rotationEffect(.degrees(iconRotation))
                            .shadow(color: iconColor.opacity(0.5), radius: 10)
                    }

                    // Randomized headline
                    Text(randomHeadline)
                        .font(.system(size: titleSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: shadowColor, radius: shadowRadius)

                    // Level badge (separate, polished)
                    levelBadgeView
                        .padding(.top, 2)

                    Text(tierSubtitle)
                        .font(subtitleFont)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Talent / Perk preview
                    if grantsTalentPoint || !levelMeaning.isEmpty {
                        talentPreviewCard
                            .padding(.horizontal, 8)
                    }

                    Button(action: onDismiss) {
                        Text(QuestChatStrings.FocusView.levelUpButtonTitle)
                            .font(.headline)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                    }
                    .background(buttonBackground)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                    .padding(.horizontal, 32)
                    .shadow(color: buttonShadowColor, radius: buttonShadowRadius)
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .background(
                    ZStack {
                        // Subtle gradient behind the card
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(randomGradient.opacity(0.12))
                        
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.black.opacity(0.9))
                    }
                    .shadow(color: cardShadowColor,
                            radius: cardShadowRadius, x: 0, y: 10)
                )
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            triggerHaptic()
            pulse()
            animateIcon()
            if levelUp.tier == .jackpot {
                triggerFlash()
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                showLevelBadge = true
            }
        }
        .animation(.spring(response: 0.5,
                           dampingFraction: 0.8,
                           blendDuration: 0.2),
                   value: levelUp.level)
    }

    // MARK: - Tier-based styling properties
    
    private var gradientSize: CGFloat {
        switch levelUp.tier {
        case .normal: 360
        case .milestone: 450
        case .jackpot: 550
        }
    }
    
    private var gradientEndRadius: CGFloat {
        switch levelUp.tier {
        case .normal: 220
        case .milestone: 280
        case .jackpot: 350
        }
    }
    
    private var gradientBlur: CGFloat {
        switch levelUp.tier {
        case .normal: 20
        case .milestone: 25
        case .jackpot: 35
        }
    }
    
    private var gradientColor: Color {
        switch levelUp.tier {
        case .normal: .accentColor
        case .milestone: .purple
        case .jackpot: .yellow
        }
    }
    
    private var gradientOpacity: Double {
        switch levelUp.tier {
        case .normal: 0.35
        case .milestone: 0.45
        case .jackpot: 0.6
        }
    }
    
    private var titleSize: CGFloat {
        switch levelUp.tier {
        case .normal: 34
        case .milestone: 42
        case .jackpot: 54
        }
    }
    
    private var tierSpacing: CGFloat {
        switch levelUp.tier {
        case .normal: 20
        case .milestone: 24
        case .jackpot: 28
        }
    }
    
    private var tierIcon: String? {
        switch levelUp.tier {
        case .normal: nil
        case .milestone: "star.circle.fill"
        case .jackpot: "crown.fill"
        }
    }
    
    private var iconSize: CGFloat {
        switch levelUp.tier {
        case .normal: 0
        case .milestone: 40
        case .jackpot: 60
        }
    }
    
    private var iconColor: Color {
        switch levelUp.tier {
        case .normal: .clear
        case .milestone: .purple
        case .jackpot: .yellow
        }
    }
    
    private var iconGradient: LinearGradient {
        switch levelUp.tier {
        case .normal:
            LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        case .milestone:
            LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
        case .jackpot:
            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private var tierSubtitle: String {
        switch levelUp.tier {
        case .normal:
            QuestChatStrings.FocusView.levelUpSubtitle
        case .milestone:
            "🎯 Milestone Achievement! Keep grinding!"
        case .jackpot:
            "SPECIAL LEVEL UP ACHIVEMENT SCREEN THINGY! YAY!"
        }
    }
    
    private var subtitleFont: Font {
        switch levelUp.tier {
        case .normal: .subheadline
        case .milestone: .headline.weight(.semibold)
        case .jackpot: .title3.weight(.bold)
        }
    }
    
    private var shadowColor: Color {
        switch levelUp.tier {
        case .normal: .clear
        case .milestone: .purple.opacity(0.5)
        case .jackpot: .yellow.opacity(0.7)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch levelUp.tier {
        case .normal: 0
        case .milestone: 10
        case .jackpot: 20
        }
    }
    
    private var buttonBackground: Color {
        switch levelUp.tier {
        case .normal: .accentColor
        case .milestone: .purple
        case .jackpot: .yellow
        }
    }
    
    private var buttonShadowColor: Color {
        switch levelUp.tier {
        case .normal: .clear
        case .milestone: .purple.opacity(0.5)
        case .jackpot: .yellow.opacity(0.7)
        }
    }
    
    private var buttonShadowRadius: CGFloat {
        switch levelUp.tier {
        case .normal: 0
        case .milestone: 8
        case .jackpot: 15
        }
    }
    
    private var cardShadowColor: Color {
        switch levelUp.tier {
        case .normal: Color.accentColor.opacity(0.35)
        case .milestone: Color.purple.opacity(0.5)
        case .jackpot: Color.yellow.opacity(0.7)
        }
    }
    
    private var cardShadowRadius: CGFloat {
        switch levelUp.tier {
        case .normal: 22
        case .milestone: 30
        case .jackpot: 40
        }
    }
    
    // MARK: - Animation methods

    private func triggerHaptic() {
        #if canImport(UIKit)
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        let intensity: CGFloat
        
        switch levelUp.tier {
        case .normal:
            style = .soft
            intensity = 0.9
        case .milestone:
            style = .medium
            intensity = 1.0
        case .jackpot:
            style = .heavy
            intensity = 1.0
        }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
        
        // Extra haptics for milestone and jackpot
        if levelUp.tier == .milestone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                generator.impactOccurred(intensity: 0.8)
            }
        }
        
        if levelUp.tier == .jackpot {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                generator.impactOccurred(intensity: 0.9)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                generator.impactOccurred(intensity: 0.8)
            }
        }
        #endif
    }

    private func pulse() {
        if reduceMotion { return }

        let pulseCount: Int
        switch levelUp.tier {
        case .normal: pulseCount = 2
        case .milestone: pulseCount = 3
        case .jackpot: pulseCount = 4
        }

        for i in 0..<pulseCount {
            let delay = Double(i) * 0.25
            let intensity = 1.0 - (Double(i) * 0.15)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if self.reduceMotion { return }
                self.pulseOpacity = 0.35 * intensity
                self.pulseScale = 0.9
                withAnimation(.easeOut(duration: 0.8)) {
                    self.pulseOpacity = 0.0
                    self.pulseScale = 1.35
                }
            }
        }
    }
    
    private func animateIcon() {
        guard tierIcon != nil, !reduceMotion else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            iconScale = 1.0
        }
        
        if levelUp.tier == .jackpot {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                iconRotation = 10
            }
        }
    }
    
    private func triggerFlash() {
        guard !reduceMotion else { return }
        
        flashOpacity = 0.3
        withAnimation(.easeOut(duration: 0.15)) {
            flashOpacity = 0.0
        }
        
        // Second flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.flashOpacity = 0.2
            withAnimation(.easeOut(duration: 0.15)) {
                self.flashOpacity = 0.0
            }
        }
    }
    
    // MARK: - Level Badge

    @ViewBuilder
    private var levelBadgeView: some View {
        HStack(spacing: 0) {
            Text("Level \(levelUp.level)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(uiColor: .secondarySystemBackground).opacity(0.22))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            levelUp.tier == .normal
                            ? LinearGradient(colors: [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : iconGradient,
                            lineWidth: 1
                        )
                        .opacity(0.9)
                )
                .shadow(color: shadowColor.opacity(0.35), radius: 6, x: 0, y: 3)
                .scaleEffect(showLevelBadge ? 1 : 0.95)
                .opacity(showLevelBadge ? 1 : 0)
        }
    }
    
    // MARK: - Talent / Perk Preview

    /// Whether this level grants a talent point. Example policy: every 5 levels.
    private var grantsTalentPoint: Bool { true }

    /// Short blurb describing what this level means. Expand as needed.
    private var levelMeaning: String {
        switch levelUp.level {
        case 1: return "Welcome to the grind!"
        case 5: return "Talent tier unlocked — start specializing."
        case 10: return "Big milestone: new cosmetic and bonus XP events."
        case 15: return "Elite challenges appear more often."
        case 20: return "Mastery perks unlocked — pick a path."
        default:
            if levelUp.level % 10 == 0 {
                return "Major milestone — exclusive rewards available."
            } else if levelUp.level % 5 == 0 {
                return "New talent point available."
            } else {
                return "Stats up, rewards improve, keep going!"
            }
        }
    }

    @ViewBuilder
    private var talentPreviewCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "tree.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.mint)
                    .frame(width: 28, height: 28)
                    .background(Color.mint.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(grantsTalentPoint ? "New talent point available" : "Perk update")
                        .font(.subheadline.weight(.semibold))
                    Text(levelMeaning)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            if grantsTalentPoint, onOpenTalents != nil {
                Button(action: { onOpenTalents?() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text("Tap to spend it")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.18))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Randomization (Phase 3)
    
    /// Roll for a random headline based on tier
    private static func rollHeadline(for tier: LevelUpTier) -> String {
        switch tier {
        case .normal:
            let options = [
                "DING!",
                "Level Up!",
                "You Leveled Up!",
                "XP Unlocked!",
                "New Power Unlocked!",
                "Big XP Energy!",
                "You're Unstoppable!",
                "Grind Rewarded!",
                "Quest Progress!"
            ]
            return options.randomElement() ?? "Level Up!"
            
        case .milestone:
            let options = [
                "Milestone Reached! 🎯",
                "Major Level Up!",
                "Halfway Checkpoint!",
                "Your Grind Pays Off!",
                "Power Spike Achieved!",
                "Elite Status Unlocked!",
                "Milestone Crushed! ⭐"
            ]
            return options.randomElement() ?? "Milestone Reached!"
            
        case .jackpot:
            let options = [
                "JACKPOT! 💎",
                "LEGENDARY! 👑",
                "MAX POWER! ⚡",
                "YOU'RE A LEGEND!",
                "EPIC LEVEL UNLOCKED!",
                "CRITICAL HIT! 🔥",
                "UNSTOPPABLE! 💪",
                "OMEGA LEVEL! ✨"
            ]
            return options.randomElement() ?? "JACKPOT!"
        }
    }
    
    /// Roll for a random background gradient
    private static func rollGradient() -> LinearGradient {
        let gradients: [LinearGradient] = [
            // Purple vibes
            .init(
                colors: [.purple, .blue],
                startPoint: .top,
                endPoint: .bottom
            ),
            // Sunset
            .init(
                colors: [.orange, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            // Cool mint
            .init(
                colors: [.mint, .blue],
                startPoint: .leading,
                endPoint: .trailing
            ),
            // Warm gold
            .init(
                colors: [.yellow, .orange],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            ),
            // Cyber pink
            .init(
                colors: [.pink, .purple],
                startPoint: .bottom,
                endPoint: .top
            ),
            // Forest green
            .init(
                colors: [.green, .mint],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ),
            // Fire
            .init(
                colors: [.red, .orange],
                startPoint: .leading,
                endPoint: .trailing
            ),
            // Ocean
            .init(
                colors: [.cyan, .blue],
                startPoint: .top,
                endPoint: .bottom
            )
        ]
        
        return gradients.randomElement() ?? gradients[0]
    }
}

