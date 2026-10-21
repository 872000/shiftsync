import Foundation

/// What can go wrong when validating a shift before it is stored.
///
/// `endNotAfterStart` means the end date is not strictly after the start date;
/// the other cases are caught before that check runs.
public enum ShiftValidationError: Error, Equatable, Sendable {
    case endNotAfterStart
    case shiftTooLong(maxHours: Double)
    case negativeHourlyRate
    case emptyRole
}

/// Input validation for shifts, shared by the store and the UI form.
public enum ShiftValidator {
    public static let maxShiftHours = 24.0

    public static func validate(_ shift: Shift) throws {
        guard shift.end > shift.start else {
            throw ShiftValidationError.endNotAfterStart
        }
        guard shift.durationHours <= maxShiftHours else {
            throw ShiftValidationError.shiftTooLong(maxHours: maxShiftHours)
        }
        guard shift.hourlyRate >= 0 else {
            throw ShiftValidationError.negativeHourlyRate
        }
        guard !shift.role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShiftValidationError.emptyRole
        }
    }
}
