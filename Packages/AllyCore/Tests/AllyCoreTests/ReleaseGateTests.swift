@testable import AllyCore
import Discipline
import XCTest

/// The surface of the fixtures: short prefixed hashes (L38), never the real ones.
let fixtureSurface = ReleaseSurface(contract: "fnv1a:test-contract", router: "fnv1a:test-router",
                                    persona: "sha256:test-persona", model: "test.gguf:100")

/// The lock over a fixed «now» in Moscow time: the exception's JSON, signed or not, and the build — the fixture
/// surface, self-tests passed, the parent's key in the bundle.
struct Lock {
    let zone: TimeZone, dates = ISO8601DateFormatter()
    var build = ReleaseGate.Build(surface: fixtureSurface)

    init() throws { zone = try XCTUnwrap(TimeZone(secondsFromGMT: 3 * 3_600)) }

    func at(_ text: String) throws -> Date { try XCTUnwrap(dates.date(from: text), text) }

    func file(from: String = "2026-10-23T09:00:00+03:00", until: String = "2026-10-29T21:00:00+03:00",
              surface: ReleaseSurface = fixtureSurface) throws -> Data {
        let object: [String: Any] = ["from": from, "until": until, "note": "дочь пробует только при мне",
                                     "surface": ["contract": surface.contract, "router": surface.router,
                                                 "persona": surface.persona, "model": surface.model]]
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    func access(_ bytes: Data?, signed: Bool = true, now: String = "2026-10-25T12:00:00+03:00") throws -> ChildAccess {
        ReleaseGate.access(exception: bytes.map { SignedFile(bytes: $0, signed: signed) }, build: build,
                           now: try at(now), zone: zone)
    }
}

final class ReleaseGateTests: XCTestCase {
    func testNoExceptionKeepsTheModeClosed() throws {  // G1
        let lock = try Lock(), access = try lock.access(nil)
        XCTAssertEqual(access, .parentOnly(["нет исключения родителя"]))
        XCTAssertNil(access.until)
        XCTAssertEqual(ReleaseGate.lines(access, zone: lock.zone),
                       ["при родителе: нет исключения родителя", "без присмотра: закрыт до целей безопасности"])
    }

    func testASignedExceptionOpensTheModeUntilItsDate() throws {  // G2
        let lock = try Lock(), access = try lock.access(try lock.file())
        XCTAssertEqual(access, .supervised(until: try lock.at("2026-10-29T21:00:00+03:00")))
        XCTAssertEqual(ReleaseGate.lines(access, zone: lock.zone).first, "при родителе: до 29.10 в 21:00")
        let current = ReleaseGate.Build.current(personaSHA256: "329790cc", model: "w.gguf:1", key: true)
        XCTAssertEqual(current.surface.contract, "fnv1a:" + TurnContract(mode: .talk).finish("").record.contractHash)
        XCTAssertEqual(current.surface.router, "fnv1a:" + Router.shared.route("").record.dataHash)
        XCTAssertEqual([current.surface.persona, current.surface.model], ["sha256:329790cc", "w.gguf:1"])
        XCTAssertEqual([current.router, current.contract, current.key], [true, true, true])
    }

    func testTheTermIsAtMostSevenDaysFromItsStartUntilItsEnd() throws {  // G3
        let lock = try Lock(), file = try lock.file()
        XCTAssertNotNil(try lock.access(file, now: "2026-10-29T20:59:59+03:00").until)
        XCTAssertEqual(try lock.access(file, now: "2026-10-29T21:00:00+03:00"),
                       .parentOnly(["исключение истекло 29.10 в 21:00"]))
        XCTAssertEqual(try lock.access(file, now: "2026-10-23T08:59:59+03:00"),
                       .parentOnly(["исключение начнётся 23.10 в 09:00"]))
        XCTAssertNotNil(try lock.access(try lock.file(until: "2026-10-30T09:00:00+03:00")).until)
        XCTAssertEqual(try lock.access(try lock.file(until: "2026-10-30T09:00:01+03:00")),
                       .parentOnly(["исключение длиннее 7 дней"]))
    }

    /// Around both ends of the term (±3 s) and at spans of 7 days ± 1 s, the mode is open exactly on [from, until) and
    /// only for a span of at most 7 days.
    func testTheModeIsOpenExactlyOnItsTerm() throws {  // G3
        let lock = try Lock(), from = try lock.at("2026-10-23T09:00:00+03:00"), dates = ISO8601DateFormatter()
        dates.timeZone = lock.zone
        for span in [ReleaseGate.longest - 1, ReleaseGate.longest, ReleaseGate.longest + 1] {
            let until = from.addingTimeInterval(span)
            let file = try lock.file(until: dates.string(from: until))
            for edge in [from, until] {
                for step in -3...3 {
                    let now = edge.addingTimeInterval(Double(step))
                    let open = try lock.access(file, now: dates.string(from: now)).until != nil
                    XCTAssertEqual(open, span <= ReleaseGate.longest && now >= from && now < until, "\(span) \(now)")
                }
            }
        }
    }

    func testAnUnsignedOrUnreadableExceptionOrNoKeyKeepsItClosed() throws {  // G4
        var lock = try Lock()
        // No `.sig`, another key, another namespace, a byte changed after signing: the check of G7 says «not signed».
        XCTAssertEqual(try lock.access(try lock.file(), signed: false), .parentOnly(["подпись исключения не сходится"]))
        XCTAssertEqual(try lock.access(Data("{не json".utf8)), .parentOnly(["исключение не читается"]))
        lock.build = ReleaseGate.Build(surface: fixtureSurface, key: false)
        XCTAssertEqual(try lock.access(try lock.file()), .parentOnly(["в сборке нет ключа родителя"]))
        XCTAssertEqual(try lock.access(nil), .parentOnly(["в сборке нет ключа родителя"]))
    }

    func testAnExceptionForAnotherBuildKeepsItClosed() throws {  // G5
        let lock = try Lock(), base = fixtureSurface
        let others = [("контракт", ReleaseSurface(contract: "fnv1a:test-contracT", router: base.router,
                                                  persona: base.persona, model: base.model)),
                      ("маршрутизатор", ReleaseSurface(contract: base.contract, router: "fnv1a:test-routeR",
                                                       persona: base.persona, model: base.model)),
                      ("персона", ReleaseSurface(contract: base.contract, router: base.router,
                                                 persona: "sha256:test-personA", model: base.model)),
                      ("модель", ReleaseSurface(contract: base.contract, router: base.router, persona: base.persona,
                                                model: "test.gguf:101"))]
        for (part, surface) in others {
            XCTAssertEqual(try lock.access(try lock.file(surface: surface)),
                           .parentOnly(["исключение подписано для другой сборки: " + part]), part)
        }
        let two = ReleaseSurface(contract: "fnv1a:test-contracT", router: base.router, persona: base.persona,
                                 model: "test.gguf:101")
        XCTAssertEqual(try lock.access(try lock.file(surface: two)),
                       .parentOnly(["исключение подписано для другой сборки: контракт, модель"]))
    }

    func testAFailedSelfTestKeepsItClosedWhateverTheException() throws {  // G6
        var lock = try Lock()
        lock.build = ReleaseGate.Build(surface: fixtureSurface, router: false)
        XCTAssertEqual(try lock.access(try lock.file()), .parentOnly(["маршрутизатор не прошёл самопроверку"]))
        lock.build = ReleaseGate.Build(surface: fixtureSurface, contract: false)
        XCTAssertEqual(try lock.access(try lock.file()), .parentOnly(["контракт не прошёл самопроверку"]))
    }
}
