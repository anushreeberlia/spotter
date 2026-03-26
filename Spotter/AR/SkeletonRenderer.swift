import Foundation
import RealityKit
import simd

class SkeletonRenderer {

    private var arView: ARView?
    private let rootAnchor = AnchorEntity()
    private var jointEntities: [JointName: ModelEntity] = [:]
    private var boneEntities: [String: ModelEntity] = [:]

    /// Joint colors: green = good form, red = correction needed.
    private(set) var jointColors: [JointName: JointColor] = [:]

    private let jointRadius: Float = 0.025
    private let boneRadius: Float = 0.01

    /// Bones defined as pairs of joints to connect with lines.
    private static let bonePairs: [(JointName, JointName)] = [
        (.head, .neck),
        (.neck, .chest),
        (.chest, .hips),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .chest),
        (.rightShoulder, .chest),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
        (.leftHip, .rightHip),
        (.hips, .leftHip),
        (.hips, .rightHip),
    ]

    func attach(to arView: ARView) {
        self.arView = arView
        arView.scene.addAnchor(rootAnchor)
        createJointEntities()
        createBoneEntities()
    }

    func update(with frame: PoseFrame) {
        for joint in JointName.allCases {
            guard let position = frame.joints[joint],
                  let entity = jointEntities[joint] else { continue }

            entity.position = position
            entity.isEnabled = true

            let color = jointColors[joint] ?? .normal
            entity.model?.materials = [SimpleMaterial(color: color.uiColor, isMetallic: false)]
        }

        for (a, b) in Self.bonePairs {
            guard let posA = frame.joints[a],
                  let posB = frame.joints[b] else { continue }

            let key = "\(a.rawValue)-\(b.rawValue)"
            guard let boneEntity = boneEntities[key] else { continue }

            updateBone(entity: boneEntity, from: posA, to: posB)
            boneEntity.isEnabled = true
        }
    }

    func setJointColor(_ joint: JointName, color: JointColor) {
        jointColors[joint] = color
    }

    func resetColors() {
        jointColors.removeAll()
    }

    func hide() {
        jointEntities.values.forEach { $0.isEnabled = false }
        boneEntities.values.forEach { $0.isEnabled = false }
    }

    // MARK: - Private

    private func createJointEntities() {
        for joint in JointName.allCases {
            let mesh = MeshResource.generateSphere(radius: jointRadius)
            let material = SimpleMaterial(color: .cyan, isMetallic: false)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.isEnabled = false
            rootAnchor.addChild(entity)
            jointEntities[joint] = entity
        }
    }

    private func createBoneEntities() {
        for (a, b) in Self.bonePairs {
            let key = "\(a.rawValue)-\(b.rawValue)"
            let mesh = MeshResource.generateBox(size: [boneRadius * 2, boneRadius * 2, 0.01])
            let material = SimpleMaterial(color: .cyan.withAlphaComponent(0.6), isMetallic: false)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.isEnabled = false
            rootAnchor.addChild(entity)
            boneEntities[key] = entity
        }
    }

    private func updateBone(entity: ModelEntity, from a: SIMD3<Float>, to b: SIMD3<Float>) {
        let midpoint = (a + b) / 2
        let direction = b - a
        let length = simd_length(direction)

        entity.position = midpoint
        entity.scale = [1, 1, length / 0.01]

        if length > 0.001 {
            let normalizedDir = simd_normalize(direction)
            let up = SIMD3<Float>(0, 0, 1)
            let rotationAxis = simd_cross(up, normalizedDir)
            let rotationAngle = acos(simd_clamp(simd_dot(up, normalizedDir), -1, 1))

            if simd_length(rotationAxis) > 0.001 {
                entity.orientation = simd_quatf(angle: rotationAngle, axis: simd_normalize(rotationAxis))
            }
        }
    }
}

enum JointColor {
    case normal
    case good
    case warning
    case error

    var uiColor: UIColor {
        switch self {
        case .normal: .cyan
        case .good: .green
        case .warning: .yellow
        case .error: .red
        }
    }
}
