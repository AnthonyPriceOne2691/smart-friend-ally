import CSQLite
import Foundation

/// What SQLite answered: its result code and its message.
public struct SQLiteError: Error, Equatable, CustomStringConvertible {
    public let code: Int32, message: String

    public init(code: Int32, message: String) { (self.code, self.message) = (code, message) }

    public var description: String { "SQLite \(code): \(message)" }
}

/// A value bound to a statement or read from a row.
public enum SQLiteValue: Equatable, Sendable {
    case int(Int64), real(Double), text(String), null

    public var int: Int64? { if case .int(let value) = self { value } else { nil } }
    public var real: Double? { if case .real(let value) = self { value } else { int.map(Double.init) } }
    public var text: String? { if case .text(let value) = self { value } else { nil } }
}

/// One connection to one database file. It is not shared between threads: its owner serializes the calls.
public final class SQLiteConnection {
    /// The library's version, «3.45.1»: the SQLite of the system the package runs on.
    public static var version: String { String(cString: sqlite3_libversion()) }

    /// The open flag of the complete file protection for the base, its WAL and SHM — Apple's SQLite; elsewhere none.
    public static var protectionComplete: Int32 {
        #if canImport(Darwin)
        SQLITE_OPEN_FILEPROTECTION_COMPLETE
        #else
        0
        #endif
    }

    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    private var handle: OpaquePointer?
    /// One caller at a time on the connection; a transaction holds it for its whole body.
    private let lock = NSRecursiveLock()

    /// Opens the file, creating it; `flags` add to read-write-create (on Apple — the file protection class).
    public init(path: String, flags: Int32 = 0) throws {
        let code = sqlite3_open_v2(path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | flags, nil)
        guard code == SQLITE_OK else {
            let error = failure(code)
            close()
            throw error
        }
    }

    deinit { sqlite3_close_v2(handle) }

    /// Closes the file; every later call answers with an error.
    public func close() {
        sqlite3_close_v2(handle)
        handle = nil
    }

    /// One or several statements that return no rows.
    public func exec(_ sql: String) throws {
        lock.lock()
        defer { lock.unlock() }
        var message: UnsafeMutablePointer<CChar>?
        let code = sqlite3_exec(handle, sql, nil, nil, &message)
        defer { sqlite3_free(message) }
        guard code == SQLITE_OK else {
            throw SQLiteError(code: code, message: message.map { String(cString: $0) } ?? failure(code).message)
        }
    }

    /// The rows of one statement with the values bound in order; each row — its columns.
    public func rows(_ sql: String, _ values: [SQLiteValue] = []) throws -> [[SQLiteValue]] {
        lock.lock()
        defer { lock.unlock() }
        var statement: OpaquePointer?
        let prepared = sqlite3_prepare_v2(handle, sql, -1, &statement, nil)
        defer { sqlite3_finalize(statement) }
        guard prepared == SQLITE_OK else { throw failure(prepared) }
        try bind(values, to: statement)
        var rows: [[SQLiteValue]] = []
        while true {
            let code = sqlite3_step(statement)
            if code == SQLITE_DONE { return rows }
            guard code == SQLITE_ROW else { throw failure(code) }
            rows.append((0..<sqlite3_column_count(statement)).map { column(statement, $0) })
        }
    }

    /// One statement for its effect; how many rows it changed.
    @discardableResult
    public func run(_ sql: String, _ values: [SQLiteValue] = []) throws -> Int {
        _ = try rows(sql, values)
        return Int(sqlite3_changes(handle))
    }

    /// The row id of the last insert on this connection.
    public var lastInsertID: Int64 { sqlite3_last_insert_rowid(handle) }

    /// All of `body` or nothing: `BEGIN IMMEDIATE` … `COMMIT`; an error rolls back all of it and goes to the caller.
    public func transaction<Result>(_ body: () throws -> Result) throws -> Result {
        lock.lock()
        defer { lock.unlock() }
        try exec("BEGIN IMMEDIATE")
        do {
            let result = try body()
            try exec("COMMIT")
            return result
        } catch {
            _ = try? exec("ROLLBACK")
            throw error
        }
    }

    /// A pure SQL function of one value for this connection — a schema's trigger may call it; NULL answers false.
    public func function(_ name: String, _ body: @escaping (String) -> Bool) throws {
        let flags = SQLITE_UTF8 | SQLITE_DETERMINISTIC | SQLITE_INNOCUOUS
        let box = Unmanaged.passRetained(Predicate(body)).toOpaque()
        let code = sqlite3_create_function_v2(handle, name, 1, flags, box, { context, _, values in
            let predicate = Unmanaged<Predicate>.fromOpaque(UnsafeRawPointer(sqlite3_user_data(context)))
            let text = sqlite3_value_text(values?[0]).map { String(cString: $0) }
            sqlite3_result_int(context, text.map(predicate.takeUnretainedValue().body) == true ? 1 : 0)
        }, nil, nil, { box in box.map { Unmanaged<Predicate>.fromOpaque($0).release() } })
        guard code == SQLITE_OK else { throw failure(code) }
    }

    private func bind(_ values: [SQLiteValue], to statement: OpaquePointer?) throws {
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let code = switch value {
            case .int(let number): sqlite3_bind_int64(statement, index, number)
            case .real(let number): sqlite3_bind_double(statement, index, number)
            case .text(let text): sqlite3_bind_text(statement, index, text, -1, Self.transient)
            case .null: sqlite3_bind_null(statement, index)
            }
            guard code == SQLITE_OK else { throw failure(code) }
        }
    }

    private func column(_ statement: OpaquePointer?, _ index: Int32) -> SQLiteValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER: .int(sqlite3_column_int64(statement, index))
        case SQLITE_FLOAT: .real(sqlite3_column_double(statement, index))
        case SQLITE_NULL: .null
        default: .text(sqlite3_column_text(statement, index).map { String(cString: $0) } ?? "")
        }
    }

    private func failure(_ code: Int32) -> SQLiteError {
        let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? String(cString: sqlite3_errstr(code))
        return SQLiteError(code: code, message: message)
    }
}

/// The closure behind a SQL function; SQLite keeps it retained and releases it when the connection lets it go.
private final class Predicate {
    let body: (String) -> Bool
    init(_ body: @escaping (String) -> Bool) { self.body = body }
}
