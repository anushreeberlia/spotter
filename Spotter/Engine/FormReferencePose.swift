import Foundation
import simd

/// Maps primary joint angle to 0 (top of rep) → 1 (bottom).
enum FormAvatarDepth {
    static func normalized(angle: Float, top: Float, bottom: Float) -> Float {
        guard top > bottom else { return 0 }
        let t = (top - angle) / (top - bottom)
        return simd_clamp(t, 0, 1)
    }
}

/// Builds world-space reference skeletons beside the user for form cues.
enum FormReferencePose {

    /// Reference squat: green avatar ~0.85 m to the user's right, matching their leg length.
    static func squat(depth: Float, userFrame: PoseFrame) -> [JointName: SIMD3<Float>]? {
        guard let hipMid = hipMidpoint(userFrame),
              let basis = worldBasis(userFrame) else { return nil }

        let (right, up, forward) = basis
        let scale = legScale(userFrame)
        let d = simd_clamp(depth, 0, 1)

        let origin = hipMid + right * 0.85 + up * Float(0.12)

        let lhStand = SIMD3<Float>(-0.11, 0, 0.02)
        let rhStand = SIMD3<Float>(0.11, 0, 0.02)
        let lkStand = SIMD3<Float>(-0.11, -0.42, 0.05)
        let rkStand = SIMD3<Float>(0.11, -0.42, 0.05)
        let laStand = SIMD3<Float>(-0.11, -0.82, 0.06)
        let raStand = SIMD3<Float>(0.11, -0.82, 0.06)

        let lkDeep = SIMD3<Float>(-0.2, -0.36, 0.22)
        let rkDeep = SIMD3<Float>(0.2, -0.36, 0.22)
        let laDeep = SIMD3<Float>(-0.16, -0.76, 0.32)
        let raDeep = SIMD3<Float>(0.16, -0.76, 0.32)

        let lh = lhStand
        let rh = rhStand
        let lk = lerp3(lkStand, lkDeep, d)
        let rk = lerp3(rkStand, rkDeep, d)
        let la = lerp3(laStand, laDeep, d)
        let ra = lerp3(raStand, raDeep, d)

        let chestS = SIMD3<Float>(0, 0.36, 0.03)
        let chestD = SIMD3<Float>(0, 0.38, 0.14)
        let neckS = SIMD3<Float>(0, 0.44, 0.04)
        let neckD = SIMD3<Float>(0, 0.45, 0.16)
        let headS = SIMD3<Float>(0, 0.52, 0.05)
        let headD = SIMD3<Float>(0, 0.53, 0.18)

        let lsS = SIMD3<Float>(-0.2, 0.28, 0.02)
        let rsS = SIMD3<Float>(0.2, 0.28, 0.02)
        let leS = SIMD3<Float>(-0.26, 0.12, 0.04)
        let reS = SIMD3<Float>(0.26, 0.12, 0.04)
        let lwS = SIMD3<Float>(-0.3, -0.02, 0.05)
        let rwS = SIMD3<Float>(0.3, -0.02, 0.05)

        let chestD2 = lerp3(chestS, chestD, d)
        let neckD2 = lerp3(neckS, neckD, d)
        let headD2 = lerp3(headS, headD, d)

        func w(_ local: SIMD3<Float>) -> SIMD3<Float> {
            origin + (right * local.x + up * local.y + forward * local.z) * scale
        }

        var joints: [JointName: SIMD3<Float>] = [:]
        joints[.hips] = w(SIMD3(0, 0, 0))
        joints[.leftHip] = w(lh * scale)
        joints[.rightHip] = w(rh * scale)
        joints[.leftKnee] = w(lk * scale)
        joints[.rightKnee] = w(rk * scale)
        joints[.leftAnkle] = w(la * scale)
        joints[.rightAnkle] = w(ra * scale)
        joints[.chest] = w(chestD2 * scale)
        joints[.neck] = w(neckD2 * scale)
        joints[.head] = w(headD2 * scale)
        joints[.leftShoulder] = w(lsS * scale)
        joints[.rightShoulder] = w(rsS * scale)
        joints[.leftElbow] = w(leS * scale)
        joints[.rightElbow] = w(reS * scale)
        joints[.leftWrist] = w(lwS * scale)
        joints[.rightWrist] = w(rwS * scale)
        joints[.spine] = w(lerp3(SIMD3(0, 0.2, 0.02), SIMD3(0, 0.22, 0.1), d) * scale)
        return joints
    }

