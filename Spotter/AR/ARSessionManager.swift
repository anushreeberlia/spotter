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

    func setupSession(in arView: ARView) {
        self.arView = arView

        guard ARBodyTrackingConfiguration.isSupported else {
            trackingMessage = "Body tracking not supported on this device"
            return
        }

        let config = ARBodyTrackingConfiguration()
        config.automaticSkeletonScaleEstimationEnabled = true

        arView.session.delegate = self
        arView.session.run(config)

        skeletonRenderer.attach(to: arView)
        trackingMessage = "Move back so your full body is visible"
    }

    func pauseSession() {
        arView?.session.pause()
        isTracking = false
    }

    func resumeSession() {
        guard let arView = arView else { return }
        let config = ARBodyTrackingConfiguration()
        config.automaticSkeletonScaleEstimationEnabled = true
        arView.session.run(config)
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
    }
}
