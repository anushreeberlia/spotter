import Foundation

struct LungeConfig: ExerciseConfig {
    let id = "lunge"
    let displayName = "Lunge"
    let category: ExerciseCategory = .legs
    let topThreshold: Float = 155
    let bottomThreshold: Float = 95

    var primaryAngle: (PoseFrame) -> Float {
        { frame in min(frame.angles.leftKnee, frame.angles.rightKnee) }
    }

    var keyJoints: [JointName] {
        [.leftKnee, .rightKnee, .leftAnkle, .rightAnkle, .chest]
    }

    var formRules: [FormRule] {
        [LungeKneeOverToeRule(), LungeTorsoLeanRule()]
    }
}

struct LungeKneeOverToeRule: FormRule {
    let ruleId = "lunge_knee_over_toe"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .bottom || phase == .descending else { return nil }

        guard let leftKnee = frame.position(of: .leftKnee),
              let leftAnkle = frame.position(of: .leftAnkle) else { return nil }

        let kneeForward = leftKnee.z - leftAnkle.z
        if kneeForward > 0.12 {
            return FormCorrection(
                joint: .leftKnee,
                severity: .warning,
                message: "Don't let your knee pass your toes",
                ruleId: ruleId
            )
        }
        return nil
    }
}

struct LungeTorsoLeanRule: FormRule {
    let ruleId = "lunge_torso_lean"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase != .standing else { return nil }
        let backAngle = frame.angles.backAngle
        if backAngle > 0 && backAngle < 50 {
            return FormCorrection(
                joint: .chest,
                severity: .warning,
                message: "Keep your torso upright",
                ruleId: ruleId
            )
        }
        return nil
    }
}
