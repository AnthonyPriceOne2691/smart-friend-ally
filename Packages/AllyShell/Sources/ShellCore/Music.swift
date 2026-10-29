import AllyCore
import Foundation

/// The parent's line for the music, `music.json` (background-music, 2026-10-29; no settings screen — «Пока не делаем»):
/// on or off, the idle volume, how far it goes down while Ellie talks, and three times. A missing key takes its
/// standard; a value out of its range or not a number takes the standard and a console line (Y9).
public struct MusicLine: Equatable, Sendable {
    public static let standard = MusicLine(on: true, volume: 0.8, duckDB: -20, fadeOut: 0.4, delay: 2, fadeIn: 3)

    public let on: Bool, volume: Double, duckDB: Double, fadeOut: Double, delay: Double, fadeIn: Double
    /// Console lines for the values refused.
    public private(set) var notes: [String] = []

    /// The level while Ellie talks — «еле слышно»: the volume `duck_db` lower.
    public var quiet: Double { volume * pow(10, duckDB / 20) }

    public static func decode(_ data: Data) -> MusicLine {
        guard let raw = try? JSONDecoder().decode(Raw.self, from: data) else {
            var line = standard
            line.notes = ["музыка: music.json не читается"]
            return line
        }
        var notes = raw.on == nil && raw.onWritten ? ["музыка: on не true/false — взято true"] : []
        func take(_ key: Key, _ range: ClosedRange<Double>, _ fallback: Double) -> Double {
            guard let found = raw.numbers[key] else { return fallback }
            if let value = found, range.contains(value) { return value }
            notes.append("музыка: " + key.word + " вне " + key.range + " — взято " + decimal(fallback))
            return fallback
        }
        let s = standard
        var line = MusicLine(on: raw.on ?? s.on, volume: take(.volume, 0...1, s.volume),
                             duckDB: take(.duckDB, -60...0, s.duckDB), fadeOut: take(.fadeOut, 0...5, s.fadeOut),
                             delay: take(.delay, 0...60, s.delay), fadeIn: take(.fadeIn, 0...30, s.fadeIn))
        line.notes = notes
        return line
    }

    /// The console's line of the music at warm-up.
    public var console: String {
        guard on, volume > 0 else { return "музыка: выключена" }
        return "музыка: «Шкатулка Элли» · " + Self.decimal(volume) + " · " + Self.decimal(duckDB) + " дБ"
    }

    private static func decimal(_ value: Double) -> String {
        String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
    }

    enum Key: String, CodingKey, CaseIterable {
        case on, volume, duckDB = "duck_db", fadeOut = "fade_out", delay, fadeIn = "fade_in"

        var word: String {
            ["volume": "громкость", "duck_db": "приглушение", "fade_out": "уход", "delay": "ожидание",
             "fade_in": "возврат"][rawValue] ?? rawValue
        }

        var range: String {
            ["volume": "0–1", "duck_db": "−60–0 дБ", "fade_out": "0–5 с", "delay": "0–60 с", "fade_in": "0–30 с"][
                rawValue] ?? ""
        }
    }

    /// The JSON as written: a number per key, nil inside when the key is there but no number.
    private struct Raw: Decodable {
        var on: Bool?, onWritten = false, numbers: [Key: Double?] = [:]

        init(from decoder: Decoder) throws {
            let keyed = try decoder.container(keyedBy: Key.self)
            (on, onWritten) = (try? keyed.decodeIfPresent(Bool.self, forKey: .on), keyed.contains(.on))
            for key in Key.allCases where key != .on && keyed.contains(key) {
                numbers.updateValue(try? keyed.decode(Double.self, forKey: key), forKey: key)  // nil inside: no number
            }
        }
    }
}

/// Where the music goes (Y1–Y8): off, quiet under a talk, full while Ellie idles. «Пока Элли спит и ждет… довольно
/// так ощутимо играет. При тапе… затихает, именно, не выключается, пока Элли слушает, думает и говорит» (the parent,
/// 2026-10-29). Quiet only where the voice's engine takes the music out of the microphone; without it (Milena) — off.
public enum MusicCue: Equatable, Sendable {
    case off, quiet, full

    /// What the app knows: the child screen is shown, the app is in front, the warm-up set the audio session, a wake is
    /// on its way, the shown session's phase, and whether the voice's engine cancels its echo.
    public struct Scene: Equatable, Sendable {
        public var child = false, front = true, ready = false, waking = false, cancelsEcho = true
        public var phase = SessionState.asleep

        public init() {}
    }

    public static func of(_ scene: Scene, line: MusicLine) -> MusicCue {
        guard line.on, line.volume > 0, scene.child, scene.front, scene.ready else { return .off }
        guard scene.waking || scene.phase != .asleep else { return .full }
        return scene.cancelsEcho ? .quiet : .off
    }
}

/// The music's level in time (Y1, Y2, Y4, Y5): down to its cue in `fade_out`, up to full after `delay` in `fade_in`,
/// from wherever the level is; up to quiet — at once (a tap before the music rose: the node takes the quiet level);
/// the same level — no way at all.
public struct MusicFader: Equatable, Sendable {
    /// A way of the level: `from` until `start`, then straight to `to` in `length` seconds.
    public struct Ramp: Equatable, Sendable {
        public let from: Double, to: Double, start: Double, length: Double
    }

    public private(set) var ramp = Ramp(from: 0, to: 0, start: 0, length: 0)

    public init() {}

    public func level(at time: Double) -> Double {
        guard time > ramp.start else { return ramp.from }
        guard ramp.length > 0, time < end else { return ramp.to }
        return ramp.from + (ramp.to - ramp.from) * (time - ramp.start) / ramp.length
    }

    /// When the level gets where it goes: a tap opens the microphone after it (Y2).
    public var end: Double { ramp.start + ramp.length }

    /// A cue at `time`: the new way, nil when the level already goes there.
    public mutating func cue(_ cue: MusicCue, line: MusicLine, at time: Double) -> Ramp? {
        let target = cue == .full ? line.volume : cue == .quiet ? line.quiet : 0
        guard target != ramp.to else { return nil }
        let now = level(at: time)
        let rises = target > now && cue == .full
        ramp = Ramp(from: now, to: target, start: rises ? time + line.delay : time,
                    length: rises ? line.fadeIn : target < now ? line.fadeOut : 0)
        return ramp
    }
}
