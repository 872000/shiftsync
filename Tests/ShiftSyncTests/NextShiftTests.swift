import XCTest
@testable import ShiftSync

final class NextShiftTests: XCTestCase {

    // Fixed "now": Monday 2026-10-05, 08:00 Toronto time.
    let now = makeDate(2026, 10, 5, 8, 0)

    func sampleShifts() -> [Shift] {
        [
            // Past shift.
            makeShift(start: makeDate(2026, 10, 4, 9), end: makeDate(2026, 10, 4, 17)),
            // Currently in progress (07:00–15:00).
            makeShift(start: makeDate(2026, 10, 5, 7), end: makeDate(2026, 10, 5, 15)),
            // Next shift: Tuesday 09:00.
            makeShift(start: makeDate(2026, 10, 6, 9), end: makeDate(2026, 10, 6, 17)),
            // Later shift: Friday 09:00.
            makeShift(start: makeDate(2026, 10, 9, 9), end: makeDate(2026, 10, 9, 17)),
        ]
    }

    func testFindsCurrentShift() {
        let current = NextShiftResolver.currentShift(at: now, in: sampleShifts())
        XCTAssertEqual(current?.start, makeDate(2026, 10, 5, 7))
    }

    func testFindsNextShift() {
        let next = NextShiftResolver.nextShift(after: now, in: sampleShifts())
        XCTAssertEqual(next?.start, makeDate(2026, 10, 6, 9))
    }

    func testNoNextShiftWhenAllPast() {
        let past = [makeShift(start: makeDate(2026, 10, 4, 9), end: makeDate(2026, 10, 4, 17))]
        XCTAssertNil(NextShiftResolver.nextShift(after: now, in: past))
    }

    func testCountdownMath() {
        // Tuesday 09:00 is exactly 25 hours after Monday 08:00.
        let shift = makeShift(start: makeDate(2026, 10, 6, 9), end: makeDate(2026, 10, 6, 17))
        let countdown = NextShiftResolver.countdown(to: shift, from: now)
        XCTAssertEqual(countdown.totalSeconds, 25 * 3_600)
        XCTAssertEqual(countdown.days, 1)
        XCTAssertEqual(countdown.hours, 1)
        XCTAssertEqual(countdown.minutes, 0)
        XCTAssertEqual(countdown.displayString, "1d 1h 0m")
        XCTAssertFalse(countdown.isImminent)
    }

    func testCountdownDisplayFormats() {
        XCTAssertEqual(ShiftCountdown(totalSeconds: 90).displayString, "1m 30s")
        XCTAssertEqual(ShiftCountdown(totalSeconds: 3_661).displayString, "1h 1m 1s")
        XCTAssertEqual(ShiftCountdown(totalSeconds: 2 * 86_400 + 30).displayString, "2d 0h 0m")
    }

    func testImminentCountdown() {
        let soon = makeShift(start: now.addingTimeInterval(30 * 60), end: now.addingTimeInterval(8 * 3_600))
        let countdown = NextShiftResolver.countdown(to: soon, from: now)
        XCTAssertTrue(countdown.isImminent)
    }

    func testCountdownClampsNegativeToZero() {
        XCTAssertEqual(ShiftCountdown(totalSeconds: -100).totalSeconds, 0)
    }
}
