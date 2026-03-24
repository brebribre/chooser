import SwiftUI
import UIKit

// MARK: - UIViewRepresentable Wrapper

struct MultiTouchCanvas: UIViewRepresentable {
    @ObservedObject var engine: GameEngine

    func makeUIView(context: Context) -> TouchCanvasUIView {
        let view = TouchCanvasUIView()
        view.engine = engine
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: TouchCanvasUIView, context: Context) {
        uiView.engine = engine
    }
}

// MARK: - Touch Handling UIView

final class TouchCanvasUIView: UIView {
    weak var engine: GameEngine?

    /// Shift the touch point up so the circle appears centered under the finger pad
    private let fingerOffset: CGFloat = -30

    private func adjustedPoint(for touch: UITouch) -> CGPoint {
        let raw = touch.location(in: self)
        return CGPoint(x: raw.x, y: raw.y + fingerOffset)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            let point = adjustedPoint(for: touch)
            engine?.fingerDown(id: id, position: point)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            let point = adjustedPoint(for: touch)
            engine?.fingerMoved(id: id, position: point)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            engine?.fingerUp(id: id)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        guard let touches else { return }
        for touch in touches {
            let id = ObjectIdentifier(touch)
            engine?.fingerUp(id: id)
        }
    }
}
