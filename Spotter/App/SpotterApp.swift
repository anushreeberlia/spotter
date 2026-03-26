import SwiftUI
import SwiftData

@main
struct SpotterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            UserProfile.self,
            WorkoutPlan.self,
            WorkoutDay.self,
            PlannedExercise.self,
            WorkoutLog.self,
            ExerciseLog.self,
            SetLog.self,
            RepLog.self,
        ])
    }
}
