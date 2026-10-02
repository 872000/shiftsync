import Foundation

/// A single work shift, modelled with full start/end timestamps so overnight
/// shifts (e.g. 10 PM – 6 AM) work without special-casing.
public struct Shift: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var start: Date
    public var end: Date
    public var role: String
    public var hourlyRate: Double
    public var notes: String

    public init(
        id: UUID = UUID(),
        start: Date,
        end: Date,
        role: String,
        hourlyRate: Double,
        notes: String = ""
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.role = role
        self.hourlyRate = hourlyRate
        self.notes = notes
    }

    /// Length of the shift in seconds.
    public var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    /// Length of the shift in fractional hours (e.g. 7.5).
    public var durationHours: Double {
        duration / 3_600
    }

    /// True when the shift ends on a later calendar day than it starts.
    /// The calendar is injectable so overnight detection stays testable
    /// regardless of the machine's timezone.
    public func isOvernight(using calendar: Calendar = .current) -> Bool {
        !calendar.isDate(start, inSameDayAs: end)
    }

    /// Gross pay for this shift at its own hourly rate, before overtime rules.
    public var grossPay: Double {
        durationHours * hourlyRate
    }
}
