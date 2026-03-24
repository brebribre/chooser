import SwiftUI
import Combine

final class GameEngine: ObservableObject {
    @Published var phase: GamePhase = .idle
    @Published var fingers: [ObjectIdentifier: FingerInfo] = [:]
    @Published var winnerID: ObjectIdentifier?
    @Published var countdownValue: Int = 3

    let settings: GameSettings

    private var stabilizationTimer: DispatchWorkItem?
    private var countdownTimer: Timer?
    private var fingerOrderCounter = 0

    init(settings: GameSettings) {
        self.settings = settings
    }

    // MARK: - Touch Handling

    func fingerDown(id: ObjectIdentifier, position: CGPoint) {
        guard phase == .idle || phase == .registering else { return }

        fingerOrderCounter += 1
        let color = ColorPalette.color(for: fingers.count)
        let finger = FingerInfo(
            id: id,
            position: position,
            color: color,
            orderPlaced: fingerOrderCounter,
            state: .active,
            timestamp: Date()
        )
        fingers[id] = finger

        if phase == .idle {
            phase = .registering
        }

        resetStabilizationTimer()
        triggerHaptic(.light)
    }

    func fingerMoved(id: ObjectIdentifier, position: CGPoint) {
        fingers[id]?.position = position
    }

    func fingerUp(id: ObjectIdentifier) {
        fingers.removeValue(forKey: id)

        switch phase {
        case .registering:
            if fingers.isEmpty {
                reset()
            } else {
                resetStabilizationTimer()
            }
        case .countdown:
            cancelCountdown()
            if fingers.isEmpty {
                reset()
            } else {
                phase = .registering
                resetStabilizationTimer()
            }
        case .revealing, .result:
            if fingers.isEmpty {
                reset()
            }
        default:
            break
        }
    }

    // MARK: - Stabilization

    private func resetStabilizationTimer() {
        stabilizationTimer?.cancel()

        guard fingers.count >= 2 else { return }

        let work = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                self?.startCountdown()
            }
        }
        stabilizationTimer = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + settings.stabilizationDelay,
            execute: work
        )
    }

    // MARK: - Countdown

    private func startCountdown() {
        guard fingers.count >= 2 else { return }

        let total = max(1, Int(settings.countdownDuration))
        countdownValue = total
        phase = .countdown(remaining: total)
        triggerHaptic(.medium)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            self.countdownValue -= 1
            if self.countdownValue <= 0 {
                timer.invalidate()
                self.selectWinner()
            } else {
                self.phase = .countdown(remaining: self.countdownValue)
                self.triggerHaptic(.light)
            }
        }
    }

    private func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: - Selection Logic

    private func selectWinner() {
        let activeFingers = fingers.values.sorted { $0.orderPlaced < $1.orderPlaced }
        guard !activeFingers.isEmpty else {
            reset()
            return
        }

        let winner: FingerInfo

        switch settings.selectionMode {
        case .firstToTouch:
            winner = activeFingers.first!

        case .lastToTouch:
            winner = activeFingers.last!

        case .random:
            winner = activeFingers.randomElement()!

        case .custom:
            winner = selectWeighted(from: activeFingers)
        }

        winnerID = winner.id

        // Update finger states
        for key in fingers.keys {
            fingers[key]?.state = (key == winner.id) ? .winner : .eliminated
        }

        triggerHaptic(.success)

        // Go straight to result — no revealing delay
        phase = .result
    }

    private func selectWeighted(from sortedFingers: [FingerInfo]) -> FingerInfo {
        let favoredIndex = settings.favoredPosition - 1
        let probability = settings.favoredProbability / 100.0

        guard favoredIndex >= 0, favoredIndex < sortedFingers.count else {
            return sortedFingers.randomElement()!
        }

        let roll = Double.random(in: 0..<1)
        if roll < probability {
            return sortedFingers[favoredIndex]
        } else {
            // Pick randomly from the others
            var others = sortedFingers
            others.remove(at: favoredIndex)
            return others.randomElement() ?? sortedFingers[favoredIndex]
        }
    }

    // MARK: - Reset

    func reset() {
        stabilizationTimer?.cancel()
        cancelCountdown()
        phase = .idle
        fingers.removeAll()
        winnerID = nil
        fingerOrderCounter = 0
    }

    // MARK: - Haptics

    private func triggerHaptic(_ style: HapticStyle) {
        switch style {
        case .light:
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.prepare()
            gen.impactOccurred()
        case .medium:
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.prepare()
            gen.impactOccurred()
        case .success:
            let gen = UINotificationFeedbackGenerator()
            gen.prepare()
            gen.notificationOccurred(.success)
        }
    }

    private enum HapticStyle {
        case light, medium, success
    }
}
