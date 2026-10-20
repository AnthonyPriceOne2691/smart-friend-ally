import Foundation

/// State behind a lock, for what tasks and cancellation handlers touch at once.
public final class Locked<State>: @unchecked Sendable {
    private let lock = NSLock()
    private var state: State
    public init(_ state: State) { self.state = state }

    public func callAsFunction<Result>(_ body: (inout State) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(&state)
    }
}
