import Foundation

struct DeadliftConfig: ExerciseConfig {
    let id = "deadlift"
    let displayName = "Deadlift / RDL"
    let category: ExerciseCategory = .legs
    let topThreshold: Float = 160
    let bottomThreshold: Float = 90

    var primaryAngle: (PoseFrame) -> Float {
        { frame in frame.angles.averageHip() }
    }

    var keyJoints: [JointName] {
        [.leftHip, .rightHip, .chest, .leftKnee, .rightKnee]
    }

    var formRules: [FormRule] {
        [DeadliftBackRule(), DeadliftLockoutRule()]
    }
}

struct DeadliftBackRule: FormRule {
    let ruleId = "deadlift_back_rounding"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase != .standing else { return nil }
        let backAngle = frame.angles.backAngle
        if backAngle > 0 && backAngle < 40 {
            return FormCorrection(
                joint: .chest,
                severity: .error,
                message: "Keep your back straight",
                ruleId: ruleId
            )
        }
        return nil
    }
}

struct DeadliftLockoutRule: FormRule {
    let ruleId = "deadlift_lockout"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .standing else { return nil }
        let hipAngle = frame.angles.averageHip()
        if hipAngle < 165 {
            return FormCorrection(
                joint: .hips,
                severity: .warning,
                message: "Lock out your hips",
                ruleId: ruleId
            )
        }
        return nil
    }
}
