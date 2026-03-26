import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            TabView(selection: $selectedTab) {
                Tab("Today", systemImage: "flame.fill", value: 0) {
                    TodayView()
                }
                Tab("Plan", systemImage: "calendar", value: 1) {
                    PlanOverviewView()
                }
                Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: 2) {
                    ProgressDashboardView()
                }
                Tab("Profile", systemImage: "person.fill", value: 3) {
                    ProfileView()
                }
            }
            .tint(.accentColor)
        } else {
            OnboardingFlowView {
                hasCompletedOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
