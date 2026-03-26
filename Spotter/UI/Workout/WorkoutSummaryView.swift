import SwiftUI

struct WorkoutSummaryView: View {
    let dayName: String
    let duration: TimeInterval
    let exerciseCount: Int
    let totalVolume: Double
    let averageFormScore: Double
    var onDone: () -> Void = {}

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Workout Complete!")
                .font(.title.bold())

            Text(dayName)
                .font(.title3)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                SummaryCard(title: "Duration", value: formatDuration(duration), icon: "clock")
                SummaryCard(title: "Exercises", value: "\(exerciseCount)", icon: "dumbbell")
                SummaryCard(title: "Volume", value: "\(Int(totalVolume)) kg", icon: "scalemass")
                SummaryCard(
                    title: "Form",
                    value: "\(Int(averageFormScore * 100))%",
                    icon: "checkmark.shield"
                )
            }

            Spacer()

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