    /// Reference push-up: avatar offset to the side, plank depth driven by elbow angle proxy.
    static func pushup(depth: Float, userFrame: PoseFrame) -> [JointName: SIMD3<Float>]? {
        guard let hipMid = hipMidpoint(userFrame),
              let basis = worldBasis(userFrame) else { return nil }

        let (right, up, forward) = basis
        let scale = armScale(userFrame)
        let d = simd_clamp(depth, 0, 1)

        let origin = hipMid + right * 0.75 + up * Float(0.05)

        let hipY: Float = 0.12
        let shoulderY: Float = 0.22
        let chestZ = lerpF(0.02, 0.18, d)

        let ls = SIMD3<Float>(-0.18, shoulderY, chestZ)
        let rs = SIMD3<Float>(0.18, shoulderY, chestZ)
        let le = lerp3(SIMD3<Float>(-0.2, 0.1, 0.06), SIMD3<Float>(-0.22, 0.02, 0.14), d)
        let re = lerp3(SIMD3<Float>(0.2, 0.1, 0.06), SIMD3<Float>(0.22, 0.02, 0.14), d)
        let lw = lerp3(SIMD3<Float>(-0.24, -0.02, 0.08), SIMD3<Float>(-0.26, -0.08, 0.16), d)
        let rw = lerp3(SIMD3<Float>(0.24, -0.02, 0.08), SIMD3<Float>(0.26, -0.08, 0.16), d)

        let hipZ = lerpF(0.04, 0.12, d)
        let hips = SIMD3<Float>(0, hipY, hipZ)

        func w(_ local: SIMD3<Float>) -> SIMD3<Float> {
            origin + (right * local.x + up * local.y + forward * local.z) * scale
        }

        var joints: [JointName: SIMD3<Float>] = [:]
        joints[.hips] = w(hips * scale)
        joints[.leftHip] = w(SIMD3(-0.06, hipY, hipZ) * scale)
        joints[.rightHip] = w(SIMD3(0.06, hipY, hipZ) * scale)
        joints[.chest] = w(SIMD3(0, 0.18, chestZ * 0.9) * scale)
        joints[.neck] = w(SIMD3(0, 0.26, chestZ * 0.95) * scale)
        joints[.head] = w(SIMD3(0, 0.34, chestZ) * scale)
        joints[.leftShoulder] = w(ls * scale)
        joints[.rightShoulder] = w(rs * scale)
        joints[.leftElbow] = w(le * scale)
        joints[.rightElbow] = w(re * scale)
        joints[.leftWrist] = w(lw * scale)
        joints[.rightWrist] = w(rw * scale)
        let ankleZ = hipZ + Float(0.02)
        joints[.leftKnee] = w(SIMD3(-0.05, 0.02, hipZ) * scale)
        joints[.rightKnee] = w(SIMD3(0.05, 0.02, hipZ) * scale)
        joints[.leftAnkle] = w(SIMD3(-0.06, 0.01, ankleZ) * scale)
        joints[.rightAnkle] = w(SIMD3(0.06, 0.01, ankleZ) * scale)
        joints[.spine] = w(SIMD3(0, 0.15, chestZ * 0.85) * scale)
        return joints
    }

    // MARK: - Full-screen demo (no user / camera; fixed stage in front of default view)

