import Foundation

struct OverheadPressConfig: ExerciseConfig {
    let id = "overhead_press"
    let displayName = "Overhead Press"
    let category: ExerciseCategory = .push
    let topThreshold: Float = 160
    let bottomThreshold: Float = 90

    var primaryAngle: (PoseFrame) -> Float {
        { frame in frame.angles.averageElbow() }
    }

    var keyJoints: [JointName] {
        [.leftElbow, .rightElbow, .leftShoulder, .rightShoulder, .chest]
    }

    var formRules: [FormRule] {
        [OHPArchRule(), OHPLockoutRule()]
    }
}

struct OHPArchRule: FormRule {
    let ruleId = "ohp_excessive_arch"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .ascending || phase == .standing else { return nil }

        guard let chest = frame.position(of: .chest),
              let hip = frame.position(of: .hips) else { return nil }

        let archAmount = chest.z - hip.z
        if archAmount > 0.08 {
            return FormCorrection(
                joint: .chest,
                severity: .error,
                message: "Don't arch your back",
                ruleId: ruleId
            )
        }
        return nil
    }
}

struct OHPLockoutRule: FormRule {
    let ruleId = "ohp_lockout"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .standing else { return nil }
        let elbowAngle = frame.angles.averageElbow()
        if elbowAngle > 0 && elbowAngle < 165 {
            return FormCorrection(
                joint: .leftElbow,
                severity: .info,
                message: "Lock out at the top",
                ruleId: ruleId
            )
        }
        return nil
    }
}
