import SpriteKit
import SwiftUI

/// Wraps `SKView` so we get native 120fps rendering and conflict-free UIKit Tap / Pan / Pinch gestures.
public struct PuzzleBoardView: UIViewRepresentable {
    public let scene: PuzzleBoardScene

    public init(scene: PuzzleBoardScene) {
        self.scene = scene
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(scene: scene)
    }

    public func makeUIView(context: Context) -> SKView {
        let skView = SKView(frame: .zero)
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 120
        skView.allowsTransparency = false
        skView.presentScene(scene)

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        panGesture.delegate = context.coordinator

        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pinchGesture.delegate = context.coordinator

        // Prevent accidental taps when the user starts panning or zooming
        tapGesture.require(toFail: panGesture)

        skView.addGestureRecognizer(tapGesture)
        skView.addGestureRecognizer(panGesture)
        skView.addGestureRecognizer(pinchGesture)

        return skView
    }

    public func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }
    }

    public final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let scene: PuzzleBoardScene

        init(scene: PuzzleBoardScene) {
            self.scene = scene
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, let view = gesture.view else { return }
            let location = gesture.location(in: view)
            scene.handleTap(atViewPoint: location)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            if gesture.state == .changed {
                let translation = gesture.translation(in: view)
                scene.handlePan(translationInView: translation)
                gesture.setTranslation(.zero, in: view)
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = gesture.view else { return }
            if gesture.state == .changed {
                let anchor = gesture.location(in: view)
                scene.handlePinch(scaleDelta: gesture.scale, anchorInView: anchor)
                gesture.scale = 1.0
            }
        }

        public func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            let isPanAndPinch =
                (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) ||
                (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer)
            return isPanAndPinch
        }
    }
}
