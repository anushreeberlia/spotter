import Foundation

/// Central registry of all exercises available in the app.
struct ExerciseLibrary {
    static let shared = ExerciseLibrary()

    let exercises: [any ExerciseConfig] = [
        SquatConfig(),
        DeadliftConfig(),
        OverheadPressConfig(),
        PushupConfig(),
        LungeConfig(),
        RowConfig(),
        PlankConfig(),
        CurlConfig(),
    ]

    func exercise(for id: String) -> (any ExerciseConfig)? {
        exercises.first { $0.id == id }
    }

    func exercises(in category: ExerciseCategory) -> [any ExerciseConfig] {
        exercises.filter { $0.category == category }
    }

    var allIds: [String] {
        exercises.map(\.id)
    }

    var byCategory: [(category: ExerciseCategory, exercises: [any ExerciseConfig])] {
        ExerciseCategory.allCases.compactMap { cat in
            let matching = exercises(in: cat)
            return matching.isEmpty ? nil : (cat, matching)
        }
    }
}
