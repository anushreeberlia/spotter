import Foundation
import SwiftData

@Model
final class UserProfile {
    var goals: [String]
    var experience: ExperienceLevel
    var equipment: [String]
    var injuries: [String]
    var daysPerWeek: Int
    var heightCm: Double
    var weightKg: Double
    var age: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        goals: [String] = [],
        experience: ExperienceLevel = .beginner,
        equipment: [String] = [],
        injuries: [String] = [],
        daysPerWeek: Int = 3,
        heightCm: Double = 170,
        weightKg: Double = 70,
        age: Int = 25
    ) {
        self.goals = goals
        self.experience = experience
        self.equipment = equipment
        self.injuries = injuries
        self.daysPerWeek = daysPerWeek
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.age = age
        self.createdAt = .now
        self.updatedAt = .now
    }
}

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .beginner: "Less than 6 months of consistent training"
        case .intermediate: "6 months to 2 years of consistent training"
        case .advanced: "2+ years of consistent training"
        }
    }
}
