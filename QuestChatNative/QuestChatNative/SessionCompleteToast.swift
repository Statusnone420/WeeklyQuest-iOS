import SwiftUI

/// A compact, non-blocking toast that celebrates a completed session.
/// Shows XP gained, duration + friendly label, and a small action to jump back to Focus.
struct SessionCompleteToast: View {
    let xpGained: Int
    let minutes: Int
    let label: String
    var onOpenFocus: (() -> Void)? = nil

    @State private var animate = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("+\(xpGained) XP")
                    .font(.title2.weight(.bold))

                Text("\(minutes)-min \(label)")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("Chipping away at your next level")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Button {
                onOpenFocus?()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                    Text("Back to Focus")
                        .fontWeight(.semibold)
                }
                .font(.footnote)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.mint.opacity(0.2))
                .foregroundStyle(.mint)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 20)
        .scaleEffect(animate ? 1 : 0.97)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                animate = true
            }
        }
    }
}
