import Foundation

public enum SwapError: Error, Equatable, Sendable {
    case shiftAlreadyStarted
    case alreadyHasOpenPost
    case postNotFound
    case postNotOpen
    case cannotClaimOwnPost
    case onlyOwnerCanCancel
    case emptyName
}

/// A shift offered up for swapping. Carries a snapshot of the shift so the
/// board stays meaningful even if the original shift is later edited.
public struct SwapPost: Identifiable, Codable, Hashable, Sendable {
    public enum Status: String, Codable, Sendable {
        case open, claimed, cancelled
    }

    public var id: UUID
    public var shift: Shift
    public var ownerName: String
    public var note: String
    public var postedAt: Date
    public var status: Status
    public var claimedBy: String?

    public init(
        id: UUID = UUID(),
        shift: Shift,
        ownerName: String,
        note: String = "",
        postedAt: Date,
        status: Status = .open,
        claimedBy: String? = nil
    ) {
        self.id = id
        self.shift = shift
        self.ownerName = ownerName
        self.note = note
        self.postedAt = postedAt
        self.status = status
        self.claimedBy = claimedBy
    }
}

/// Coworker swap board: post shifts, claim open ones, cancel your own posts.
public struct SwapBoard: Codable, Equatable, Sendable {
    public private(set) var posts: [SwapPost]

    public init(posts: [SwapPost] = []) {
        self.posts = posts
    }

    /// Open posts, soonest shift first.
    public func openPosts() -> [SwapPost] {
        posts
            .filter { $0.status == .open }
            .sorted { $0.shift.start < $1.shift.start }
    }

    public mutating func post(shift: Shift, ownerName: String, note: String = "", now: Date) throws {
        let owner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !owner.isEmpty else { throw SwapError.emptyName }
        guard shift.start > now else { throw SwapError.shiftAlreadyStarted }
        guard !posts.contains(where: { $0.shift.id == shift.id && $0.status == .open }) else {
            throw SwapError.alreadyHasOpenPost
        }
        posts.append(SwapPost(shift: shift, ownerName: owner, note: note, postedAt: now))
    }

    public mutating func claim(postID: UUID, by coworkerName: String, now: Date) throws {
        let coworker = coworkerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !coworker.isEmpty else { throw SwapError.emptyName }
        guard let index = posts.firstIndex(where: { $0.id == postID }) else {
            throw SwapError.postNotFound
        }
        guard posts[index].status == .open else { throw SwapError.postNotOpen }
        guard posts[index].shift.start > now else { throw SwapError.shiftAlreadyStarted }
        guard posts[index].ownerName.lowercased() != coworker.lowercased() else {
            throw SwapError.cannotClaimOwnPost
        }
        posts[index].status = .claimed
        posts[index].claimedBy = coworker
    }

    public mutating func cancel(postID: UUID, by requesterName: String) throws {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else {
            throw SwapError.postNotFound
        }
        guard posts[index].status == .open else { throw SwapError.postNotOpen }
        let requester = requesterName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard posts[index].ownerName.lowercased() == requester else {
            throw SwapError.onlyOwnerCanCancel
        }
        posts[index].status = .cancelled
    }

    // MARK: - Persistence helpers

    public func encodeToJSON() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func decodeFromJSON(_ data: Data) throws -> SwapBoard {
        try JSONDecoder().decode(SwapBoard.self, from: data)
    }
}