    /// Centered reference squat for looping form demo.
    static func squatDemonstration(depth: Float) -> [JointName: SIMD3<Float>]? {
        let right = SIMD3<Float>(1, 0, 0)
        let up = SIMD3<Float>(0, 1, 0)
        let forward = SIMD3<Float>(0, 0, -1)
        let origin = SIMD3<Float>(0, 1.02, -1.55)
        let scale: Float = 1.0
        let d = simd_clamp(depth, 0, 1)

        let lhStand = SIMD3<Float>(-0.11, 0, 0.02)
        let rhStand = SIMD3<Float>(0.11, 0, 0.02)
        let lkStand = SIMD3<Float>(-0.11, -0.42, 0.05)
        let rkStand = SIMD3<Float>(0.11, -0.42, 0.05)
        let laStand = SIMD3<Float>(-0.11, -0.82, 0.06)
        let raStand = SIMD3<Float>(0.11, -0.82, 0.06)
        let lkDeep = SIMD3<Float>(-0.2, -0.36, 0.22)
        let rkDeep = SIMD3<Float>(0.2, -0.36, 0.22)
        let laDeep = SIMD3<Float>(-0.16, -0.76, 0.32)
        let raDeep = SIMD3<Float>(0.16, -0.76, 0.32)

        let lk = lerp3(lkStand, lkDeep, d)
        let rk = lerp3(rkStand, rkDeep, d)
        let la = lerp3(laStand, laDeep, d)
        let ra = lerp3(raStand, raDeep, d)

        let chestD2 = lerp3(SIMD3(0, 0.36, 0.03), SIMD3(0, 0.38, 0.14), d)
        let neckD2 = lerp3(SIMD3(0, 0.44, 0.04), SIMD3(0, 0.45, 0.16), d)
        let headD2 = lerp3(SIMD3(0, 0.52, 0.05), SIMD3(0, 0.53, 0.18), d)

        let lsS = SIMD3<Float>(-0.2, 0.28, 0.02)
        let rsS = SIMD3<Float>(0.2, 0.28, 0.02)
        let leS = SIMD3<Float>(-0.26, 0.12, 0.04)
        let reS = SIMD3<Float>(0.26, 0.12, 0.04)
        let lwS = SIMD3<Float>(-0.3, -0.02, 0.05)
        let rwS = SIMD3<Float>(0.3, -0.02, 0.05)

        func w(_ local: SIMD3<Float>) -> SIMD3<Float> {
            origin + (right * local.x + up * local.y + forward * local.z) * scale
        }

        var joints: [JointName: SIMD3<Float>] = [:]
        joints[.hips] = w(SIMD3(0, 0, 0))
        joints[.leftHip] = w(lhStand * scale)
        joints[.rightHip] = w(rhStand * scale)
        joints[.leftKnee] = w(lk * scale)
        joints[.rightKnee] = w(rk * scale)
        joints[.leftAnkle] = w(la * scale)
        joints[.rightAnkle] = w(ra * scale)
        joints[.chest] = w(chestD2 * scale)
        joints[.neck] = w(neckD2 * scale)
        joints[.head] = w(headD2 * scale)
        joints[.leftShoulder] = w(lsS * scale)
        joints[.rightShoulder] = w(rsS * scale)
        joints[.leftElbow] = w(leS * scale)
        joints[.rightElbow] = w(reS * scale)
        joints[.leftWrist] = w(lwS * scale)
        joints[.rightWrist] = w(rwS * scale)
        joints[.spine] = w(lerp3(SIMD3(0, 0.2, 0.02), SIMD3(0, 0.22, 0.1), d) * scale)
        return joints
    }

