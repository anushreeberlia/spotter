import Foundation

struct RowConfig: ExerciseConfig {
    let id = "barbell_row"
    let displayName = "Barbell Row"
    let category: ExerciseCategory = .pull
    let topThreshold: Float = 150
    let bottomThreshold: Float = 70

    var primaryAngle: (PoseFrame) -> Float {
        { frame in frame.angles.averageElbow() }
    }

    var keyJoints: [JointName] {
        [.leftElbow, .rightElbow, .chest, .hips]
    }

    var formRules: [FormRule] {
        [RowBackRule(), RowBodySwingRule()]
    }
}

struct RowBackRule: FormRule {
    let ruleId = "row_back_rounding"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        let backAngle = frame.angles.backAngle
        if backAngle > 0 && backAngle < 35 {
            return FormCorrection(
                joint: .chest,
                severity: .error,
                message: "Keep your back flat",
                ruleId: ruleId
            )
        }
        return nil
    }
}

struct RowBodySwingRule: FormRule {
    let ruleId = "row_body_swing"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        let hipAngle = frame.angles.averageHip()
        if hipAngle > 140 {
            return FormCorrection(
                joint: .hips,
                severity: .warning,
                message: "Stop swinging your body",
                ruleId: ruleId
            )
        }
        return nil
    }
}
