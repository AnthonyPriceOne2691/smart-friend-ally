import Foundation

/// The records on the phone (D2.2): one JSON line a record, appended to a file (`Caches/turns.jsonl`). A write that
/// fails is counted for the console and the session goes on; the black box (D3) puts its own store behind `TraceSink`.
public final class TraceFile: TraceSink {
    private let url: URL, failed = Locked(0)

    public init(url: URL) { self.url = url }

    /// Records that did not reach the file.
    public var failures: Int { failed { $0 } }

    public func write(_ trace: TurnTrace) {
        let line = trace.jsonLine().map { Data(($0 + "\n").utf8) }
        failed { count in
            if let line, append(line) { return }
            count += 1
        }
    }

    private func append(_ line: Data) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return FileManager.default.createFile(atPath: url.path, contents: line)
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return false }
        defer { try? handle.close() }
        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
            return true
        } catch {
            return false
        }
    }
}
