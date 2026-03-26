import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                if let profile = profile {
                    Section("About You") {
                        LabeledContent("Experience", value: profile.experience.displayName)
                        LabeledContent("Days/Week", value: "\(profile.daysPerWeek)")
                        LabeledContent("Height", value: "\(Int(profile.heightCm)) cm")
                        LabeledContent("Weight", value: "\(Int(profile.weightKg)) kg")
                        LabeledContent("Age", value: "\(profile.age)")
                    }

                    if !profile.goals.isEmpty {
                        Section("Goals") {
                            ForEach(profile.goals, id: \.self) { goal in
                                Text(goal.replacingOccurrences(of: "_", with: " ").capitalized)
                            }
                        }
                    }

                    if !profile.injuries.isEmpty {
                        Section("Injuries / Limitations") {
                            ForEach(profile.injuries, id: \.self) { injury in
                                Text(injury.replacingOccurrences(of: "_", with: " ").capitalized)
                            }
                        }
                    }
                }

                Section {
                    Button("Redo Onboarding", role: .destructive) {
                        hasCompletedOnboarding = false
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
