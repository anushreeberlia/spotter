import Foundation
import simd

struct SquatConfig: ExerciseConfig {
    let id = "barbell_squat"
    let displayName = "Barbell Squat"
    let category: ExerciseCategory = .legs
    let topThreshold: Float = 150
    let bottomThreshold: Float = 100

    var primaryAngle: (PoseFrame) -> Float {
        { frame in frame.angles.averageKnee() }
    }

    var keyJoints: [JointName] {
        [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle, .chest]
    }

    var formRules: [FormRule] {
        [
            SquatDepthRule(),
            SquatKneeValgusRule(),
            SquatBackRoundingRule(),
            SquatHeelRiseRule(),
            SquatKneeTrackingRule(),
        ]
    }

    var hasFormAvatar: Bool { true }

    func formAvatarJoints(depth: Float, userFrame: PoseFrame) -> [JointName: SIMD3<Float>]? {
        FormReferencePose.squat(depth: depth, userFrame: userFrame)
    }
}

// MARK: - Squat Form Rules

/// Checks if the user reaches adequate depth at the bottom.
struct SquatDepthRule: FormRule {
    let ruleId = "squat_depth"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .ascending else { return nil }
        let kneeAngle = frame.angles.averageKnee()
        if kneeAngle > 110 {
            return FormCorrection(
                joint: .leftKnee,
                severity: .warning,
                message: "Go deeper",
                ruleId: ruleId
            )
        }
        return nil
    }
}

/// Checks if knees collapse inward (valgus).
struct SquatKneeValgusRule: FormRule {
    let ruleId = "squat_knee_valgus"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .descending || phase == .bottom || phase == .ascending else { return nil }

        guard let kneeWidth = frame.horizontalDistance(from: .leftKnee, to: .rightKnee),
              let hipWidth = frame.horizontalDistance(from: .leftHip, to: .rightHip) else {
            return nil
        }

        if kneeWidth < hipWidth * 0.75 {
            return FormCorrection(
                joint: .leftKnee,
                severity: .error,
                message: "Push your knees out",
                ruleId: ruleId
            )
        }
        return nil
    }
}

/// Checks for excessive forward lean / back rounding.
struct SquatBackRoundingRule: FormRule {
    let ruleId = "squat_back_rounding"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .descending || phase == .bottom || phase == .ascending else { return nil }

        let backAngle = frame.angles.backAngle
        if backAngle > 0 && backAngle < 45 {
            return FormCorrection(
                joint: .chest,
                severity: .error,
                message: "Chest up",
                ruleId: ruleId
            )
        }
        return nil
    }
}

/// Checks if heels are rising off the ground.
struct SquatHeelRiseRule: FormRule {
    let ruleId = "squat_heel_rise"
    private var referenceAnkleY: Float?

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .descending || phase == .bottom else { return nil }

        guard let leftAnkleY = frame.height(of: .leftAnkle),
              let rightAnkleY = frame.height(of: .rightAnkle) else {
            return nil
        }

        let avgAnkleY = (leftAnkleY + rightAnkleY) / 2
        // If ankles are notably above ground level (positive Y shift), heels are rising.
        // ARKit Y=0 is at the detected floor, so ankle should stay near a baseline.
        if avgAnkleY > 0.08 {
            return FormCorrection(
                joint: .leftAnkle,
                severity: .warning,
                message: "Keep heels on the ground",
                ruleId: ruleId
            )
        }
        return nil
    }
}

/// Checks if knees travel too far beyond toes.
struct SquatKneeTrackingRule: FormRule {
    let ruleId = "squat_knee_tracking"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .bottom || phase == .descending else { return nil }

        guard let leftKnee = frame.position(of: .leftKnee),
              let leftAnkle = frame.position(of: .leftAnkle) else {
            return nil
        }

        // In the Z-axis (depth from camera), knee shouldn't be much farther than ankle
        let kneeForward = leftKnee.z - leftAnkle.z
        if kneeForward > 0.15 {
            return FormCorrection(
                joint: .leftKnee,
                severity: .warning,
                message: "Sit back more",
                ruleId: ruleId
            )
        }
        return nil
    }
}
