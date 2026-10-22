import Foundation

/// The black box: the words and the sound of both sides for every turn of a session with the parent by (`audience:
/// supervised`), on the phone only. A sink beside the trace — one record per trace record. A turn's sound is written
/// first and its record last; a failed write takes the turn's files back and is counted, never thrown — the session
/// goes on. Past the limit the sound is not kept, the record is.
public final class BlackBox: TraceSink, @unchecked Sendable {
    public struct Settings: Sendable {
        public let limitBytes: Int, warnShare: Double

        public init(limitBytes: Int = 1 << 30, warnShare: Double = 0.8) {
            (self.limitBytes, self.warnShare) = (limitBytes, warnShare)
        }
    }

    /// What «erase all» did: how many sessions and bytes went, or nothing — a session with the parent by is on.
    public enum Erase: Equatable, Sendable {
        case erased(sessions: Int, bytes: Int), busy
    }

    private struct State {
        var pending: Utterance?, session = "", folder = "", started = "", total = 0, lost = 0, open = false
        var lastWrite: Double?, erased: (sessions: Int, bytes: Int)?
    }

    private struct Turn {
        let trace: TurnTrace, words: TurnWords, utterance: Utterance?, voice: RecordedVoice?
    }

    private struct EncodingFailed: Error {}

    private let disk: BlackBoxDisk, tape: VoiceTape?, clock: TurnClock, wall: @Sendable () -> Date
    private let settings: Settings, state = Locked(State())

    public init(disk: BlackBoxDisk, tape: VoiceTape? = nil, clock: TurnClock = SystemClock(),
                wall: @escaping @Sendable () -> Date = { Date() }, settings: Settings = Settings()) {
        (self.disk, self.tape, self.clock, self.wall, self.settings) = (disk, tape, clock, wall, settings)
        let held = (try? disk.files().values.reduce(0, +)) ?? 0
        state { $0.total = held }
    }

    /// Her utterance as the recognizer got it, given before the session hears its text: the next record with her
    /// words takes it; one not taken is replaced by the next.
    public func heard(_ utterance: Utterance) { state { $0.pending = utterance } }

    public func write(_ trace: TurnTrace) { write(trace, words: TurnWords()) }

    public func write(_ trace: TurnTrace, words: TurnWords) {
        let voice = tape?.take()
        let utterance = state { (s: inout State) -> Utterance? in
            defer { if words.heard != nil { s.pending = nil } }
            return words.heard == nil ? nil : s.pending
        }
        guard trace.audience == Audience.supervised.rawValue, disk.isPrivate else { return }
        do {
            try enter(trace, words: words)
            try keep(Turn(trace: trace, words: words, utterance: utterance, voice: voice))
        } catch {
            state { $0.lost += 1 }
        }
    }

    /// Erases every session, never while a session with the parent by is on; the answer says what went (П22).
    public func eraseAll() throws -> Erase {
        guard !state({ $0.open }) else { return .busy }
        let files = try disk.files()
        let folders = Set(files.keys.compactMap { $0.split(separator: "/").first.map(String.init) })
        for folder in folders.sorted() { try disk.remove(folder) }
        let bytes = files.values.reduce(0, +)
        state { (s: inout State) in (s.total, s.session, s.erased) = (0, "", (folders.count, bytes)) }
        return .erased(sessions: folders.count, bytes: bytes)
    }

    /// The console line: off in the parent's console, recording with the room left, full, a folder in the backup;
    /// turns not kept; what an erase removed.
    public var status: String {
        let now = state { $0 }, used = Self.mb(now.total), room = Self.mb(settings.limitBytes)
        let lost = now.lost > 0 ? " · не записано ходов: \(now.lost)" : ""
        if let erased = now.erased {
            let sessions = erased.sessions, freed = Self.mb(erased.bytes)
            return "стёрто: \(sessions) сес., \(freed) МБ" + lost
        }
        guard disk.isPrivate else { return "не пишу: каталог в бэкапе" + lost }
        guard now.open else { return "запись выключена" + (now.total > 0 ? " · \(used) МБ" : "") + lost }
        guard now.total < settings.limitBytes else { return "● ящик полон: выгрузи и сотри" + lost }
        let warn = Double(now.total) >= settings.warnShare * Double(settings.limitBytes) ? " — выгрузи на Mac" : ""
        return "● запись: \(used) из \(room) МБ" + warn + lost
    }

