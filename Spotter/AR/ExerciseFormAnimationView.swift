import QuartzCore
import RealityKit
import SwiftUI

/// Full-screen 3D stick figure looping correct form — no camera, no overlay on the user.
struct ExerciseFormAnimationView: UIViewRepresentable {
    let exercise: any ExerciseConfig

    func makeCoordinator() -> Coordinator {
        Coordinator(exercise: exercise)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        arView.environment.background = .color(.init(white: 0.08, alpha: 1))
        context.coordinator.start(arView: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.exercise = exercise
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator {
        var exercise: any ExerciseConfig
        private weak var arView: ARView?
        private let skeleton = SkeletonRenderer(role: .formReference)
        private var displayLink: CADisplayLink?
        private var startTime: CFTimeInterval = 0

        init(exercise: any ExerciseConfig) {
            self.exercise = exercise
        }

        func start(arView: ARView) {
            self.arView = arView
            skeleton.attach(to: arView)
            addLighting(to: arView)
            startTime = CACurrentMediaTime()

            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        func stop() {
            displayLink?.invalidate()
            displayLink = nil
            skeleton.hide()
        }

        @objc private func tick() {
            guard arView != nil else { return }
            let t = CACurrentMediaTime() - startTime
            // ~3.5s full down–up cycle
            let phase = Float((sin(t * 2 * .pi / 3.5) + 1) / 2)

            guard let joints = exercise.demoReferenceJoints(depth: phase) else {
                skeleton.hide()
                return
            }
            let angles = AngleCalculator.computeAngles(from: joints)
            let frame = PoseFrame(
                timestamp: t,
                joints: joints,
                angles: angles,
                isTracked: true
            )
            skeleton.update(with: frame)
        }

        private func addLighting(to arView: ARView) {
            // RealityKit allows one directional light per scene; orientation matters, not position.
            let anchor = AnchorEntity(world: .zero)
            var light = DirectionalLightComponent()
            light.intensity = 4500
            light.isRealWorldProxy = false
            anchor.components.set(light)
            anchor.look(at: SIMD3<Float>(0, 0.9, -1.5), from: SIMD3<Float>(0.5, 2.2, 1.2), relativeTo: nil)
            arView.scene.addAnchor(anchor)
        }
    }
}
