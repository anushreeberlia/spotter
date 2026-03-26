import Foundation
import SwiftData

@Model
final class WorkoutLog {
    var date: Date
    var durationSeconds: Int
    var dayName: String
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseLog]
    var notes: String?

    var overallFormScore: Double {
        let scores = exercises.flatMap { $0.sets.map(\.formScore) }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + (set.weightKg * Double(set.repsCompleted))
            }
        }
    }

    init(dayName: String) {
        self.date = .now
        self.durationSeconds = 0
        self.dayName = dayName
        self.exercises = []
    }
}

@Model
final class ExerciseLog {
    var exerciseId: String
    @Relationship(deleteRule: .cascade) var sets: [SetLog]
    var notes: String?
    var workoutLog: WorkoutLog?

    init(exerciseId: String) {
        self.exerciseId = exerciseId
        self.sets = []
    }
}

@Model
final class SetLog {
    var setNumber: Int
    var weightKg: Double
    var repsCompleted: Int
    var formScore: Double
    var arTrackingUsed: Bool
    @Relationship(deleteRule: .cascade) var reps: [RepLog]
    var exerciseLog: ExerciseLog?
    var completedAt: Date

    var averageRepScore: RepScore {
        let scores = reps.map(\.score)
        guard !scores.isEmpty else { return .good }
        let goodCount = scores.filter { $0 == .good }.count
        let ratio = Double(goodCount) / Double(scores.count)
        if ratio >= 0.8 { return .good }
        if ratio >= 0.5 { return .okay }
        return .fixForm
    }

    init(
        setNumber: Int,
        weightKg: Double = 0,
        repsCompleted: Int = 0,
        formScore: Double = 1.0,
        arTrackingUsed: Bool = false
    ) {
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.repsCompleted = repsCompleted
        self.formScore = formScore
        self.arTrackingUsed = arTrackingUsed
        self.reps = []
        self.completedAt = .now
    }
}

@Model
final class RepLog {
    var repNumber: Int
    var score: RepScore
    var corrections: [String]
    var peakAngle: Double?
    var bottomAngle: Double?
    var setLog: SetLog?

    init(
        repNumber: Int,
        score: RepScore = .good,
        corrections: [String] = [],
        peakAngle: Double? = nil,
        bottomAngle: Double? = nil
    ) {
        self.repNumber = repNumber
        self.score = score
        self.corrections = corrections
        self.peakAngle = peakAngle
        self.bottomAngle = bottomAngle
    }
}

enum RepScore: String, Codable {
    case good
    case okay
    case fixForm

    var displayName: String {
        switch self {
        case .good: "Good"
        case .okay: "Okay"
        case .fixForm: "Fix Form"
        }
    }

    var color: String {
        switch self {
        case .good: "green"
        case .okay: "yellow"
        case .fixForm: "red"
        }
    }
}
