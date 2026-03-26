import Foundation
import ARKit
import RealityKit
import Combine

@Observable
class ARSessionManager: NSObject {
    var currentFrame: PoseFrame?
    var isTracking = false
    var trackingMessage = "Looking for body..."

    private var arView: ARView?
    private let skeletonRenderer = SkeletonRenderer()
    private let formReferenceRenderer = SkeletonRenderer(role: .formReference)
    private var usesBodyTracking = false

    /// Set from `WorkoutView` so the green form avatar matches the active exercise.
    var exerciseForFormAvatar: (any ExerciseConfig)?

    func setupSession(in arView: ARView) {
        self.arView = arView
        arView.session.delegate = self
        skeletonRenderer.attach(to: arView)
        formReferenceRenderer.attach(to: arView)

        if ARBodyTrackingConfiguration.isSupported {
            usesBodyTracking = true
            let config = ARBodyTrackingConfiguration()
            config.automaticSkeletonScaleEstimationEnabled = true
            arView.session.run(config)
            trackingMessage = "Move back so your full body is visible"
        } else if ARWorldTrackingConfiguration.isSupported {
            usesBodyTracking = false
            // Still run the camera; otherwise ARView stays black with no session.
            arView.session.run(ARWorldTrackingConfiguration())
            trackingMessage = "Body tracking not supported on this device"
        } else {
            usesBodyTracking = false
            trackingMessage = "AR not supported on this device"
        }
    }

    func pauseSession() {
        arView?.session.pause()
        isTracking = false
        formReferenceRenderer.hide()
    }

    func resumeSession() {
        guard let arView = arView else { return }
        if usesBodyTracking {
            let config = ARBodyTrackingConfiguration()
            config.automaticSkeletonScaleEstimationEnabled = true
            arView.session.run(config)
        } else if ARWorldTrackingConfiguration.isSupported {
            arView.session.run(ARWorldTrackingConfiguration())
        }
    }
}

extension ARSessionManager: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let bodyAnchor = anchors.compactMap({ $0 as? ARBodyAnchor }).first else {
            return
        }

        isTracking = true
        trackingMessage = "Tracking"

        let skeleton = bodyAnchor.skeleton
        let bodyTransform = bodyAnchor.transform

        var jointPositions: [JointName: SIMD3<Float>] = [:]

        for joint in JointName.allCases {
            guard let modelTransform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: joint.rawValue)) else {
                continue
            }

            let worldTransform = bodyTransform * modelTransform
            let position = SIMD3<Float>(
                worldTransform.columns.3.x,
                worldTransform.columns.3.y,
                worldTransform.columns.3.z
            )
            jointPositions[joint] = position
        }

        let angles = AngleCalculator.computeAngles(from: jointPositions)

        let frame = PoseFrame(
            timestamp: CACurrentMediaTime(),
            joints: jointPositions,
            angles: angles,
            isTracked: true
        )

        currentFrame = frame
        skeletonRenderer.update(with: frame)
        updateFormAvatar(with: frame)
    }

    private func updateFormAvatar(with frame: PoseFrame) {
        guard let exercise = exerciseForFormAvatar else {
            formReferenceRenderer.hide()
            return
        }
        let angle = exercise.primaryAngle(frame)
        let depth = FormAvatarDepth.normalized(angle: angle, top: exercise.topThreshold, bottom: exercise.bottomThreshold)
        guard let joints = exercise.formAvatarJoints(depth: depth, userFrame: frame) else {
            formReferenceRenderer.hide()
            return
        }
        let angles = AngleCalculator.computeAngles(from: joints)
        let refFrame = PoseFrame(
            timestamp: frame.timestamp,
            joints: joints,
            angles: angles,
            isTracked: true
        )
        formReferenceRenderer.update(with: refFrame)
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        trackingMessage = "AR session error: \(error.localizedDescription)"
        isTracking = false
    }

    func sessionWasInterrupted(_ session: ARSession) {
        trackingMessage = "Session interrupted"
        isTracking = false
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        trackingMessage = "Resuming tracking..."
        resumeSession()
    }
}
