import Foundation

struct PlankConfig: ExerciseConfig {
    let id = "plank"
    let displayName = "Plank"
    let category: ExerciseCategory = .core
    let isIsometric = true

    // Plank doesn't use rep detection — it tracks hold time.
    let topThreshold: Float = 180
    let bottomThreshold: Float = 160

    var primaryAngle: (PoseFrame) -> Float {
        { frame in frame.angles.backAngle }
    }

    var keyJoints: [JointName] {
        [.leftShoulder, .rightShoulder, .hips, .leftAnkle, .rightAnkle]
    }

    var formRules: [FormRule] {
        [PlankHipSagRule(), PlankHipPikeRule()]
    }
}

struct PlankHipSagRule: FormRule {
    let ruleId = "plank_hip_sag"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard let shoulder = frame.position(of: .leftShoulder),
              let hip = frame.position(of: .hips),
              let ankle = frame.position(of: .leftAnkle) else { return nil }

        // Shoulder and ankle define the "straight line"; hip should be on or above it
        let expectedHipY = shoulder.y + (ankle.y - shoulder.y) * 0.5
        if hip.y < expectedHipY - 0.06 {
            return FormCorrection(
                joint: .hips,
                severity: .error,
                message: "Hips are sagging — squeeze your core",
                ruleId: ruleId
            )
        }
        return nil
    }
}

struct PlankHipPikeRule: FormRule {
    let ruleId = "plank_hip_pike"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard let shoulder = frame.position(of: .leftShoulder),
              let hip = frame.position(of: .hips),
              let ankle = frame.position(of: .leftAnkle) else { return nil }

        let expectedHipY = shoulder.y + (ankle.y - shoulder.y) * 0.5
        if hip.y > expectedHipY + 0.10 {
            return FormCorrection(
                joint: .hips,
                severity: .warning,
                message: "Lower your hips — don't pike up",
                ruleId: ruleId
            )
        }
        return nil
    }
}
