import Foundation

/// Tracks rep phases using a primary angle signal (e.g. knee angle for squats).
@Observable
class RepCounter {
    private(set) var repCount: Int = 0
    private(set) var phase: RepPhase = .standing
    private(set) var currentAngle: Float = 180
    private(set) var bottomAngle: Float = 180
    private(set) var peakAngle: Float = 180

    private var topThreshold: Float
    private var bottomThreshold: Float
    private var smoothedAngle: Float = 180

    /// Exponential smoothing factor to reduce noise. 0 = no smoothing, 1 = full smoothing.
    private let smoothingFactor: Float = 0.3

    init(topThreshold: Float = 150, bottomThreshold: Float = 100) {
        self.topThreshold = topThreshold
        self.bottomThreshold = bottomThreshold
    }

    func configure(topThreshold: Float, bottomThreshold: Float) {
        self.topThreshold = topThreshold
        self.bottomThreshold = bottomThreshold
    }

    func reset() {
        repCount = 0
        phase = .standing
        currentAngle = 180
        bottomAngle = 180
        peakAngle = 180
        smoothedAngle = 180
    }

    /// Feed a new angle reading. Returns true if a rep was just completed.
    @discardableResult
    func update(angle: Float) -> Bool {
        smoothedAngle = smoothedAngle * smoothingFactor + angle * (1 - smoothingFactor)
        currentAngle = smoothedAngle

        switch phase {
        case .standing:
            peakAngle = smoothedAngle
            if smoothedAngle < topThreshold {
                phase = .descending
            }

        case .descending:
            bottomAngle = min(bottomAngle, smoothedAngle)
            if smoothedAngle <= bottomThreshold {
                phase = .bottom
            } else if smoothedAngle > topThreshold {
                // Went back up without reaching bottom — false start
                phase = .standing
                bottomAngle = 180
            }

        case .bottom:
            bottomAngle = min(bottomAngle, smoothedAngle)
            if smoothedAngle > bottomThreshold + 15 {
                phase = .ascending
            }

        case .ascending:
            if smoothedAngle >= topThreshold {
                repCount += 1
                phase = .standing
                peakAngle = smoothedAngle
                let completedBottom = bottomAngle
                bottomAngle = 180
                _ = completedBottom
                return true
            } else if smoothedAngle <= bottomThreshold {
                // Dropped back down
                phase = .bottom
            }
        }

        return false
    }
}

enum RepPhase: String {
    case standing
    case descending
    case bottom
    case ascending

    var displayName: String {
        switch self {
        case .standing: "Ready"
        case .descending: "Going down"
        case .bottom: "Bottom"
        case .ascending: "Coming up"
        }
    }

    var progress: Double {
        switch self {
        case .standing: 0.0
        case .descending: 0.33
        case .bottom: 0.5
        case .ascending: 0.75
        }
    }
}
