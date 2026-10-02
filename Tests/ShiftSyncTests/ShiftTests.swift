import XCTest
@testable import ShiftSync

final class ShiftTests: XCTestCase {

    func testDurationHoursForStandardShift() {
        let shift = makeShift(start: makeDate(2026, 10, 5, 9), end: makeDate(2026, 10, 5, 17))
        XCTAssertEqual(shift.durationHours, 8.0, accuracy: 0.0001)
    }

    func testOvernightShiftDuration() {
        // 10 PM -> 6 AM crosses midnight.
        let shift = makeShift(start: makeDate(2026, 10, 5, 22), end: makeDate(2026, 10, 6, 6))
        XCTAssertEqual(shift.durationHours, 8.0, accuracy: 0.0001)
        XCTAssertTrue(shift.isOvernight(using: testCalendar))
    }

    func testDayShiftIsNotOvernight() {
        let shift = makeShift(start: makeDate(2026, 10, 5, 9), end: makeDate(2026, 10, 5, 17))
        XCTAssertFalse(shift.isOvernight(using: testCalendar))
    }

    func testGrossPay() {
        let shift = makeShift(
            start: makeDate(2026, 10, 5, 9),
            end: makeDate(2026, 10, 5, 16, 30),
            hourlyRate: 22.50
        )
        XCTAssertEqual(shift.grossPay, 7.5 * 22.50, accuracy: 0.0001)
    }

    func testValidationRejectsEndBeforeStart() {
        let shift = makeShift(start: makeDate(2026, 10, 5, 17), end: makeDate(2026, 10, 5, 9))
        XCTAssertThrowsError(try ShiftValidator.validate(shift)) { error in
            XCTAssertEqual(error as? ShiftValidationError, .endNotAfterStart)
        }
    }

    func testValidationRejectsShiftLongerThan24Hours() {
        let shift = makeShift(start: makeDate(2026, 10, 5, 8), end: makeDate(2026, 10, 6, 9))
        XCTAssertThrowsError(try ShiftValidator.validate(shift)) { error in
            XCTAssertEqual(error as? ShiftValidationError, .shiftTooLong(maxHours: 24))
        }
    }

    func testValidationRejectsNegativeRate() {
        let shift = makeShift(
            start: makeDate(2026, 10, 5, 9),
            end: makeDate(2026, 10, 5, 17),
            hourlyRate: -5
        )
        XCTAssertThrowsError(try ShiftValidator.validate(shift)) { error in
            XCTAssertEqual(error as? ShiftValidationError, .negativeHourlyRate)
        }
    }

    func testValidationRejectsEmptyRole() {
        let shift = makeShift(
            start: makeDate(2026, 10, 5, 9),
            end: makeDate(2026, 10, 5, 17),
            role: "   "
        )
        XCTAssertThrowsError(try ShiftValidator.validate(shift)) { error in
            XCTAssertEqual(error as? ShiftValidationError, .emptyRole)
        }
    }

    func testValidationAcceptsGoodShift() throws {
        let shift = makeShift(start: makeDate(2026, 10, 5, 9), end: makeDate(2026, 10, 5, 17))
        try ShiftValidator.validate(shift) // must not throw
    }

    // MARK: - Store

    func testStoreAddUpdateRemove() throws {
        var store = ShiftStore()
        var shift = makeShift(start: makeDate(2026, 10, 5, 9), end: makeDate(2026, 10, 5, 17))
        try store.add(shift)
        XCTAssertEqual(store.shifts.count, 1)

        shift.role = "Supervisor"
        try store.update(shift)
        XCTAssertEqual(store.shifts.first?.role, "Supervisor")

        store.remove(id: shift.id)
        XCTAssertTrue(store.shifts.isEmpty)
    }

    func testStoreRejectsInvalidShift() {
        var store = ShiftStore()
        let bad = makeShift(start: makeDate(2026, 10, 5, 17), end: makeDate(2026, 10, 5, 9))
        XCTAssertThrowsError(try store.add(bad))
        XCTAssertTrue(store.shifts.isEmpty)
    }

    func testStoreShiftsOnDay() throws {
        var store = ShiftStore()
        try store.add(makeShift(start: makeDate(2026, 10, 5, 9), end: makeDate(2026, 10, 5, 17)))
        try store.add(makeShift(start: makeDate(2026, 10, 6, 9), end: makeDate(2026, 10, 6, 17)))
        let monday = store.shifts(on: makeDate(2026, 10, 5))
        XCTAssertEqual(monday.count, 1)
    }

    func testStoreJSONRoundTrip() throws {
        var store = ShiftStore()
        try store.add(makeShift(start: makeDate(2026, 10, 5, 9), end: makeDate(2026, 10, 5, 17)))
        let restored = try ShiftStore.decodeFromJSON(store.encodeToJSON())
        XCTAssertEqual(restored, store)
    }
}
