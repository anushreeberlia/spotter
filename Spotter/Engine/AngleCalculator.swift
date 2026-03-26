import Foundation
import simd

struct AngleCalculator {

    /// Compute the angle at vertex B formed by points A-B-C, in degrees.
    /// Returns value in range [0, 180].
    static func angle(
        _ a: SIMD3<Float>,
        _ b: SIMD3<Float>,
        _ c: SIMD3<Float>
    ) -> Float {
        let v1 = a - b
        let v2 = c - b
        let dot = simd_dot(v1, v2)
        let cross = simd_length(simd_cross(v1, v2))
        let radians = atan2(cross, dot)
        return radians * (180 / .pi)
    }

    /// Compute all relevant joint angles from a set of joint positions.
    static func computeAngles(from joints: [JointName: SIMD3<Float>]) -> JointAngles {
        var angles = JointAngles()

        if let lh = joints[.leftHip], let lk = joints[.leftKnee], let la = joints[.leftAnkle] {
            angles.leftKnee = angle(lh, lk, la)
        }
        if let rh = joints[.rightHip], let rk = joints[.rightKnee], let ra = joints[.rightAnkle] {
            angles.rightKnee = angle(rh, rk, ra)
        }

        if let ls = joints[.leftShoulder], let lh = joints[.leftHip], let lk = joints[.leftKnee] {
            angles.leftHip = angle(ls, lh, lk)
        }
        if let rs = joints[.rightShoulder], let rh = joints[.rightHip], let rk = joints[.rightKnee] {
            angles.rightHip = angle(rs, rh, rk)
        }

        if let ls = joints[.leftShoulder], let le = joints[.leftElbow], let lw = joints[.leftWrist] {
            angles.leftElbow = angle(ls, le, lw)
        }
        if let rs = joints[.rightShoulder], let re = joints[.rightElbow], let rw = joints[.rightWrist] {
            angles.rightElbow = angle(rs, re, rw)
        }

        if let le = joints[.leftElbow], let ls = joints[.leftShoulder], let lh = joints[.leftHip] {
            angles.leftShoulder = angle(le, ls, lh)
        }
        if let re = joints[.rightElbow], let rs = joints[.rightShoulder], let rh = joints[.rightHip] {
            angles.rightShoulder = angle(re, rs, rh)
        }

        if let chest = joints[.chest], let hip = joints[.hips], let knee = joints[.leftKnee] ?? joints[.rightKnee] {
            angles.backAngle = angle(chest, hip, knee)
        }

        return angles
    }
}
