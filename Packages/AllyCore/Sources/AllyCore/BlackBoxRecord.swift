import Foundation

/// One black box record: the trace record as it is, plus the words of both sides, the sound with sizes and hashes,
/// the timings and the wall time. The file `NNNN.allybox` is the header line and this JSON — sorted snake_case keys,
/// the words as UTF-8. The header lets the child-data gate know the file under any name.
struct BlackBoxRecord: Encodable {
    static let header = "ALLY-BLACKBOX/1\n"

    /// A sound file of the record, or the reason it is missing.
    struct Audio: Encodable {
        var file: String?, format: String?, rate: Int?, seconds: Double?, bytes: Int?, fnv1a: String?
        var missing: String?

        init(missing: String) { self.missing = missing }

        init(file: String, data: Data, format: String, seconds: Double, rate: Int? = nil) {
            (self.file, self.format, self.rate, self.seconds) = (file, format, rate, BlackBoxRecord.ms(seconds))
            (bytes, fnv1a) = (data.count, FNV1a.tag(data))
        }
    }

    /// Pauses and durations, s: her listening and speech, her speech end to the first sound, the voice, a stop.
    struct Timing: Encodable {
        var pauseBeforeSpeech, herSpeech, tail, recognize, speechEndToSound, ellySpeech, pauseAfterElly: Double?
        var interruptedAt: Double?
    }

    let trace: TurnTrace, words: TurnWords, at: String, sessionStarted: String
    let childAudio: Audio, ellyAudio: Audio, timing: Timing

    private enum Keys: String, CodingKey {
        case at, sessionStarted, heard, modelText, said, childAudio, ellyAudio, timing
    }

    /// The trace's own keys first, the black box's beside them in the same object.
    func encode(to encoder: Encoder) throws {
        try trace.encode(to: encoder)
        var box = encoder.container(keyedBy: Keys.self)
        try box.encode(at, forKey: .at)
        try box.encode(sessionStarted, forKey: .sessionStarted)
        try box.encodeIfPresent(words.heard, forKey: .heard)
        try box.encodeIfPresent(words.modelText, forKey: .modelText)
        try box.encodeIfPresent(words.said, forKey: .said)
        try box.encode(childAudio, forKey: .childAudio)
        try box.encode(ellyAudio, forKey: .ellyAudio)
        try box.encode(timing, forKey: .timing)
    }

    /// The file: the header line, the JSON line, one newline; nil only if encoding fails.
    func file() -> Data? { journalLine(self).map { Data((Self.header + $0 + "\n").utf8) } }

    /// A time to the millisecond, so a record reads 0.4 and not 0.40000000000000036.
    static func ms(_ seconds: Double) -> Double { (seconds * 1000).rounded() / 1000 }
}