    /// Centered reference push-up for looping form demo.
    static func pushupDemonstration(depth: Float) -> [JointName: SIMD3<Float>]? {
        let right = SIMD3<Float>(1, 0, 0)
        let up = SIMD3<Float>(0, 1, 0)
        let forward = SIMD3<Float>(0, 0, -1)
        let origin = SIMD3<Float>(0, 0.88, -1.45)
        let scale: Float = 1.0
        let d = simd_clamp(depth, 0, 1)

        let hipY: Float = 0.12
        let shoulderY: Float = 0.22
        let chestZ = lerpF(0.02, 0.18, d)
        let ls = SIMD3<Float>(-0.18, shoulderY, chestZ)
        let rs = SIMD3<Float>(0.18, shoulderY, chestZ)
        let le = lerp3(SIMD3<Float>(-0.2, 0.1, 0.06), SIMD3<Float>(-0.22, 0.02, 0.14), d)
        let re = lerp3(SIMD3<Float>(0.2, 0.1, 0.06), SIMD3<Float>(0.22, 0.02, 0.14), d)
        let lw = lerp3(SIMD3<Float>(-0.24, -0.02, 0.08), SIMD3<Float>(-0.26, -0.08, 0.16), d)
        let rw = lerp3(SIMD3<Float>(0.24, -0.02, 0.08), SIMD3<Float>(0.26, -0.08, 0.16), d)
        let hipZ = lerpF(0.04, 0.12, d)
        let hips = SIMD3<Float>(0, hipY, hipZ)

        func w(_ local: SIMD3<Float>) -> SIMD3<Float> {
            origin + (right * local.x + up * local.y + forward * local.z) * scale
        }

        var joints: [JointName: SIMD3<Float>] = [:]
        joints[.hips] = w(hips * scale)
        joints[.leftHip] = w(SIMD3(-0.06, hipY, hipZ) * scale)
        joints[.rightHip] = w(SIMD3(0.06, hipY, hipZ) * scale)
        joints[.chest] = w(SIMD3(0, 0.18, chestZ * 0.9) * scale)
        joints[.neck] = w(SIMD3(0, 0.26, chestZ * 0.95) * scale)
        joints[.head] = w(SIMD3(0, 0.34, chestZ) * scale)
        joints[.leftShoulder] = w(ls * scale)
        joints[.rightShoulder] = w(rs * scale)
        joints[.leftElbow] = w(le * scale)
        joints[.rightElbow] = w(re * scale)
        joints[.leftWrist] = w(lw * scale)
        joints[.rightWrist] = w(rw * scale)
        let ankleZ = hipZ + Float(0.02)
        joints[.leftKnee] = w(SIMD3(-0.05, 0.02, hipZ) * scale)
        joints[.rightKnee] = w(SIMD3(0.05, 0.02, hipZ) * scale)
        joints[.leftAnkle] = w(SIMD3(-0.06, 0.01, ankleZ) * scale)
        joints[.rightAnkle] = w(SIMD3(0.06, 0.01, ankleZ) * scale)
        joints[.spine] = w(SIMD3(0, 0.15, chestZ * 0.85) * scale)
        return joints
    }

    // MARK: - Helpers

    private static func hipMidpoint(_ frame: PoseFrame) -> SIMD3<Float>? {
        guard let lh = frame.joints[.leftHip], let rh = frame.joints[.rightHip] else { return nil }
        return (lh + rh) * 0.5
    }

    /// Right, up, forward (horizontal forward) from torso.
    private static func worldBasis(_ frame: PoseFrame) -> (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)? {
        guard let hip = frame.joints[.hips] ?? hipMidpoint(frame),
              let chest = frame.joints[.chest] else { return nil }

        let worldUp = SIMD3<Float>(0, 1, 0)
        var fwd = SIMD3(chest.x - hip.x, 0, chest.z - hip.z)
        if simd_length(fwd) < 0.05 {
            fwd = SIMD3(0, 0, -1)
        } else {
            fwd = simd_normalize(fwd)
        }
        let right = simd_normalize(simd_cross(fwd, worldUp))
        return (right, worldUp, fwd)
    }

    private static func legScale(_ frame: PoseFrame) -> Float {
        guard let lh = frame.joints[.leftHip],
              let lk = frame.joints[.leftKnee],
              let la = frame.joints[.leftAnkle] else {
            return 1
        }
        let thigh = simd_length(lk - lh)
        let shin = simd_length(la - lk)
        let total = thigh + shin
        return total > 0.2 ? total / 0.82 : 1
    }

    private static func armScale(_ frame: PoseFrame) -> Float {
        guard let ls = frame.joints[.leftShoulder],
              let le = frame.joints[.leftElbow],
              let lw = frame.joints[.leftWrist] else {
            return 1
        }
        let upper = simd_length(le - ls)
        let fore = simd_length(lw - le)
        let total = upper + fore
        return total > 0.15 ? total / 0.55 : 1
    }

    private static func lerp3(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ t: Float) -> SIMD3<Float> {
        a + (b - a) * t
    }

    private static func lerpF(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }
}
