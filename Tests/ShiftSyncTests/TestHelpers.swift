import XCTest
@testable import ShiftSync

/// Fixed Toronto calendar so date tests don't depend on the machine timezone.
var testCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Toronto")!
    return calendar
}

/// Shared date helper: deterministic dates in America/Toronto.
func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    testCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

func makeShift(
    start: Date,
    end: Date,
    role: String = "Cashier",
    hourlyRate: Double = 20.0
) -> Shift {
    Shift(start: start, end: end, role: role, hourlyRate: hourlyRate)
}
