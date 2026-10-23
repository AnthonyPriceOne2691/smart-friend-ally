import Discipline
import Foundation

/// Who may talk on the child screen, and why not (R): with the parent present, by his signed exception, until its date.
/// Without him the lock stays closed: there is no path to that until the safety goals of 18.10 are accepted (R2).
public enum ChildAccess: Equatable, Sendable {
    case supervised(until: Date)
    case parentOnly([String])

    /// The end of the exception while the mode is open; nil when it is closed.
    public var until: Date? { if case .supervised(let until) = self { until } else { nil } }
}

/// What an exception is signed for: the discipline's data, the persona and the weights of the build on the phone.
public struct ReleaseSurface: Codable, Equatable, Sendable {
    public let contract, router, persona, model: String

    public init(contract: String, router: String, persona: String, model: String) {
        (self.contract, self.router, self.persona, self.model) = (contract, router, persona, model)
    }

    /// This build: the data hashes of the contract and the router from their records; the persona's sha256 and the
    /// weights' «file:bytes» from the app.
    public static func build(personaSHA256: String, model: String) -> ReleaseSurface {
        ReleaseSurface(contract: "fnv1a:" + TurnContract(mode: .talk).finish("").record.contractHash,
                       router: "fnv1a:" + Router.shared.route("").record.dataHash,
                       persona: "sha256:" + personaSHA256, model: model)
    }
}

/// A file as the app found it, and whether the parent's key signed exactly these bytes for the lock's namespace.
public struct SignedFile: Equatable, Sendable {
    public let bytes: Data, signed: Bool

    public init(bytes: Data, signed: Bool) { (self.bytes, self.signed) = (bytes, signed) }
}

/// The lock of the child screen (R): a pure function, closed on any doubt. The reasons go in the order of the spec —
/// the data self-tests, the parent's key in the build, the exception readable, its signature, its term, its surface.
public enum ReleaseGate {
    /// The build on the phone as the lock sees it: its surface, the data self-tests at load (one that fails keeps the
    /// lock closed whatever the exception says) and whether the parent's key is in the bundle.
    public struct Build: Equatable, Sendable {
        public let surface: ReleaseSurface, router: Bool, contract: Bool, key: Bool

        public init(surface: ReleaseSurface, router: Bool = true, contract: Bool = true, key: Bool = true) {
            (self.surface, self.router, self.contract, self.key) = (surface, router, contract, key)
        }

        public static func current(personaSHA256: String, model: String, key: Bool) -> Build {
            Build(surface: .build(personaSHA256: personaSHA256, model: model), router: RouterRouting.healthy,
                  contract: !TurnContract(mode: .talk).finish("").record.rules.contains("selftest_failed"), key: key)
        }
    }

    /// The longest exception: the free signature lives 7 days (E4), and so does one exception at most.
    public static let longest: TimeInterval = 7 * 86_400

    public static func access(exception: SignedFile?, build: Build, now: Date, zone: TimeZone) -> ChildAccess {
        let texts = ReleaseTexts.shared
        let broken = [(build.router, texts.parts.router), (build.contract, texts.parts.contract)]
            .filter { !$0.0 }.map { fill(texts.selftest, "part", $0.1) }
        guard broken.isEmpty else { return .parentOnly(broken) }
        guard build.key else { return .parentOnly([texts.noKey]) }
        guard let exception else { return .parentOnly([texts.none]) }
        guard let file = Exception.decode(exception.bytes) else { return .parentOnly([texts.unreadable]) }
        guard exception.signed else { return .parentOnly([texts.unsigned]) }
        return judge(file, surface: build.surface, now: now, zone: zone)
    }

    /// The console's lines of the lock: with the parent — open until the date or why not; without him — closed.
    public static func lines(_ access: ChildAccess, zone: TimeZone) -> [String] {
        let texts = ReleaseTexts.shared
        let line = switch access {
        case .supervised(let until): fill(texts.supervised, "when", when(until, zone: zone))
        case .parentOnly(let reasons): fill(texts.parentOnly, "reason", reasons.joined(separator: "; "))
        }
        return [line, texts.unsupervised]
    }

    /// «29.10 в 21:00» in the phone's time zone.
    public static func when(_ date: Date, zone: TimeZone) -> String {
        let formatter = DateFormatter()
        (formatter.locale, formatter.timeZone) = (Locale(identifier: "en_US_POSIX"), zone)
        let part = { (pattern: String) -> String in
            formatter.dateFormat = pattern
            return formatter.string(from: date)
        }
        return fill(fill(ReleaseTexts.shared.when, "day", part("dd.MM")), "time", part("HH:mm"))
    }

    /// The term and the surface of a signed exception: at most 7 days, from `from` up to but not including `until`,
    /// for this build only.
    static func judge(_ file: Exception, surface: ReleaseSurface, now: Date, zone: TimeZone) -> ChildAccess {
        let texts = ReleaseTexts.shared
        guard file.until.timeIntervalSince(file.from) <= longest else {
            return .parentOnly([fill(texts.tooLong, "days", "\(Int(longest / 86_400))")])
        }
        guard now >= file.from else { return .parentOnly([fill(texts.notYet, "when", when(file.from, zone: zone))]) }
        guard now < file.until else { return .parentOnly([fill(texts.expired, "when", when(file.until, zone: zone))]) }
        let other = [(\ReleaseSurface.contract, texts.parts.contract), (\.router, texts.parts.router),
                     (\.persona, texts.parts.persona), (\.model, texts.parts.model)]
            .filter { file.surface[keyPath: $0.0] != surface[keyPath: $0.0] }.map(\.1)
        return other.isEmpty ? .supervised(until: file.until)
            : .parentOnly([fill(texts.otherBuild, "parts", other.joined(separator: ", "))])
    }

    static func fill(_ template: String, _ key: String, _ value: String) -> String {
        template.replacingOccurrences(of: "{\(key)}", with: value)
    }
}

/// The exception's file: one JSON object signed by the parent's key — its term (ISO 8601 with an offset), its surface
/// and a note.
struct Exception: Decodable, Sendable {
    let from, until: Date, surface: ReleaseSurface

    static func decode(_ bytes: Data) -> Exception? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Exception.self, from: bytes)
    }
}

/// `release.json`: the lock's reasons and console lines, one copy.
struct ReleaseTexts: Decodable, Sendable {
    struct Parts: Decodable, Sendable { let contract, router, persona, model: String }

    let selftest, noKey, none, unreadable, unsigned, tooLong, notYet, expired, otherBuild: String
    let parts: Parts, when, supervised, parentOnly, unsupervised: String

    static let shared: ReleaseTexts = {
        guard let url = Bundle.module.url(forResource: "release", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("AllyCore: release.json is unreadable") }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(ReleaseTexts.self, from: bytes)
        } catch {
            fatalError("AllyCore: release.json does not decode: \(error)")
        }
    }()
}
