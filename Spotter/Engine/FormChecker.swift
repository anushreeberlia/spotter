import Foundation
import simd

/// A form correction returned by the checker.
struct FormCorrection: Identifiable {
    let id = UUID()
    let joint: JointName
    let severity: Severity
    let message: String
    let ruleId: String

    enum Severity: Comparable {
        case info
        case warning
        case error
    }
}

/// Protocol for exercise-specific form rules.
protocol FormRule {
    var ruleId: String { get }
    func check(frame: PoseFrame, phase: RepPhase) -> FormCorrection?
}

/// Runs all applicable form rules for the current exercise.
@Observable
class FormChecker {
    private(set) var activeCorrections: [FormCorrection] = []
    private(set) var frameFormScore: Double = 1.0

    private var rules: [FormRule] = []
    private var correctionCooldowns: [String: Date] = [:]
    private let cooldownInterval: TimeInterval = 2.0

    func configure(rules: [FormRule]) {
        self.rules = rules
        activeCorrections = []
        correctionCooldowns = [:]
    }

    /// Check the current frame against all rules. Returns new corrections found.
    @discardableResult
    func evaluate(frame: PoseFrame, phase: RepPhase) -> [FormCorrection] {
        let now = Date()
        var newCorrections: [FormCorrection] = []

        for rule in rules {
            if let correction = rule.check(frame: frame, phase: phase) {
                let lastFired = correctionCooldowns[rule.ruleId]
                if lastFired == nil || now.timeIntervalSince(lastFired!) >= cooldownInterval {
                    newCorrections.append(correction)
                    correctionCooldowns[rule.ruleId] = now
                }
            }
        }

        activeCorrections = newCorrections

        if rules.isEmpty {
            frameFormScore = 1.0
        } else {
            let errorCount = newCorrections.filter { $0.severity == .error }.count
            let warningCount = newCorrections.filter { $0.severity == .warning }.count
            let penalty = Double(errorCount) * 0.3 + Double(warningCount) * 0.1
            frameFormScore = max(0, 1.0 - penalty)
        }

        return newCorrections
    }

    func reset() {
        activeCorrections = []
        correctionCooldowns = [:]
        frameFormScore = 1.0
    }
}
