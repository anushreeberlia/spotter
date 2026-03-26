import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    var name: String
    var weeks: Int
    var currentWeek: Int
    var isActive: Bool
    @Relationship(deleteRule: .cascade) var days: [WorkoutDay]
    var createdAt: Date

    init(
        name: String,
        weeks: Int = 4,
        days: [WorkoutDay] = []
    ) {
        self.name = name
        self.weeks = weeks
        self.currentWeek = 1
        self.isActive = true
        self.days = days
        self.createdAt = .now
    }
}

@Model
final class WorkoutDay {
    var dayName: String
    var dayIndex: Int
    @Relationship(deleteRule: .cascade) var exercises: [PlannedExercise]
    var plan: WorkoutPlan?

    init(dayName: String, dayIndex: Int, exercises: [PlannedExercise] = []) {
        self.dayName = dayName
        self.dayIndex = dayIndex
        self.exercises = exercises
    }
}

@Model
final class PlannedExercise {
    var exerciseId: String
    var sets: Int
    var repsTarget: Int
    var weightKg: Double?
    var restSeconds: Int
    var orderIndex: Int
    var day: WorkoutDay?

    init(
        exerciseId: String,
        sets: Int = 3,
        repsTarget: Int = 10,
        weightKg: Double? = nil,
        restSeconds: Int = 90,
        orderIndex: Int = 0
    ) {
        self.exerciseId = exerciseId
        self.sets = sets
        self.repsTarget = repsTarget
        self.weightKg = weightKg
        self.restSeconds = restSeconds
        self.orderIndex = orderIndex
    }
}
