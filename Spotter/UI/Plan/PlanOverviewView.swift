import SwiftUI
import SwiftData

struct PlanOverviewView: View {
    @Query private var plans: [WorkoutPlan]

    private var activePlan: WorkoutPlan? {
        plans.first { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let plan = activePlan {
                    List {
                        Section {
                            LabeledContent("Program", value: plan.name)
                            LabeledContent("Week", value: "\(plan.currentWeek) of \(plan.weeks)")
                        }

                        Section("Training Days") {
                            ForEach(Array(plan.days.sorted(by: { $0.dayIndex < $1.dayIndex })), id: \.dayIndex) { day in
                                NavigationLink {
                                    DayDetailView(day: day)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(day.dayName)
                                            .font(.headline)
                                        Text("\(day.exercises.count) exercises")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Active Plan",
                        systemImage: "calendar.badge.plus",
                        description: Text("Complete onboarding to generate your first training plan.")
                    )
                }
            }
            .navigationTitle("Plan")
        }
    }
}

struct DayDetailView: View {
    let day: WorkoutDay

    private var sortedExercises: [PlannedExercise] {
        day.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        List {
            ForEach(Array(sortedExercises), id: \.exerciseId) { exercise in
                exerciseRow(exercise)
            }
        }
        .navigationTitle(day.dayName)
    }

    @ViewBuilder
    private func exerciseRow(_ exercise: PlannedExercise) -> some View {
        if let config = ExerciseLibrary.shared.exercise(for: exercise.exerciseId) {
            HStack {
                Image(systemName: config.category.iconName)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)
                VStack(alignment: .leading) {
                    Text(config.displayName)
                        .font(.headline)
                    Text("\(exercise.sets) sets × \(exercise.repsTarget) reps • \(exercise.restSeconds)s rest")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
