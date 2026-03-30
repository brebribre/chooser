import SwiftUI

struct ContentView: View {
    @StateObject private var settings: GameSettings
    @StateObject private var engine: GameEngine
    @State private var showSettings = false

    // Winner color spread animation
    @State private var winnerColorSpread: CGFloat = 0
    @State private var winnerColor: Color = .white
    @State private var winnerPosition: CGPoint = .zero
    @State private var showColorSpread = false

    init() {
        let s = GameSettings()
        let e = GameEngine(settings: s)
        _settings = StateObject(wrappedValue: s)
        _engine = StateObject(wrappedValue: e)
    }

    var body: some View {
        ZStack {
            // Background gradient
            GradientBackground(theme: settings.backgroundTheme)

            // Winner color spread overlay
            if showColorSpread {
                WinnerColorSpreadView(
                    color: winnerColor,
                    origin: winnerPosition,
                    spread: winnerColorSpread
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Touch canvas (invisible, handles all touches)
            MultiTouchCanvas(engine: engine)
                .ignoresSafeArea()

            // Finger circles overlay
            ForEach(Array(engine.fingers.values)) { finger in
                FingerCircleView(finger: finger, phase: engine.phase)
            }

            // Countdown overlay
            if case .countdown(let remaining) = engine.phase {
                CountdownOverlay(value: remaining)
            }

            // Idle instructions
            if engine.phase == .idle {
                IdleOverlay()
            }

            // Settings gear button — always visible when idle
            if engine.phase == .idle {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: engine.phase) { newPhase in
            if case .result = newPhase {
                triggerWinnerSpread()
            }
            if case .idle = newPhase {
                resetSpread()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
        }
    }

    // MARK: - Winner Color Spread

    private func triggerWinnerSpread() {
        guard let wID = engine.winnerID,
              let winner = engine.fingers[wID] else { return }

        winnerColor = winner.color
        winnerPosition = winner.position
        showColorSpread = true
        winnerColorSpread = 0

        // Spread out
        withAnimation(.easeOut(duration: 0.6)) {
            winnerColorSpread = 1.0
        }

        // Pull back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.5)) {
                winnerColorSpread = 0.0
            }
        }

        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showColorSpread = false
        }
    }

    private func resetSpread() {
        showColorSpread = false
        winnerColorSpread = 0
    }

}

// MARK: - Winner Color Spread View

struct WinnerColorSpreadView: View {
    let color: Color
    let origin: CGPoint
    let spread: CGFloat

    var body: some View {
        GeometryReader { geo in
            let maxDimension = max(geo.size.width, geo.size.height) * 2.5
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.5 * Double(spread)),
                            color.opacity(0.25 * Double(spread)),
                            color.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: maxDimension * 0.5 * spread
                    )
                )
                .frame(width: maxDimension * spread, height: maxDimension * spread)
                .position(origin)
        }
    }
}

// MARK: - Finger Circle View

struct FingerCircleView: View {
    let finger: FingerInfo
    let phase: GamePhase
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var appeared = false
    @State private var pulsing = false
    @State private var waitingPulse = false

    private var isIPad: Bool { sizeClass == .regular }

    private var isCountdown: Bool {
        if case .countdown = phase { return true }
        return false
    }

    private var circleSize: CGFloat {
        let scale: CGFloat = isIPad ? 1.5 : 1.0
        switch finger.state {
        case .active: return 140 * scale
        case .winner: return 180 * scale
        case .eliminated: return 0
        }
    }

    private var circleOpacity: Double {
        switch finger.state {
        case .active: return 0.85
        case .winner: return 1.0
        case .eliminated: return 0.0
        }
    }

