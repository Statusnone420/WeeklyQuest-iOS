import SwiftUI
import Lottie

// MARK: - UIColor Extension for Lottie
private extension UIColor {
    var lottieColorValue: LottieColor {
        var r: CGFloat = 1
        var g: CGFloat = 1
        var b: CGFloat = 1
        var a: CGFloat = 1
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return LottieColor(r: Double(r), g: Double(g), b: Double(b), a: Double(a))
    }
}

struct LottieView: UIViewRepresentable, Equatable {
    let animationName: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    let contentMode: UIView.ContentMode
    let animationTrigger: UUID
    let freezeOnLastFrame: Bool
    let renderingEngine: RenderingEngineOption
    let tintColor: UIColor?
    
    enum RenderingEngineOption: Equatable {
        case automatic
        case mainThread
        case coreAnimation
    }
    
    // Implement Equatable to prevent unnecessary updates
    static func == (lhs: LottieView, rhs: LottieView) -> Bool {
        lhs.animationName == rhs.animationName &&
        lhs.loopMode == rhs.loopMode &&
        lhs.animationSpeed == rhs.animationSpeed &&
        lhs.contentMode == rhs.contentMode &&
        lhs.animationTrigger == rhs.animationTrigger &&
        lhs.freezeOnLastFrame == rhs.freezeOnLastFrame &&
        lhs.renderingEngine == rhs.renderingEngine &&
        lhs.tintColor == rhs.tintColor
    }
    
    init(
        animationName: String,
        loopMode: LottieLoopMode = .playOnce,
        animationSpeed: CGFloat = 1.0,
        contentMode: UIView.ContentMode = .scaleAspectFit,
        animationTrigger: UUID = UUID(),
        freezeOnLastFrame: Bool = true,
        renderingEngine: RenderingEngineOption = .automatic,
        tintColor: UIColor? = nil
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
        self.contentMode = contentMode
        self.animationTrigger = animationTrigger
        self.freezeOnLastFrame = freezeOnLastFrame
        self.renderingEngine = renderingEngine
        self.tintColor = tintColor
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        // Configure rendering engine based on option
        let configuration: LottieConfiguration
        switch renderingEngine {
        case .automatic:
            configuration = LottieConfiguration(renderingEngine: .automatic)
        case .mainThread:
            configuration = LottieConfiguration(renderingEngine: .mainThread)
        case .coreAnimation:
            configuration = LottieConfiguration(renderingEngine: .coreAnimation)
        }
        
        let animationView = LottieAnimationView(name: animationName, configuration: configuration)
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.contentMode = contentMode
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply tint color if provided
        if let tintColor {
            let keypath = AnimationKeypath(keypath: "**.Color")
            let provider = ColorValueProvider(tintColor.lottieColorValue)
            animationView.setValueProvider(provider, keypath: keypath)
        }
        
        // Ensure colors are rendered properly (not grayscale)
        animationView.shouldRasterizeWhenIdle = false
        animationView.layer.shouldRasterize = false
        
        // Store reference to animation view for updates
        containerView.tag = animationTrigger.hashValue
        
        containerView.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Play and stop on last frame
        animationView.play { finished in
            if finished && freezeOnLastFrame && loopMode == .playOnce {
                // Keep showing the last frame (chest open)
                animationView.currentProgress = 1.0
            }
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = uiView.subviews.first as? LottieAnimationView else { return }
        
        // Always ensure animation speed and loop mode are correct (prevents timer interference)
        if animationView.animationSpeed != animationSpeed {
            animationView.animationSpeed = animationSpeed
        }
        
        if animationView.loopMode != loopMode {
            animationView.loopMode = loopMode
        }
        
        // Check if trigger changed (replay requested)
        if uiView.tag != animationTrigger.hashValue {
            uiView.tag = animationTrigger.hashValue
            
            // Replay the animation
            animationView.play { finished in
                if finished && freezeOnLastFrame && loopMode == .playOnce {
                    animationView.currentProgress = 1.0
                }
            }
        }
    }
}
