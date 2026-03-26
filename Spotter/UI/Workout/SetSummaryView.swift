import SwiftUI

struct SetSummaryView: View {
    let exerciseName: String
    let setNumber: Int
    let repsCompleted: Int
    let formScore: Double
    let corrections: [String]
    var onContinue: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            Text("Set \(setNumber) Complete")
                .font(.title.bold())

            HStack(spacing: 32) {
                VStack {
                    Text("\(repsCompleted)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("Reps")
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(Int(formScore * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(formScore >= 0.85 ? .green : formScore >= 0.6 ? .yellow : .red)
                    Text("Form Score")
                        .foregroundStyle(.secondary)
                }
            }

            if !corrections.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus on:")
                        .font(.headline)
                    ForEach(corrections, id: \.self) { correction in
                        Label(correction, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button("Next Set", action: onContinue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }
}
