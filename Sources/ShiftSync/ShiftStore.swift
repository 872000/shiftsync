import Foundation

/// In-memory schedule store. A pure value type — encode it to JSON for
/// persistence (helpers below); the UI layer decides where the data lives.
public struct ShiftStore: Codable, Equatable, Sendable {
    public private(set) var shifts: [Shift]

    public init(shifts: [Shift] = []) {
        self.shifts = shifts
    }

    public mutating func add(_ shift: Shift) throws {
        try ShiftValidator.validate(shift)
        shifts.append(shift)
    }

    public mutating func update(_ shift: Shift) throws {
        try ShiftValidator.validate(shift)
        guard let index = shifts.firstIndex(where: { $0.id == shift.id }) else { return }
        shifts[index] = shift
    }

    public mutating func remove(id: UUID) {
        shifts.removeAll { $0.id == id }
    }

    public func sorted() -> [Shift] {
        shifts.sorted { $0.start < $1.start }
    }

    /// Shifts that start on the given calendar day.
    public func shifts(on date: Date, calendar: Calendar = .current) -> [Shift] {
        shifts
            .filter { calendar.isDate($0.start, inSameDayAs: date) }
            .sorted { $0.start < $1.start }
    }

    /// Shifts that start inside the interval.
    public func shifts(in interval: DateInterval) -> [Shift] {
        shifts
            .filter { interval.contains($0.start) }
            .sorted { $0.start < $1.start }
    }

    // MARK: - Persistence helpers

    public func encodeToJSON() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func decodeFromJSON(_ data: Data) throws -> ShiftStore {
        try JSONDecoder().decode(ShiftStore.self, from: data)
    }
}
