import XCTest
@testable import ShiftSync

final class SwapBoardTests: XCTestCase {

    let now = makeDate(2026, 10, 5, 8, 0)

    func futureShift() -> Shift {
        makeShift(start: makeDate(2026, 10, 6, 9), end: makeDate(2026, 10, 6, 17))
    }

    func testPostAndListOpen() throws {
        var board = SwapBoard()
        try board.post(shift: futureShift(), ownerName: "Parth", note: "Can't make it", now: now)
        let open = board.openPosts()
        XCTAssertEqual(open.count, 1)
        XCTAssertEqual(open.first?.ownerName, "Parth")
        XCTAssertEqual(open.first?.status, .open)
    }

    func testCannotPostStartedShift() {
        var board = SwapBoard()
        let past = makeShift(start: makeDate(2026, 10, 4, 9), end: makeDate(2026, 10, 4, 17))
        XCTAssertThrowsError(try board.post(shift: past, ownerName: "Parth", now: now)) { error in
            XCTAssertEqual(error as? SwapError, .shiftAlreadyStarted)
        }
    }

    func testCannotDoublePostSameShift() throws {
        var board = SwapBoard()
        let shift = futureShift()
        try board.post(shift: shift, ownerName: "Parth", now: now)
        XCTAssertThrowsError(try board.post(shift: shift, ownerName: "Parth", now: now)) { error in
            XCTAssertEqual(error as? SwapError, .alreadyHasOpenPost)
        }
    }

    func testClaimByCoworker() throws {
        var board = SwapBoard()
        try board.post(shift: futureShift(), ownerName: "Parth", now: now)
        let postID = board.openPosts().first!.id
        try board.claim(postID: postID, by: "Aisha", now: now)
        XCTAssertTrue(board.openPosts().isEmpty)
        XCTAssertEqual(board.posts.first?.status, .claimed)
        XCTAssertEqual(board.posts.first?.claimedBy, "Aisha")
    }

    func testCannotClaimOwnPost() throws {
        var board = SwapBoard()
        try board.post(shift: futureShift(), ownerName: "Parth", now: now)
        let postID = board.openPosts().first!.id
        XCTAssertThrowsError(try board.claim(postID: postID, by: "parth", now: now)) { error in
            XCTAssertEqual(error as? SwapError, .cannotClaimOwnPost)
        }
    }

    func testCannotClaimTwice() throws {
        var board = SwapBoard()
        try board.post(shift: futureShift(), ownerName: "Parth", now: now)
        let postID = board.openPosts().first!.id
        try board.claim(postID: postID, by: "Aisha", now: now)
        XCTAssertThrowsError(try board.claim(postID: postID, by: "Ravi", now: now)) { error in
            XCTAssertEqual(error as? SwapError, .postNotOpen)
        }
    }

    func testOwnerCanCancel() throws {
        var board = SwapBoard()
        try board.post(shift: futureShift(), ownerName: "Parth", now: now)
        let postID = board.openPosts().first!.id
        try board.cancel(postID: postID, by: "Parth")
        XCTAssertTrue(board.openPosts().isEmpty)
        XCTAssertEqual(board.posts.first?.status, .cancelled)
    }

    func testNonOwnerCannotCancel() throws {
        var board = SwapBoard()
        try board.post(shift: futureShift(), ownerName: "Parth", now: now)
        let postID = board.openPosts().first!.id
        XCTAssertThrowsError(try board.cancel(postID: postID, by: "Aisha")) { error in
            XCTAssertEqual(error as? SwapError, .onlyOwnerCanCancel)
        }
    }

    func testBoardJSONRoundTrip() throws {
        var board = SwapBoard()
        try board.post(shift: futureShift(), ownerName: "Parth", now: now)
        let restored = try SwapBoard.decodeFromJSON(board.encodeToJSON())
        XCTAssertEqual(restored, board)
    }
}
