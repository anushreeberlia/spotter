import Foundation
import simd

/// Joint identifiers matching ARKit's body tracking skeleton.
enum JointName: String, CaseIterable, Hashable {
    case head = "head_joint"
    case neck = "neck_1_joint"

    case leftShoulder = "left_shoulder_1_joint"
    case rightShoulder = "right_shoulder_1_joint"
    case leftElbow = "left_forearm_joint"
    case rightElbow = "right_forearm_joint"
    case leftWrist = "left_hand_joint"
    case rightWrist = "right_hand_joint"

    case hips = "hips_joint"
    case leftHip = "left_upLeg_joint"
    case rightHip = "right_upLeg_joint"
    case leftKnee = "left_leg_joint"
    case rightKnee = "right_leg_joint"
    case leftAnkle = "left_foot_joint"
    case rightAnkle = "right_foot_joint"

    case spine = "spine_4_joint"
    case chest = "spine_7_joint"
}

/// Angles computed from joint positions for a single frame.
struct JointAngles {
    var leftKnee: Float = 0
    var rightKnee: Float = 0
    var leftHip: Float = 0
    var rightHip: Float = 0
    var leftElbow: Float = 0
    var rightElbow: Float = 0
    var leftShoulder: Float = 0
    var rightShoulder: Float = 0
    var backAngle: Float = 0

    func averageKnee() -> Float { (leftKnee + rightKnee) / 2 }
    func averageHip() -> Float { (leftHip + rightHip) / 2 }
    func averageElbow() -> Float { (leftElbow + rightElbow) / 2 }
    func averageShoulder() -> Float { (leftShoulder + rightShoulder) / 2 }
}

/// A snapshot of body pose data for a single frame.
struct PoseFrame {
    let timestamp: TimeInterval
    let joints: [JointName: SIMD3<Float>]
    let angles: JointAngles
    let isTracked: Bool

    func position(of joint: JointName) -> SIMD3<Float>? {
        joints[joint]
    }

    /// Horizontal distance between two joints (ignores Y axis).
    func horizontalDistance(from a: JointName, to b: JointName) -> Float? {
        guard let posA = joints[a], let posB = joints[b] else { return nil }
        let dx = posA.x - posB.x
        let dz = posA.z - posB.z
        return sqrt(dx * dx + dz * dz)
    }

    /// Vertical position of a joint.
    func height(of joint: JointName) -> Float? {
        joints[joint]?.y
    }
}
