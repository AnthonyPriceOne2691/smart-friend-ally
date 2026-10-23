import AllySQLite
import Foundation
import XCTest

final class SQLiteTests: XCTestCase {
    /// M22: values come back as bound, an error names SQLite's code and text, a failed transaction leaves nothing, the
    /// file keeps what was committed across a reopen.
    func testValuesErrorsTransactionAndReopen() throws {  // M22
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("m22-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("t.sqlite").path
        FileHandle.standardError.write(Data("M22: SQLite \(SQLiteConnection.version)\n".utf8))
        XCTAssertTrue(SQLiteConnection.version.hasPrefix("3."), SQLiteConnection.version)

        var db = try SQLiteConnection(path: path)
        try db.exec("CREATE TABLE t (a TEXT, b INTEGER, c REAL, d TEXT, e INTEGER CHECK (e > 0))")
        try db.run("INSERT INTO t VALUES (?, ?, ?, ?, ?)", [.text("кошка Мурка"), .int(5), .real(0.9), .null, .int(1)])
        XCTAssertEqual(try db.rows("SELECT a, b, c, d FROM t"), [[.text("кошка Мурка"), .int(5), .real(0.9), .null]])
        let utf8 = Data("кошка Мурка".utf8).map { String(format: "%02X", $0) }.joined()
        XCTAssertEqual(try db.rows("SELECT hex(a) FROM t"), [[.text(utf8)]])

        XCTAssertThrowsError(try db.rows("SELECT * FROM x")) { error in
            XCTAssertEqual(error as? SQLiteError, SQLiteError(code: 1, message: "no such table: x"))
        }
        XCTAssertThrowsError(try db.transaction {
            try db.run("INSERT INTO t VALUES ('a', 2, 0.5, NULL, 2)")
            try db.run("INSERT INTO t VALUES ('b', 3, 0.5, NULL, 0)")
        }) { error in
            XCTAssertEqual((error as? SQLiteError)?.code, 19)
        }
        XCTAssertEqual(try db.rows("SELECT count(*) FROM t"), [[.int(1)]])

        db.close()
        db = try SQLiteConnection(path: path)
        XCTAssertEqual(try db.rows("SELECT a, b FROM t"), [[.text("кошка Мурка"), .int(5)]])
    }
}
