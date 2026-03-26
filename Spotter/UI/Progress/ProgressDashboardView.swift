import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]

    var body: some View {
        NavigationStack {
            Group {
                if logs.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Complete your first workout to see progress here.")
                    )
                } else {
                    List {
                        Section("Recent Workouts") {
                            ForEach(logs.prefix(10), id: \.date) { log in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(log.dayName)
                                            .font(.headline)
                                        Text(log.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("\(Int(log.overallFormScore * 100))%")
                                            .font(.headline)
                                            .foregroundStyle(
                                                log.overallFormScore >= 0.85 ? .green :
                                                log.overallFormScore >= 0.6 ? .yellow : .red
                                            )
                                        Text("\(Int(log.totalVolume)) kg")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }
}
