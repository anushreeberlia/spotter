import Foundation
import simd

struct PushupConfig: ExerciseConfig {
    let id = "pushup"
    let displayName = "Push-up"
    let category: ExerciseCategory = .push
    let topThreshold: Float = 150
    let bottomThreshold: Float = 90

    var primaryAngle: (PoseFrame) -> Float {
        { frame in frame.angles.averageElbow() }
    }

    var keyJoints: [JointName] {
        [.leftElbow, .rightElbow, .leftShoulder, .rightShoulder, .hips]
    }

    var formRules: [FormRule] {
        [PushupHipSagRule(), PushupElbowFlareRule()]
    }

    var hasFormAvatar: Bool { true }

    func formAvatarJoints(depth: Float, userFrame: PoseFrame) -> [JointName: SIMD3<Float>]? {
        FormReferencePose.pushup(depth: depth, userFrame: userFrame)
    }
}

struct PushupHipSagRule: FormRule {
    let ruleId = "pushup_hip_sag"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard let shoulder = frame.position(of: .leftShoulder),
              let hip = frame.position(of: .hips),
              let ankle = frame.position(of: .leftAnkle) else { return nil }

        let shoulderToHip = hip.y - shoulder.y
        let hipToAnkle = ankle.y - hip.y

        // If hip sags below the shoulder-ankle line
        if shoulderToHip > 0.08 && hipToAnkle < -0.05 {
            return FormCorrection(
                joint: .hips,
                severity: .error,
                message: "Keep your hips up",
                ruleId: ruleId
            )
        }
        return nil
    }
}

struct PushupElbowFlareRule: FormRule {
    let ruleId = "pushup_elbow_flare"

    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection? {
        guard phase == .bottom || phase == .descending else { return nil }

        guard let elbowWidth = frame.horizontalDistance(from: .leftElbow, to: .rightElbow),
              let shoulderWidth = frame.horizontalDistance(from: .leftShoulder, to: .rightShoulder) else {
            return nil
        }

        if elbowWidth > shoulderWidth * 1.5 {
            return FormCorrection(
                joint: .leftElbow,
                severity: .warning,
                message: "Tuck your elbows in",
                ruleId: ruleId
            )
        }
        return nil
    }
}
