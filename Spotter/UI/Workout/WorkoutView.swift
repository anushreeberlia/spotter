import SwiftUI

/// Main AR workout screen — shows camera feed with skeleton overlay and live stats.
struct WorkoutView: View {
    @State private var sessionManager = ARSessionManager()
    @State private var repCounter = RepCounter()
    @State private var formChecker = FormChecker()
    @State private var isActive = false

    let exercise: any ExerciseConfig

    var body: some View {
        ZStack {
            // AR camera feed with skeleton
            ARViewContainer(sessionManager: sessionManager)
                .ignoresSafeArea()

            // Top overlay: exercise name + tracking status
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.displayName)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(sessionManager.trackingMessage)
                            .font(.caption)
                            .foregroundStyle(sessionManager.isTracking ? .green : .yellow)
                    }
                    Spacer()
                    Button("End") {
                        sessionManager.pauseSession()
                        isActive = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
                .background(.ultraThinMaterial)

                Spacer()

                // Bottom overlay: rep count + phase + angles + corrections
                VStack(spacing: 12) {
                    // Form corrections
                    ForEach(formChecker.activeCorrections) { correction in
                        HStack {
                            Image(systemName: correction.severity == .error ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                .foregroundStyle(correction.severity == .error ? .red : .yellow)
                            Text(correction.message)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            (correction.severity == .error ? Color.red : Color.yellow)
                                .opacity(0.3)
                        )
                        .clipShape(Capsule())
                    }

                    // Stats bar
                    HStack(spacing: 24) {
                        StatBadge(label: "Reps", value: "\(repCounter.repCount)")
                        StatBadge(label: "Phase", value: repCounter.phase.displayName)
                        StatBadge(label: "Angle", value: "\(Int(repCounter.currentAngle))°")
                        StatBadge(
                            label: "Form",
                            value: "\(Int(formChecker.frameFormScore * 100))%"
                        )
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
        }
        .onAppear {
            repCounter.configure(
                topThreshold: exercise.topThreshold,
                bottomThreshold: exercise.bottomThreshold
            )
            formChecker.configure(rules: exercise.formRules)
            isActive = true
        }
        .onDisappear {
            sessionManager.pauseSession()
        }
        .onChange(of: sessionManager.currentFrame?.timestamp) {
            guard let frame = sessionManager.currentFrame else { return }
            let angle = exercise.primaryAngle(frame)
            repCounter.update(angle: angle)
            formChecker.evaluate(frame: frame, phase: repCounter.phase)
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
