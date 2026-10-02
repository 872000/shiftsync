import Foundation

/// Human-friendly countdown to the next shift.
public struct ShiftCountdown: Equatable, Sendable {
    public let totalSeconds: Int

    public init(totalSeconds: Int) {
        self.totalSeconds = max(0, totalSeconds)
    }

    public var days: Int { totalSeconds / 86_400 }
    public var hours: Int { (totalSeconds % 86_400) / 3_600 }
    public var minutes: Int { (totalSeconds % 3_600) / 60 }
    public var seconds: Int { totalSeconds % 60 }

    /// True when the shift starts within the next hour — time to head out.
    public var isImminent: Bool { totalSeconds <= 3_600 }

    public var displayString: String {
        if days > 0 { return "\(days)d \(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h \(minutes)m \(seconds)s" }
        return "\(minutes)m \(seconds)s"
    }
}

public enum NextShiftResolver {
    /// The shift in progress at `now`, if any.
    public static func currentShift(at now: Date, in shifts: [Shift]) -> Shift? {
        shifts
            .filter { $0.start <= now && now < $0.end }
            .min(by: { $0.start < $1.start })
    }

    /// The next shift that has not started yet.
    public static func nextShift(after now: Date, in shifts: [Shift]) -> Shift? {
        shifts
            .filter { $0.start > now }
            .min(by: { $0.start < $1.start })
    }

    public static func countdown(to shift: Shift, from now: Date) -> ShiftCountdown {
        ShiftCountdown(totalSeconds: Int(shift.start.timeIntervalSince(now)))
    }
}
