import SwiftUI
import SwiftData

/// Binds full-screen workout so the cover always has an exercise id (avoids an empty cover = black screen).
private struct WorkoutPresentation: Identifiable {
    let exerciseId: String
    var id: String { exerciseId }
}

struct TodayView: View {
    @Query private var plans: [WorkoutPlan]
    @State private var workoutPresentation: WorkoutPresentation?

    private var activePlan: WorkoutPlan? {
        plans.first { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let plan = activePlan, let today = plan.days.first {
                    List {
                        Section("Today — \(today.dayName)") {
                            ForEach(today.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.exerciseId) { planned in
                                if let config = ExerciseLibrary.shared.exercise(for: planned.exerciseId) {
                                    Button {
                                        workoutPresentation = WorkoutPresentation(exerciseId: planned.exerciseId)
                                    } label: {
                                        HStack {
                                            Image(systemName: config.category.iconName)
                                                .foregroundStyle(Color.accentColor)
                                                .frame(width: 32)
                                            VStack(alignment: .leading) {
                                                Text(config.displayName)
                                                    .font(.headline)
                                                Text("\(planned.sets) × \(planned.repsTarget) reps")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .tint(.primary)
                                }
                            }
                        }
                    }
                } else {
                    // No active plan — show quick start with all exercises
                    QuickStartView(onSelect: { exerciseId in
                        workoutPresentation = WorkoutPresentation(exerciseId: exerciseId)
                    })
                }
            }
            .navigationTitle("Today")
            .fullScreenCover(item: $workoutPresentation) { presentation in
                if let config = ExerciseLibrary.shared.exercise(for: presentation.exerciseId) {
                    WorkoutView(exercise: config)
                } else {
                    VStack(spacing: 16) {
                        Text("Couldn’t load that exercise.")
                            .font(.headline)
                        Button("Close") {
                            workoutPresentation = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
        }
    }
}

struct QuickStartView: View {
    let onSelect: (String) -> Void

    var body: some View {
        List {
            Section {
                Text("No plan active. Pick an exercise to start tracking.")
                    .foregroundStyle(.secondary)
            }

            ForEach(ExerciseLibrary.shared.byCategory, id: \.category) { group in
                Section(group.category.displayName) {
                    ForEach(group.exercises, id: \.id) { exercise in
                        Button {
                            onSelect(exercise.id)
                        } label: {
                            HStack {
                                Image(systemName: group.category.iconName)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 32)
                                VStack(alignment: .leading) {
                                    Text(exercise.displayName)
                                        .font(.headline)
                                    Text(exercise.isIsometric ? "Isometric hold" : "Rep-based")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .tint(.primary)
                    }
                }
            }
        }
    }
}
