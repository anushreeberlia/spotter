import Foundation

struct CurlConfig: ExerciseConfig {
    let id = "bicep_curl"
    let displayName = "Bicep Curl"
    let category: ExerciseCategory = .pull
    let topThreshold: Float = 150
    let bottomThreshold: Float = 50

    var primaryAngle: (PoseFrame) -> Float {
        { frame in frame.angles.averageElbow() }
    }

    var keyJoints: [JointName] {
        [.leftElbow, .rightElbow, .leftShoulder, .rightShoulder]
    }

    var formRules: [FormRule] {
        [CurlShoulderSwingRule(), CurlROMRule()]
    }
}

struct CurlShoulderSwingRule: FormRule {
    let ruleId = "curl_shoulder_swing"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .ascending else { return nil }

        let shoulderAngle = frame.angles.averageShoulder()
        // Shoulder should stay relatively static during a curl
        if shoulderAngle > 45 {
            return FormCorrection(
                joint: .leftShoulder,
                severity: .warning,
                message: "Keep your elbows pinned — don't swing",
                ruleId: ruleId
            )
        }
        return nil
    }
}

struct CurlROMRule: FormRule {
    let ruleId = "curl_rom"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .standing else { return nil }
        let elbowAngle = frame.angles.averageElbow()
        if elbowAngle < 140 {
            return FormCorrection(
                joint: .leftElbow,
                severity: .info,
                message: "Fully extend your arms at the bottom",
                ruleId: ruleId
            )
        }
        return nil
    }
}
