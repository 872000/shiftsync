import SwiftUI
import ShiftSync

// MARK: - Schedule

@Observable
final class ScheduleViewModel {
    var store = ShiftStore()
    var payPolicy = OvertimePolicy.standard
    var lastError: String?

    private let storeURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("shiftsync-shifts.json")
    }()

    init() { load() }

    func add(_ shift: Shift) {
        do {
            try store.add(shift)
            save()
        } catch {
            lastError = friendlyMessage(for: error)
        }
    }

    func update(_ shift: Shift) {
        do {
            try store.update(shift)
            save()
        } catch {
            lastError = friendlyMessage(for: error)
        }
    }

    func remove(_ shift: Shift) {
        store.remove(id: shift.id)
        save()
    }

    func upcomingShifts(now: Date = Date()) -> [Shift] {
        store.shifts.filter { $0.end > now }.sorted { $0.start < $1.start }
    }

    func nextShift(now: Date = Date()) -> Shift? {
        NextShiftResolver.nextShift(after: now, in: store.shifts)
    }

    func currentShift(now: Date = Date()) -> Shift? {
        NextShiftResolver.currentShift(at: now, in: store.shifts)
    }

    private func save() {
        try? store.encodeToJSON().write(to: storeURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? ShiftStore.decodeFromJSON(data) else { return }
        store = decoded
    }

    private func friendlyMessage(for error: Error) -> String {
        switch error as? ShiftValidationError {
        case .endNotAfterStart: return "The shift must end after it starts."
        case .shiftTooLong: return "A shift can't be longer than 24 hours."
        case .negativeHourlyRate: return "Hourly rate can't be negative."
        case .emptyRole: return "Please enter a role for the shift."
        case .none: return error.localizedDescription
        }
    }
}

// MARK: - Swap board

@Observable
final class SwapBoardViewModel {
    var board = SwapBoard()
    var lastError: String?
    var myName: String = UserDefaults.standard.string(forKey: "shiftsync.myName") ?? ""

    private let boardURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("shiftsync-swaps.json")
    }()

    init() { load() }

    func saveName(_ name: String) {
        myName = name
        UserDefaults.standard.set(name, forKey: "shiftsync.myName")
    }

    func post(shift: Shift, note: String) {
        do {
            try board.post(shift: shift, ownerName: myName, note: note, now: Date())
            save()
        } catch {
            lastError = friendlyMessage(for: error)
        }
    }

    func claim(_ post: SwapPost) {
        do {
            try board.claim(postID: post.id, by: myName, now: Date())
            save()
        } catch {
            lastError = friendlyMessage(for: error)
        }
    }

    func cancel(_ post: SwapPost) {
        do {
            try board.cancel(postID: post.id, by: myName)
            save()
        } catch {
            lastError = friendlyMessage(for: error)
        }
    }

    private func save() {
        try? board.encodeToJSON().write(to: boardURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: boardURL),
              let decoded = try? SwapBoard.decodeFromJSON(data) else { return }
        board = decoded
    }

    private func friendlyMessage(for error: Error) -> String {
        switch error as? SwapError {
        case .shiftAlreadyStarted: return "That shift has already started."
        case .alreadyHasOpenPost: return "This shift is already posted for swap."
        case .postNotFound: return "That post no longer exists."
        case .postNotOpen: return "That post is no longer open."
        case .cannotClaimOwnPost: return "You can't claim your own post."
        case .onlyOwnerCanCancel: return "Only the poster can cancel this."
        case .emptyName: return "Please set your name first (Swaps tab)."
        case .none: return error.localizedDescription
        }
    }
}