    var body: some View {
        ZStack {
            // Waiting pulse ring during countdown / revealing
            if finger.state == .active && isCountdown {
                Circle()
                    .stroke(finger.color.opacity(0.4), lineWidth: 2)
                    .frame(width: circleSize, height: circleSize)
                    .scaleEffect(waitingPulse ? 1.6 : 1.0)
                    .opacity(waitingPulse ? 0.0 : 0.5)
                    .animation(
                        .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                        value: waitingPulse
                    )
            }

            // Glow ring for winner
            if finger.state == .winner {
                // Outer expanding ring
                Circle()
                    .stroke(finger.color, lineWidth: isIPad ? 6 : 4)
                    .frame(width: circleSize * 1.1, height: circleSize * 1.1)
                    .scaleEffect(pulsing ? 1.5 : 1.0)
                    .opacity(pulsing ? 0.0 : 0.7)
                    .animation(
                        .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: pulsing
                    )

                // Inner glow
                Circle()
                    .fill(finger.color.opacity(0.2))
                    .frame(width: circleSize * 1.22, height: circleSize * 1.22)
                    .scaleEffect(pulsing ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: pulsing
                    )
            }

            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [finger.color.opacity(0.9), finger.color],
                        center: .center,
                        startRadius: 0,
                        endRadius: circleSize / 2
                    )
                )
                .frame(width: circleSize, height: circleSize)
                .opacity(circleOpacity)
                .shadow(color: finger.color.opacity(0.6), radius: finger.state == .winner ? 30 : 20, x: 0, y: 0)
                .scaleEffect(appeared ? 1.0 : 0.0)
                .scaleEffect(finger.state == .active && isCountdown && waitingPulse ? 1.05 : 1.0)
                .animation(
                    finger.state == .active && isCountdown
                        ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                        : .default,
                    value: waitingPulse
                )

            // Winner crown icon
            if finger.state == .winner {
                Image(systemName: "crown.fill")
                    .font(.system(size: isIPad ? 42 : 28))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .position(finger.position)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: finger.state)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: finger.position)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                appeared = true
            }
            if finger.state == .winner {
                pulsing = true
            }
        }
        .onChange(of: finger.state) { newState in
            if newState == .winner {
                pulsing = true
                waitingPulse = false
            }
        }
        .onChange(of: isCountdown) { active in
            if active {
                waitingPulse = true
            } else {
                waitingPulse = false
            }
        }
    }
}

// MARK: - Countdown Overlay

struct CountdownOverlay: View {
    let value: Int

    var body: some View {
        // .id(value) forces a brand-new CountdownTickView each second
        CountdownTickView(value: value)
            .id(value)
    }
}

/// A single "tick" of the countdown. Because the parent recreates this via .id(),
/// onAppear fires fresh every second, restarting all animations.
private struct CountdownTickView: View {
    let value: Int
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 1.0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.6
    @State private var bgPulse: CGFloat = 0.6

    private var s: CGFloat { sizeClass == .regular ? 1.5 : 1.0 }

    var body: some View {
        ZStack {
            // Background shockwave ring — expands and fades each tick
            Circle()
                .stroke(.white.opacity(ringOpacity), lineWidth: 2)
                .frame(width: 160 * s, height: 160 * s)
                .scaleEffect(ringScale)

            // Soft background glow pulse
            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 260 * s, height: 260 * s)
                .scaleEffect(bgPulse)

            // Outer ring
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 4)
                .frame(width: 140 * s, height: 140 * s)

            // The number
            Text("\(value)")
                .font(.system(size: 80 * s, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(opacity))
                .scaleEffect(scale)
        }
        .onAppear {
            // Number punches in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                scale = 1.0
            }

            // Ring expands outward
            withAnimation(.easeOut(duration: 0.8)) {
                ringScale = 2.0
                ringOpacity = 0.0
            }

            // Background glow pulses
            withAnimation(.easeOut(duration: 0.6)) {
                bgPulse = 1.3
            }

            // Number fades and shrinks toward end of the second
            withAnimation(.easeIn(duration: 0.5).delay(0.45)) {
                opacity = 0.15
                scale = 0.7
            }
        }
    }
}

// MARK: - Idle Overlay

struct IdleOverlay: View {
    @State private var animating = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isIPad: Bool { sizeClass == .regular }

    var body: some View {
        VStack(spacing: isIPad ? 20 : 12) {
            Image(systemName: "hand.point.up.fill")
                .font(.system(size: isIPad ? 72 : 48))
                .foregroundStyle(.white.opacity(0.4))
                .scaleEffect(animating ? 1.08 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: animating
                )

            Text("Place fingers on screen")
                .font(.system(size: isIPad ? 32 : 22, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Text("2 or more players")
                .font(.system(size: isIPad ? 20 : 15, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
        }
        .onAppear { animating = true }
    }
}

// MARK: - Gradient Background

struct GradientBackground: View {
    let theme: BackgroundTheme
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: theme.colors,
            startPoint: animateGradient ? .topLeading : .topTrailing,
            endPoint: animateGradient ? .bottomTrailing : .bottomLeading
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true), value: animateGradient)
        .onAppear { animateGradient = true }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
