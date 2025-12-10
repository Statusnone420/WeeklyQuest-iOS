import SwiftUI
import UIKit
import Lottie

struct MiniFocusTimerFAB: View {
    @ObservedObject var viewModel: FocusViewModel
    @Binding var selectedTab: MainTab
    @Binding var dragOffset: CGSize

    // Transient drag during gesture; accumulated position stored in dragOffset
    @State private var tempDrag: CGSize = .zero
    @State private var focusRingsTrigger = UUID()
    @State private var isPressed: Bool = false

    private let diameter: CGFloat = 68.0 // Sized to sit comfortably above the tab bar
    private let ringLineWidth: CGFloat = 5 // Proportionally increased

    private var clampedProgress: CGFloat { CGFloat(min(max(viewModel.progress, 0), 1)) }
    
    // Warning animation (same as main timer)
    private var warningFraction: Double {
        guard viewModel.remainingSeconds <= 10 else { return 0 }
        let fraction = 1 - (Double(viewModel.remainingSeconds) / 10)
        return min(max(fraction, 0), 1)
    }
    
    // Dynamic ring colors (same as main timer)
    private var ringColors: [Color] {
        let base = [Color.mint, Color.cyan, Color.mint]
        let warning = [Color.orange, Color.red, Color.orange]
        return zip(base, warning).map { baseColor, warningColor in
            baseColor.blended(withFraction: warningFraction, of: warningColor)
        }
    }
    
    private var fabContent: some View {
        ZStack {
            // Cyan glow halo behind the button
            Circle()
                .fill(Color.clear)
                .shadow(color: Color.cyan.opacity(0.35), radius: 16, x: 0, y: 0)
                .shadow(color: Color.cyan.opacity(0.18), radius: 30, x: 0, y: 0)
                .allowsHitTesting(false)

            // Coin base with vertical gradient and subtle rim
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.22, blue: 0.25), // slightly lighter top
                            Color(red: 0.08, green: 0.09, blue: 0.11)  // darker bottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.black.opacity(0.40)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.55), radius: 14, x: 0, y: 10)
                .allowsHitTesting(false)

            // Inner gradient plate with top highlight to fake depth
            Circle()
                .inset(by: 5)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.18),
                            Color.black.opacity(0.85)
                        ]),
                        center: .center,
                        startRadius: 2,
                        endRadius: diameter
                    )
                )
                .overlay(
                    // Top highlight ring
                    Circle()
                        .inset(by: 7)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
                .allowsHitTesting(false)

            // Lottie pulse/rings (matching main timer settings)
            LottieView(
                animationName: "FocusRings",
                loopMode: .loop,
                animationSpeed: 0.5,
                contentMode: .scaleAspectFit,
                animationTrigger: focusRingsTrigger,
                freezeOnLastFrame: false
            )
            .frame(width: 100, height: 100)
            .opacity(0.6)
            .allowsHitTesting(false)

            // Progress ring (with dynamic warning colors like main timer)
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: ringLineWidth)
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        AngularGradient(colors: ringColors, center: .center),
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(1 + (0.06 * warningFraction))
                    .animation(.easeInOut(duration: 0.2), value: clampedProgress)
                    .animation(.easeInOut(duration: 0.3), value: warningFraction)
            }
            .frame(width: diameter - 6, height: diameter - 6)
            .allowsHitTesting(false)

            // Remaining time label (bigger to match main timer's scale)
            Text(viewModel.remainingTimeLabel)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
                .padding(.horizontal, 4)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsHitTesting(false)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .contentShape(Circle())
    }

    var body: some View {
        fabContent
            .scaleEffect(isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isPressed)
            .offset(x: dragOffset.width + tempDrag.width, y: dragOffset.height + tempDrag.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        tempDrag = value.translation
                    }
                    .onEnded { value in
                        dragOffset.width += value.translation.width
                        dragOffset.height += value.translation.height
                        tempDrag = .zero
                    }
            )
            .onTapGesture {
                // Light haptic and navigate to Focus tab
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        isPressed = false
                    }
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .focus
                }
            }
            .accessibilityLabel("Active focus timer")
            .accessibilityValue(viewModel.remainingTimeLabel)
            .accessibilityHint("Double-tap to open Focus. Drag to move.")
    }
}

// MARK: - Color Blending Extension (matching main timer)
private extension Color {
    func blended(withFraction fraction: Double, of color: Color) -> Color {
        let clampedFraction = min(max(fraction, 0), 1)
        let from = UIColor(self)
        let to = UIColor(color)

        var fromRed: CGFloat = 0
        var fromGreen: CGFloat = 0
        var fromBlue: CGFloat = 0
        var fromAlpha: CGFloat = 0
        from.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)

        var toRed: CGFloat = 0
        var toGreen: CGFloat = 0
        var toBlue: CGFloat = 0
        var toAlpha: CGFloat = 0
        to.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)

        return Color(
            red: Double(fromRed + (toRed - fromRed) * clampedFraction),
            green: Double(fromGreen + (toGreen - fromGreen) * clampedFraction),
            blue: Double(fromBlue + (toBlue - fromBlue) * clampedFraction),
            opacity: Double(fromAlpha + (toAlpha - fromAlpha) * clampedFraction)
        )
    }
}

#Preview {
    let container = DependencyContainer.shared
    return ZStack {
        Color.black.ignoresSafeArea()
        MiniFocusTimerFAB(
            viewModel: container.focusViewModel,
            selectedTab: .constant(.focus),
            dragOffset: .constant(.zero)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 16)
        .padding(.bottom, 24)
    }
}