    /// A session's first record opens its folder, named by its start on the wall clock; the size is read from the
    /// disk then, so the room the Mac erased is free at once.
    private func enter(_ trace: TurnTrace, words: TurnWords) throws {
        if state({ $0.session != trace.session }) {
            let held = try disk.files().values.reduce(0, +)
            let started = Self.iso(wall().addingTimeInterval(-words.elapsed))
            let folder = started.replacingOccurrences(of: ":", with: "-") + "-" + trace.session.prefix(8)
            state { (s: inout State) in
                (s.session, s.folder, s.started, s.total) = (trace.session, folder, started, held)
                (s.lastWrite, s.erased) = (nil, nil)
            }
        }
        state { $0.open = trace.end == nil }
    }

    /// A turn's files: her sound, the voice's, the record last; past the limit no sound, the record still.
    private func keep(_ turn: Turn) throws {
        let now = state { $0 }, number = String(format: "%04d", turn.trace.turn)
        let child = turn.utterance.flatMap { $0.samples.isEmpty ? nil : Wav.file($0.samples, rate: $0.rate) }
        let fits = now.total + (child?.count ?? 0) + (turn.voice?.data.count ?? 0) <= settings.limitBytes
        var files: [(name: String, data: Data)] = []
        var childAudio = BlackBoxRecord.Audio(missing: childMissing(turn, fits: fits))
        if let child, let heard = turn.utterance, fits {
            files.append((number + "-child.wav", child))
            childAudio = .init(file: number + "-child.wav", data: child, format: "wav-pcm16-mono",
                               seconds: Double(heard.samples.count) / Double(heard.rate), rate: heard.rate)
        }
        var ellyAudio = BlackBoxRecord.Audio(missing: turn.voice == nil ? "not_recorded" : "full")
        if let voice = turn.voice, fits {
            files.append((number + "-elly.m4a", voice.data))
            ellyAudio = .init(file: number + "-elly.m4a", data: voice.data, format: voice.format,
                              seconds: voice.seconds)
        }
        let record = BlackBoxRecord(trace: turn.trace, words: turn.words, at: Self.iso(wall()),
                                    sessionStarted: now.started, childAudio: childAudio, ellyAudio: ellyAudio,
                                    timing: timing(turn, lastWrite: now.lastWrite))
        guard let data = record.file() else { throw EncodingFailed() }
        files.append((number + ".allybox", data))
        try write(files, into: now.folder)
        let added = files.reduce(0) { $0 + $1.data.count }, written = clock.now()
        state { (s: inout State) in (s.total, s.lastWrite) = (s.total + added, written) }
    }

    /// Writes the files in order; a failure removes what this turn wrote and is passed on.
    private func write(_ files: [(name: String, data: Data)], into folder: String) throws {
        var done: [String] = []
        do {
            for file in files {
                try disk.write(file.data, to: folder + "/" + file.name)
                done.append(folder + "/" + file.name)
            }
        } catch {
            done.forEach { try? disk.remove($0) }
            throw error
        }
    }

    /// Why her sound is not in the record: no utterance in this turn, a listening without speech (a miss on
    /// silence), an utterance without samples, or the limit.
    private func childMissing(_ turn: Turn, fits: Bool) -> String {
        guard turn.words.heard != nil else {
            return ["session:misheard", "session:rest"].contains(turn.trace.source) ? "silence" : "no_utterance"
        }
        guard let utterance = turn.utterance, !utterance.samples.isEmpty else { return "no_audio" }
        return fits ? "" : "full"
    }

    private func timing(_ turn: Turn, lastWrite: Double?) -> BlackBoxRecord.Timing {
        var timing = BlackBoxRecord.Timing()
        timing.ellySpeech = turn.voice.map { BlackBoxRecord.ms($0.seconds) }
        timing.interruptedAt = turn.trace.cancelled ? BlackBoxRecord.ms(turn.words.elapsed) : nil
        guard let heard = turn.utterance else { return timing }
        let voiced = heard.voiced, ended = heard.ended, sound = turn.trace.stages["first_sound"]
        timing.pauseBeforeSpeech = voiced.map { BlackBoxRecord.ms($0 - heard.opened) }
        timing.herSpeech = ended.flatMap { end in voiced.map { BlackBoxRecord.ms(end - $0) } }
        timing.tail = ended.map { BlackBoxRecord.ms(heard.closed - $0) }
        timing.recognize = BlackBoxRecord.ms(heard.known - heard.closed)
        timing.speechEndToSound = ended.flatMap { end in sound.map { BlackBoxRecord.ms(heard.known - end + $0) } }
        timing.pauseAfterElly = lastWrite.map { BlackBoxRecord.ms(heard.opened - $0) }
        return timing
    }

    private static func iso(_ date: Date) -> String { ISO8601DateFormatter().string(from: date) }

    private static func mb(_ bytes: Int) -> Int { Int((Double(bytes) / 1_048_576).rounded()) }
}
