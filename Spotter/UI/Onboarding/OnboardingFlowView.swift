import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var goals: Set<String> = []
    @State private var experience: ExperienceLevel = .beginner
    @State private var equipment: Set<String> = []
    @State private var daysPerWeek = 3

    var onComplete: () -> Void

    var body: some View {
        NavigationStack {
            TabView(selection: $step) {
                // Step 0: Goals
                OnboardingPage(
                    title: "What are your goals?",
                    subtitle: "Select all that apply"
                ) {
                    ForEach(["Build Muscle", "Get Stronger", "Lose Fat", "Improve Form", "Stay Active"], id: \.self) { goal in
                        let key = goal.lowercased().replacingOccurrences(of: " ", with: "_")
                        Toggle(goal, isOn: Binding(
                            get: { goals.contains(key) },
                            set: { if $0 { goals.insert(key) } else { goals.remove(key) } }
                        ))
                    }
                }
                .tag(0)

                // Step 1: Experience
                OnboardingPage(
                    title: "Training experience?",
                    subtitle: "This helps us pick the right program"
                ) {
                    Picker("Experience", selection: $experience) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.displayName)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                .tag(1)

                // Step 2: Equipment
                OnboardingPage(
                    title: "What equipment do you have?",
                    subtitle: "Select all that apply"
                ) {
                    ForEach(["Full Gym", "Dumbbells Only", "Barbell + Rack", "Bodyweight Only", "Resistance Bands"], id: \.self) { item in
                        let key = item.lowercased().replacingOccurrences(of: " ", with: "_")
                        Toggle(item, isOn: Binding(
                            get: { equipment.contains(key) },
                            set: { if $0 { equipment.insert(key) } else { equipment.remove(key) } }
                        ))
                    }
                }
                .tag(2)

                // Step 3: Schedule
                OnboardingPage(
                    title: "How many days per week?",
                    subtitle: "We'll build your split around this"
                ) {
                    Picker("Days", selection: $daysPerWeek) {
                        ForEach(2...6, id: \.self) { day in
                            Text("\(day) days").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if step < 3 {
                        Button("Next") { withAnimation { step += 1 } }
                    } else {
                        Button("Done") { saveAndComplete() }
                            .bold()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if step > 0 {
                        Button("Back") { withAnimation { step -= 1 } }
                    }
                }
            }
        }
    }

    private func saveAndComplete() {
        let profile = UserProfile(
            goals: Array(goals),
            experience: experience,
            equipment: Array(equipment),
            daysPerWeek: daysPerWeek
        )
        modelContext.insert(profile)
        onComplete()
    }
}

struct OnboardingPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Form {
                content()
            }
        }
        .padding(.top, 32)
    }
}
