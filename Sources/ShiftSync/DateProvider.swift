import Foundation

/// Abstraction over "now" so countdowns and swap validation stay testable.
public protocol DateProvider: Sendable {
    var now: Date { get }
}

/// Production clock: reads the real current time.
public struct SystemDateProvider: DateProvider {
    public init() {}
    public var now: Date { Date() }
}

/// Test clock: always returns the fixed date it was built with.
public struct FixedDateProvider: DateProvider {
    public let now: Date
    public init(now: Date) { self.now = now }
}
