import SwiftUI

private enum WorkoutMode: String, CaseIterable {
    case formDemo = "Form demo"
    case track = "Track me"
}

/// Workout screen: optional full-screen form loop (no camera), or live AR tracking on you.
struct WorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sessionManager = ARSessionManager()
    @State private var repCounter = RepCounter()
    @State private var formChecker = FormChecker()
    @State private var mode: WorkoutMode = .formDemo

    let exercise: any ExerciseConfig

    var body: some View {
        ZStack {
            if mode == .formDemo, exercise.supportsFormDemo {
                ExerciseFormAnimationView(exercise: exercise)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else {
                ARViewContainer(sessionManager: sessionManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.displayName)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        if mode == .track {
                            Text(sessionManager.trackingMessage)
                                .font(.caption)
                                .foregroundStyle(sessionManager.isTracking ? .green : .yellow)
                        } else if exercise.supportsFormDemo {
                            Text("Looping target movement — no camera")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("End") {
                        sessionManager.pauseSession()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
                .background(.ultraThinMaterial)

                Picker("Mode", selection: $mode) {
                    if exercise.supportsFormDemo {
                        Text(WorkoutMode.formDemo.rawValue).tag(WorkoutMode.formDemo)
                    }
                    Text(WorkoutMode.track.rawValue).tag(WorkoutMode.track)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .background(.ultraThinMaterial)

                if !exercise.supportsFormDemo {
                    Text("Form demo isn’t set up for this exercise yet — use Track me.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }

                Spacer()

                if mode == .track {
                    VStack(spacing: 12) {
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
        }
        .onAppear {
            if !exercise.supportsFormDemo {
                mode = .track
            }
            repCounter.configure(
                topThreshold: exercise.topThreshold,
                bottomThreshold: exercise.bottomThreshold
            )
            formChecker.configure(rules: exercise.formRules)
        }
        .onChange(of: mode) { _, newMode in
            if newMode == .formDemo {
                sessionManager.pauseSession()
            }
        }
        .onDisappear {
            sessionManager.pauseSession()
        }
        .onChange(of: sessionManager.currentFrame?.timestamp) {
            guard mode == .track, let frame = sessionManager.currentFrame else { return }
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
