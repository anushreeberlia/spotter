import SwiftUI

struct ExerciseStartView: View {
    let exercise: any ExerciseConfig
    var onStart: () -> Void = {}

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: exercise.category.iconName)
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text(exercise.displayName)
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 12) {
                Label("Prop your phone up at waist height", systemImage: "iphone.gen3")
                Label("Step back so your full body is visible", systemImage: "person.fill")
                Label("Make sure the room is well lit", systemImage: "lightbulb.fill")
            }
            .font(.body)
            .foregroundStyle(.secondary)

            Spacer()

            Button(action: onStart) {
                Text("Start Tracking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
