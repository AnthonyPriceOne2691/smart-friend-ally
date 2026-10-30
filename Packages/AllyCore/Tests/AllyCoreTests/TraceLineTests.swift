import AllyCore
import XCTest

final class TraceLineTests: XCTestCase {
    func testTheSystemLogGetsTheTraceFilesLineAndNoWordOfTheTurn() async throws {  // N8
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("turns.jsonl"), logged = Locked([String]())
        // The session hands the sink every record with its words (the black box's path): the file and the log get the
        // same record, the words go nowhere.
        let sink = TraceFanOut([TraceFile(url: url), TraceLine { line in logged { $0.append(line) } }])
        let parts = SessionParts(model: ReplyQueue(["Динозавры жили давно."]), voice: RecordingVoice(), sink: sink,
                                 clock: TestClock())
        let session = Session(parts)
        await session.handle(.wake)
        await session.handle(.heard("Расскажи про динозавров"))
        await session.handle(.stop)
        let file = try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map(String.init)
        let lines = logged { $0 }
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines, file)
        for line in lines {
            XCTAssertNil(line.range(of: "[А-Яа-яЁё]", options: .regularExpression), line)
            for word in ["Расскажи", "динозавр", "Динозавры", "давно"] {
                XCTAssertFalse(line.contains(word), word + " in " + line)
            }
        }
        XCTAssertTrue(lines[1].contains("\"source\":\"model\""), lines[1])
    }
}
