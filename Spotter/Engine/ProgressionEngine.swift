import Foundation

struct ProgressionSuggestion {
    let exerciseId: String
    let currentWeightKg: Double
    let suggestedWeightKg: Double
    let suggestedReps: Int
    let reason: String
    let isDeload: Bool
}

struct ProgressionEngine {

    static let weightIncrementKg: Double = 2.5
    static let deloadReductionPercent: Double = 0.4
    static let formThreshold: Double = 0.85

    /// Determine the next session's weight/reps based on history.
    static func suggest(
        exerciseId: String,
        lastSets: [SetLog],
        targetSets: Int,
        targetReps: Int,
        currentWeek: Int
    ) -> ProgressionSuggestion {
        let currentWeight = lastSets.first?.weightKg ?? 0

        // Deload every 4th week
        if currentWeek > 0 && currentWeek % 4 == 0 {
            return ProgressionSuggestion(
                exerciseId: exerciseId,
                currentWeightKg: currentWeight,
                suggestedWeightKg: max(0, currentWeight * (1 - deloadReductionPercent)),
                suggestedReps: targetReps,
                reason: "Deload week — reduce volume to recover",
                isDeload: true
            )
        }

        guard !lastSets.isEmpty else {
            return ProgressionSuggestion(
                exerciseId: exerciseId,
                currentWeightKg: currentWeight,
                suggestedWeightKg: currentWeight,
                suggestedReps: targetReps,
                reason: "No previous data — start here",
                isDeload: false
            )
        }

        let allSetsCompleted = lastSets.count >= targetSets
            && lastSets.allSatisfy { $0.repsCompleted >= targetReps }
        let averageFormScore = lastSets.map(\.formScore).reduce(0, +) / Double(lastSets.count)
        let goodForm = averageFormScore >= formThreshold

        if allSetsCompleted && goodForm {
            return ProgressionSuggestion(
                exerciseId: exerciseId,
                currentWeightKg: currentWeight,
                suggestedWeightKg: currentWeight + weightIncrementKg,
                suggestedReps: targetReps,
                reason: "All sets completed with good form — increase weight",
                isDeload: false
            )
        }

        if allSetsCompleted && !goodForm {
            return ProgressionSuggestion(
                exerciseId: exerciseId,
                currentWeightKg: currentWeight,
                suggestedWeightKg: currentWeight,
                suggestedReps: targetReps,
                reason: "Sets completed but form needs work — keep same weight",
                isDeload: false
            )
        }

        let totalRepsCompleted = lastSets.reduce(0) { $0 + $1.repsCompleted }
        let totalRepsTarget = targetSets * targetReps
        let completionRatio = Double(totalRepsCompleted) / Double(totalRepsTarget)

        if completionRatio < 0.7 {
            let reducedReps = max(targetReps - 2, 3)
            return ProgressionSuggestion(
                exerciseId: exerciseId,
                currentWeightKg: currentWeight,
                suggestedWeightKg: currentWeight,
                suggestedReps: reducedReps,
                reason: "Couldn't complete sets — reduce reps and try again",
                isDeload: false
            )
        }

        return ProgressionSuggestion(
            exerciseId: exerciseId,
            currentWeightKg: currentWeight,
            suggestedWeightKg: currentWeight,
            suggestedReps: targetReps,
            reason: "Keep pushing at this weight",
            isDeload: false
        )
    }
}
