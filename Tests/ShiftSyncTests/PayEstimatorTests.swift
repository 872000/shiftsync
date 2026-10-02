import XCTest
@testable import ShiftSync

final class PayEstimatorTests: XCTestCase {

    /// Week of Monday 2026-10-05 (Toronto).
    func weekInterval() -> DateInterval {
        PayPeriod.week(containing: makeDate(2026, 10, 7, 12), calendar: testCalendar)
    }

    func testRegularWeekNoOvertime() {
        // 5 x 8h = 40h at $20 -> $800, no overtime.
        var shifts: [Shift] = []
        for day in 5...9 {
            shifts.append(makeShift(
                start: makeDate(2026, 10, day, 9),
                end: makeDate(2026, 10, day, 17),
                hourlyRate: 20
            ))
        }
        let result = PayEstimator.breakdown(for: shifts, in: weekInterval(), calendar: testCalendar)
        XCTAssertEqual(result.regularHours, 40, accuracy: 0.001)
        XCTAssertEqual(result.overtimeHours, 0, accuracy: 0.001)
        XCTAssertEqual(result.totalPay, 800, accuracy: 0.001)
        XCTAssertEqual(result.shiftCount, 5)
    }

    func testOvertimeWeek() {
        // 5 x 10h = 50h at $20 -> 40 regular ($800) + 10 OT at 1.5x ($300) = $1100.
        var shifts: [Shift] = []
        for day in 5...9 {
            shifts.append(makeShift(
                start: makeDate(2026, 10, day, 8),
                end: makeDate(2026, 10, day, 18),
                hourlyRate: 20
            ))
        }
        let result = PayEstimator.breakdown(for: shifts, in: weekInterval(), calendar: testCalendar)
        XCTAssertEqual(result.regularHours, 40, accuracy: 0.001)
        XCTAssertEqual(result.overtimeHours, 10, accuracy: 0.001)
        XCTAssertEqual(result.regularPay, 800, accuracy: 0.001)
        XCTAssertEqual(result.overtimePay, 300, accuracy: 0.001)
        XCTAssertEqual(result.totalPay, 1_100, accuracy: 0.001)
        XCTAssertEqual(result.effectiveHourlyRate, 22, accuracy: 0.001)
    }

    func testMixedRatesOvertimeUsesCorrectRate() {
        // Mon–Thu: 8h @ $20 (32h). Friday: 12h @ $30 (12h).
        // Regular: 32h @ $20 + 8h @ $30 = $640 + $240 = $880.
        // Overtime: 4h @ $30 x 1.5 = $180. Total $1060.
        var shifts: [Shift] = []
        for day in 5...8 {
            shifts.append(makeShift(
                start: makeDate(2026, 10, day, 9),
                end: makeDate(2026, 10, day, 17),
                hourlyRate: 20
            ))
        }
        shifts.append(makeShift(
            start: makeDate(2026, 10, 9, 8),
            end: makeDate(2026, 10, 9, 20),
            hourlyRate: 30
        ))
        let result = PayEstimator.breakdown(for: shifts, in: weekInterval(), calendar: testCalendar)
        XCTAssertEqual(result.regularHours, 40, accuracy: 0.001)
        XCTAssertEqual(result.overtimeHours, 4, accuracy: 0.001)
        XCTAssertEqual(result.totalPay, 1_060, accuracy: 0.001)
    }

    func testOvertimeDoesNotCarryAcrossWeeks() {
        // 30h this week + 30h next week: no overtime in either week.
        let thisWeek = makeShift(start: makeDate(2026, 10, 5, 9), end: makeDate(2026, 10, 6, 15), hourlyRate: 20) // 30h
        let nextWeek = makeShift(start: makeDate(2026, 10, 12, 9), end: makeDate(2026, 10, 13, 15), hourlyRate: 20) // 30h
        let interval = DateInterval(
            start: weekInterval().start,
            end: weekInterval().start.addingTimeInterval(14 * 86_400)
        )
        let result = PayEstimator.breakdown(for: [thisWeek, nextWeek], in: interval, calendar: testCalendar)
        XCTAssertEqual(result.overtimeHours, 0, accuracy: 0.001)
        XCTAssertEqual(result.totalPay, 60 * 20, accuracy: 0.001)
    }

    func testOvernightShiftCountedInStartWeek() {
        // Sunday 22:00 -> Monday 06:00 belongs to the week it starts in.
        let overnight = makeShift(
            start: makeDate(2026, 10, 11, 22),
            end: makeDate(2026, 10, 12, 6),
            hourlyRate: 25
        )
        let result = PayEstimator.breakdown(for: [overnight], in: weekInterval(), calendar: testCalendar)
        XCTAssertEqual(result.shiftCount, 1)
        XCTAssertEqual(result.totalPay, 8 * 25, accuracy: 0.001)
    }

    func testCustomPolicy() {
        // 40h week with a 35h threshold and 2x multiplier.
        var shifts: [Shift] = []
        for day in 5...9 {
            shifts.append(makeShift(
                start: makeDate(2026, 10, day, 9),
                end: makeDate(2026, 10, day, 17),
                hourlyRate: 20
            ))
        }
        let policy = OvertimePolicy(regularHoursPerWeek: 35, overtimeMultiplier: 2.0)
        let result = PayEstimator.breakdown(for: shifts, in: weekInterval(), policy: policy, calendar: testCalendar)
        XCTAssertEqual(result.regularHours, 35, accuracy: 0.001)
        XCTAssertEqual(result.overtimeHours, 5, accuracy: 0.001)
        XCTAssertEqual(result.totalPay, 35 * 20 + 5 * 20 * 2.0, accuracy: 0.001)
    }

    func testEmptyIntervalYieldsZero() {
        let result = PayEstimator.breakdown(for: [], in: weekInterval(), calendar: testCalendar)
        XCTAssertEqual(result.totalPay, 0, accuracy: 0.001)
        XCTAssertEqual(result.effectiveHourlyRate, 0, accuracy: 0.001)
    }

    func testWeeksHelperSplitsOnMondays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Toronto")!
        let interval = DateInterval(start: makeDate(2026, 10, 7, 12), duration: 10 * 86_400)
        let weeks = PayEstimator.weeks(in: interval, calendar: calendar)
        XCTAssertEqual(weeks.count, 2)
        // Each week starts on a Monday (weekday 2).
        for week in weeks {
            XCTAssertEqual(calendar.component(.weekday, from: week.start), 2)
        }
    }
}
