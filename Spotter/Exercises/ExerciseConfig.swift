import Foundation
import simd

/// Defines the tracking configuration for an exercise.
protocol ExerciseConfig {
    var id: String { get }
    var displayName: String { get }
    var category: ExerciseCategory { get }

    /// The primary angle used for rep detection (e.g. knee angle for squats).
    var primaryAngle: (PoseFrame) -> Float { get }

    /// Angle threshold above which the user is considered "standing" (top of rep).
    var topThreshold: Float { get }

    /// Angle threshold below which the user has reached the bottom of the rep.
    var bottomThreshold: Float { get }

    /// Form rules specific to this exercise.
    var formRules: [FormRule] { get }

    /// Whether this is an isometric hold (e.g. plank) rather than reps.
    var isIsometric: Bool { get }

    /// Joints to highlight in the AR overlay for this exercise.
    var keyJoints: [JointName] { get }

    /// World-space joints for the green “form avatar” beside the user. `depth` is 0 = top of rep, 1 = bottom.
    func formAvatarJoints(depth: Float, userFrame: PoseFrame) -> [JointName: SIMD3<Float>]?

    /// Whether this exercise shows the green reference figure when data is available.
    var hasFormAvatar: Bool { get }
}

extension ExerciseConfig {
    var isIsometric: Bool { false }

    func formAvatarJoints(depth: Float, userFrame: PoseFrame) -> [JointName: SIMD3<Float>]? {
        nil
    }

    var hasFormAvatar: Bool { false }
}

enum ExerciseCategory: String, CaseIterable {
    case legs
    case push
    case pull
    case core

    var displayName: String {
        switch self {
        case .legs: "Legs"
        case .push: "Push"
        case .pull: "Pull"
        case .core: "Core"
        }
    }

    var iconName: String {
        switch self {
        case .legs: "figure.walk"
        case .push: "figure.strengthtraining.traditional"
        case .pull: "dumbbell.fill"
        case .core: "figure.core.training"
        }
    }
}
