import Foundation

/// Overtime policy applied per calendar week (Monday–Sunday).
public struct OvertimePolicy: Equatable, Sendable {
    /// Hours per week paid at the regular rate before overtime kicks in.
    public var regularHoursPerWeek: Double
    public var overtimeMultiplier: Double

    public init(regularHoursPerWeek: Double = 40, overtimeMultiplier: Double = 1.5) {
        self.regularHoursPerWeek = regularHoursPerWeek
        self.overtimeMultiplier = overtimeMultiplier
    }

    public static let standard = OvertimePolicy()
}

/// Estimated earnings for a pay period, split into regular and overtime pay.
public struct PayBreakdown: Equatable, Sendable {
    public var regularHours: Double
    public var overtimeHours: Double
    public var regularPay: Double
    public var overtimePay: Double
    public var shiftCount: Int

    public var totalHours: Double { regularHours + overtimeHours }
    public var totalPay: Double { regularPay + overtimePay }
    public var effectiveHourlyRate: Double {
        guard totalHours > 0 else { return 0 }
        return totalPay / totalHours
    }
}

/// Common pay-period intervals.
public enum PayPeriod {
    /// The Monday–Sunday week containing `date`.
    public static func week(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        return cal.dateInterval(of: .weekOfYear, for: date)
            ?? DateInterval(start: date, duration: 7 * 86_400)
    }

    /// The calendar month containing `date`.
    public static func month(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: date, duration: 30 * 86_400)
    }
}

public enum PayEstimator {
    /// Estimates pay for every shift that starts inside `interval`.
    ///
    /// Shifts are bucketed into Monday-start weeks (a shift belongs to the week
    /// its start falls in, so overnight shifts count once). Within each week the
    /// first `regularHoursPerWeek` hours — taken chronologically — are paid at
    /// each shift's own hourly rate, and the remainder at
    /// `overtimeMultiplier`. This handles mixed pay rates correctly: overtime
    /// pay is computed from the rate of the actual overtime hours.
    public static func breakdown(
        for shifts: [Shift],
        in interval: DateInterval,
        policy: OvertimePolicy = .standard,
        calendar: Calendar = .current
    ) -> PayBreakdown {
        let relevant = shifts
            .filter { interval.contains($0.start) }
            .sorted { $0.start < $1.start }

        var regularHours = 0.0
        var overtimeHours = 0.0
        var regularPay = 0.0
        var overtimePay = 0.0

        for weekShifts in groupByWeek(relevant, calendar: calendar) {
            var hoursSoFar = 0.0
            for shift in weekShifts {
                let hours = shift.durationHours
                let regularPortion = min(max(policy.regularHoursPerWeek - hoursSoFar, 0), hours)
                let overtimePortion = hours - regularPortion
                regularHours += regularPortion
                overtimeHours += overtimePortion
                regularPay += regularPortion * shift.hourlyRate
                overtimePay += overtimePortion * shift.hourlyRate * policy.overtimeMultiplier
                hoursSoFar += hours
            }
        }

        return PayBreakdown(
            regularHours: regularHours,
            overtimeHours: overtimeHours,
            regularPay: regularPay,
            overtimePay: overtimePay,
            shiftCount: relevant.count
        )
    }

    /// Splits an interval into Monday-start week intervals (useful for UI grouping).
    public static func weeks(in interval: DateInterval, calendar: Calendar = .current) -> [DateInterval] {
        var cal = calendar
        cal.firstWeekday = 2
        var weeks: [DateInterval] = []
        var cursor = cal.date(
            from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: interval.start)
        ) ?? interval.start
        while cursor < interval.end {
            guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: cursor) else { break }
            weeks.append(weekInterval)
            cursor = weekInterval.end
        }
        return weeks
    }

    // MARK: - Private

    private static func groupByWeek(_ shifts: [Shift], calendar: Calendar) -> [[Shift]] {
        var cal = calendar
        cal.firstWeekday = 2
        var buckets: [Date: [Shift]] = [:]
        var order: [Date] = []
        for shift in shifts {
            let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.start)
            let key = cal.date(from: components) ?? shift.start
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = []
            }
            buckets[key]?.append(shift)
        }
        return order.sorted().compactMap { buckets[$0] }
    }
}
