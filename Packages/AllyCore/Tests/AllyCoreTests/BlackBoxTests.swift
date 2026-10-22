@testable import AllyCore
import Discipline
import XCTest

/// 2026-10-25T18:03:12Z — the wall clock at the first `wake`; it moves with the virtual clock.
private let wakeTime = Date(timeIntervalSince1970: 1_792_951_392)
private let rest = ["Что-то я тебя не слышу.", "Я немножко посплю.", "Нажми на меня, когда захочешь поболтать!"]
private let matches = ["Спички и зажигалку сама не бери: можно обжечься или устроить пожар.",
                       "Зажечь свечку попроси маму или папу."]
private let scriptRoutes = ["Дай мне спички": Route(.script(key: "matches"), rules: ["matches.ask"],
                                                    dataHash: "fnv1a:test")]

/// A record as the Mac reads it back from `NNNN.allybox`.
struct Kept: Decodable {
    struct Audio: Decodable {
        let file: String?, format: String?, rate: Int?, seconds: Double?, bytes: Int?, fnv1a: String?, missing: String?
    }
    struct Timing: Decodable {
        let pauseBeforeSpeech, herSpeech, tail, recognize, speechEndToSound, ellySpeech, pauseAfterElly: Double?
        let interruptedAt: Double?
    }
    struct Decision: Decodable { let kind: String, key: String?, topic: String? }
    let session: String, turn: Int, source: String, rules: [String], cancelled: Bool, end: String?, audience: String
    let heard: String?, modelText: String?, said: [String]?, route: Decision?, versions: [String: String]
    let childAudio: Audio, ellyAudio: Audio, timing: Timing, at: String, sessionStarted: String
}

/// A session over doubles with the trace and the black box behind one fan-out; `after` — the next session on the same
/// clock, disk and box.
struct BoxRig {
    let clock: TestClock, trace: RecordingSink, voice: RecordingVoice, disk: MemoryDisk, box: BlackBox
    let queue: ReplyQueue?, session: Session

    init(replies: [String] = [], think: Double = 0, routes: [String: Route] = [:], audience: Audience = .supervised,
         disk: MemoryDisk = MemoryDisk(), tape: [RecordedVoice] = [], hold: Bool = false, after: BoxRig? = nil) {
        let clock = after?.clock ?? TestClock(), disk = after?.disk ?? disk, trace = RecordingSink()
        let box = after?.box ?? BlackBox(disk: disk, tape: QueueTape(tape), clock: clock,
                                         wall: { wakeTime.addingTimeInterval(clock.now()) })
        let queue = think > 0 ? nil : ReplyQueue(replies), voice = RecordingVoice(hold: hold, from: greeting.count)
        let model: LanguageModel = queue ?? TimedReply(replies.first ?? "", after: think, clock: clock)
        let stamp = TraceStamp(versions: ["voice": "com.apple.voice.enhanced.ru-RU.Milena", "voice_rate": "0.42"])
        let parts = SessionParts(model: model, voice: voice, sink: TraceFanOut([trace, box]), clock: clock,
                                 router: TableRouter(table: routes), audience: audience, stamp: { stamp })
        (self.clock, self.trace, self.voice, self.disk, self.box, self.queue) = (clock, trace, voice, disk, box, queue)
        session = Session(parts)
    }

    /// Her utterance reaches the box when its text is known, then the session hears the text.
    func say(_ text: String, _ utterance: Utterance?) async {
        if let utterance {
            clock.advance(to: utterance.known)
            box.heard(utterance)
        }
        await session.handle(.heard(text))
    }

    /// How many trace lines there are, all without a Cyrillic letter (K9); -1 if one has a word.
    var wordlessTrace: Int {
        let lines = trace.records.compactMap { $0.jsonLine() }
        return lines.allSatisfy { $0.range(of: "[А-Яа-яЁё]", options: .regularExpression) == nil } ? lines.count : -1
    }

    /// The records this box wrote and still holds, in the order written.
    func kept() throws -> [Kept] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try disk.order.filter { $0.hasSuffix(".allybox") }.compactMap { disk.data($0) }.map { data in
            let lines = (String(bytes: data, encoding: .utf8) ?? "").split(separator: "\n")
            XCTAssertEqual(lines.first, "ALLY-BLACKBOX/1")
            return try decoder.decode(Kept.self, from: Data(lines[1].utf8))
        }
    }
}

/// Her utterance: `seconds` of a fixed PCM16 pattern at 16 kHz, heard at `known`; the listening before it — 0.2 s to
/// her speech, the speech, a tail of 0.8 s, recognition 0.15 s.
func heard(_ seconds: Double, at known: Double, samples: Int? = nil) -> Utterance {
    let count = samples ?? Int(seconds * 16_000), closed = known - 0.15, ended = closed - 0.8
    return Utterance(samples: (0..<count).map { Int16(truncatingIfNeeded: $0 &* 37) }, rate: 16_000,
                     opened: ended - seconds - 0.2, voiced: ended - seconds, ended: ended, closed: closed, known: known)
}

/// What the voice sounded: AAC at 32 kbit/s is 4000 bytes a second.
func sounded(_ seconds: Double) -> RecordedVoice {
    RecordedVoice(data: Data([0, 0, 0, 24] + Array("ftypM4A ".utf8)) + Data(count: Int(seconds * 4000)),
                  seconds: seconds, format: "aac-lc-32k-mono")
}

final class BlackBoxTests: XCTestCase {
    func testTurnKeepsBothSidesWordsSoundAndTimings() async throws {  // B1
        let rig = BoxRig(replies: ["Ух ты, в зоопарке! А кого ты там видела?"], think: 0.5,
                         tape: [sounded(3.0), sounded(3.1)])
        await rig.session.handle(.wake)
        let her = Utterance(samples: heard(1.5, at: 0).samples, rate: 16_000, opened: 10, voiced: 10.4, ended: 11.9,
                            closed: 12.7, known: 12.85)
        await rig.say("Я сегодня была в зоопарке", her)
        let folder = try "2026-10-25T18-03-12Z-" + XCTUnwrap(rig.trace.records.first?.session).prefix(8) + "/"
        let names = ["0001-elly.m4a", "0001.allybox", "0002-child.wav", "0002-elly.m4a", "0002.allybox"]
        XCTAssertEqual(rig.disk.paths, names.map { folder + $0 })
        XCTAssertEqual(Array(rig.disk.order.suffix(3)), names.suffix(3).map { folder + $0 })
        let kept = try rig.kept(), turn = kept[1]
        XCTAssertEqual(turn.heard, "Я сегодня была в зоопарке")
        XCTAssertEqual(turn.modelText, "Ух ты, в зоопарке! А кого ты там видела?")
        XCTAssertEqual(turn.said, ["Ух ты, в зоопарке!", "А кого ты там видела?"])
        XCTAssertEqual([turn.rules, [turn.source, turn.route?.kind ?? "", turn.audience]], [[], ["model", "pass",
                                                                                                "supervised"]])
        let wav = try XCTUnwrap(rig.disk.data(folder + "0002-child.wav"))
        XCTAssertEqual([turn.childAudio.bytes, turn.childAudio.rate, turn.ellyAudio.bytes],
                       [48_044, 16_000, sounded(3.1).data.count])
        XCTAssertEqual([turn.childAudio.seconds, turn.ellyAudio.seconds], [1.5, 3.1])
        XCTAssertEqual(turn.childAudio.fnv1a, FNV1a.tag(wav))
        let time = turn.timing
        XCTAssertEqual([time.pauseBeforeSpeech, time.herSpeech, time.tail, time.recognize, time.speechEndToSound,
                        time.ellySpeech], [0.4, 1.5, 0.8, 0.15, 1.45, 3.1])
        XCTAssertEqual(turn.versions["voice_rate"], "0.42")
        XCTAssertEqual(turn.sessionStarted, "2026-10-25T18:03:12Z")
        XCTAssertEqual([kept[0].heard, kept[0].childAudio.missing], [nil, "no_utterance"])
        XCTAssertEqual(kept[0].said, greeting)
        XCTAssertEqual(kept[0].ellyAudio.seconds, 3.0)
        XCTAssertEqual(rig.wordlessTrace, 2)
    }

    func testRecordShowsWhatTheContractChanged() async throws {  // B2
        let cases = [["Моя хорошая, жираф — самый высокий зверь! А ты его видела?", "model", "endearment",
                      "Жираф — самый высокий зверь!", "А ты его видела?"],
                     ["Солнышко, я буду ждать тебя завтра!", "canned:attachment", "endearment attachment",
                      "Мне с тобой весело!", "А теперь беги поиграй с мамой или папой."]]
        for line in cases {
            let rig = BoxRig(replies: [line[0]])
            await rig.session.handle(.wake)
            await rig.say("Расскажи про жирафа", heard(1.0, at: 6))
            let turn = try XCTUnwrap(rig.kept().last)
            XCTAssertEqual(turn.modelText, line[0])
            XCTAssertEqual(turn.source, line[1])
            XCTAssertEqual(turn.rules, line[2].split(separator: " ").map(String.init))
            XCTAssertEqual(turn.said, Array(line[3...]))
        }
    }

    func testScriptRecordHasNoModelText() async throws {  // B3
        let rig = BoxRig(replies: ["Не звучит."], routes: scriptRoutes, tape: [sounded(3.0), sounded(5.2)])
        await rig.session.handle(.wake)
        await rig.say("Дай мне спички", heard(1.1, at: 7.2))
        XCTAssertEqual(rig.queue?.calls, 0)
        let turn = try XCTUnwrap(rig.kept().last)
        XCTAssertNil(turn.modelText)
        XCTAssertEqual(turn.said, matches)
        XCTAssertEqual([turn.route?.kind, turn.route?.key, turn.route?.topic], ["script", "matches", "matches"])
        XCTAssertEqual([turn.childAudio.file, turn.ellyAudio.file], ["0002-child.wav", "0002-elly.m4a"])
    }

    func testMissKeepsHerSoundSilenceKeepsNone() async throws {  // B4
        let rig = BoxRig()
        await rig.session.handle(.wake)
        await rig.say("", heard(1.2, at: 7.4))
        await rig.session.handle(.silence)
        let kept = try rig.kept()
        XCTAssertEqual(kept.map(\.source), ["session:greeting", "session:misheard", "session:rest"])
        XCTAssertEqual(kept[1].heard, "")
        XCTAssertEqual(kept[1].said, [misheard])
        XCTAssertEqual(kept[1].childAudio.seconds, 1.2)
        XCTAssertNil(kept[2].heard)
        XCTAssertEqual(kept[2].childAudio.missing, "silence")
        XCTAssertEqual(kept[2].said, rest)
        XCTAssertEqual(kept[2].end, "rest")
    }

    func testStopKeepsTheCutVoiceAndTheMoment() async throws {  // B5
        let rig = BoxRig(replies: ["Привет! Как дела?"], tape: [sounded(3.0), sounded(0.7)], hold: true)
        await rig.session.handle(.wake)
        rig.clock.advance(to: 8)
        rig.box.heard(heard(0.8, at: 8))
        let turn = Task { await rig.session.handle(.heard("Привет")) }
        await eventually { rig.voice.sentences.count == greeting.count + 1 }
        rig.clock.advance(to: 20)
        await rig.session.handle(.stop)
        await turn.value
        let cut = try XCTUnwrap(rig.kept().last)
        XCTAssertTrue(cut.cancelled)
        XCTAssertEqual(cut.end, "parent")
        XCTAssertNil(cut.said)
        XCTAssertNil(cut.modelText)
        XCTAssertEqual([cut.ellyAudio.seconds, cut.timing.interruptedAt, cut.childAudio.seconds], [0.7, 20, 0.8])
    }

    func testParentSessionLeavesNoFiles() async throws {  // B6
        let rig = BoxRig(replies: ["Ага.", "Ого!"], audience: .parent, tape: (0..<4).map { _ in sounded(1) })
        await rig.session.handle(.wake)
        await rig.say("Раз", heard(1, at: 10))
        await rig.say("Два", heard(1, at: 20))
        await rig.say("Пока!", nil)
        XCTAssertTrue(rig.disk.paths.isEmpty)
        XCTAssertEqual(rig.trace.records.count, 4)
        XCTAssertEqual(rig.trace.records.map(\.audience), Array(repeating: "parent", count: 4))
        XCTAssertEqual(rig.box.status, "запись выключена")
        let next = BoxRig(replies: ["Ура!"], after: rig)
        await next.session.handle(.wake)
        await next.say("Привет", heard(1, at: 40))
        await next.say("Пока!", nil)
        XCTAssertEqual(try next.kept().map(\.turn), [1, 2, 3])
        XCTAssertEqual(try next.kept().map(\.audience), Array(repeating: "supervised", count: 3))
    }

    func testLimitStopsTheSoundNotTheRecord() async throws {  // B7
        let mib = 1 << 20, old = "2026-10-24T10-00-00Z-0A1B2C3D/0001.allybox"
        let tape = [sounded(1), sounded(1)]
        let near = BoxRig(replies: ["Ага."], disk: MemoryDisk(preload: [old: 820 * mib]), tape: tape)
        await near.session.handle(.wake)
        await near.say("Раз", heard(1, at: 10))
        XCTAssertEqual(try near.kept().last?.childAudio.file, "0002-child.wav")
        XCTAssertEqual(near.box.status, "● запись: 820 из 1024 МБ — выгрузи на Mac")
        let full = BoxRig(replies: ["Ага."], disk: MemoryDisk(preload: [old: 1024 * mib]), tape: tape)
        await full.session.handle(.wake)
        await full.say("Раз", heard(1, at: 10))
        let turn = try XCTUnwrap(full.kept().last)
        XCTAssertEqual([turn.childAudio.missing, turn.ellyAudio.missing, turn.heard], ["full", "full", "Раз"])
        XCTAssertEqual(full.box.status, "● ящик полон: выгрузи и сотри")
        await full.say("Пока!", nil)
        let held = try full.disk.files().values.reduce(0, +)
        XCTAssertEqual(try full.box.eraseAll(), .erased(sessions: 2, bytes: held))
        let again = BoxRig(replies: ["Ага."], after: full)
        await again.session.handle(.wake)
        await again.say("Раз", heard(1, at: 50))
        XCTAssertEqual(try again.kept().last?.childAudio.file, "0002-child.wav")
    }

    func testFailedWriteTakesTheTurnBackAndCounts() async throws {  // B8
        let tape = (0..<3).map { _ in sounded(1) }
        let rig = BoxRig(replies: ["Ага.", "Ого!"], disk: MemoryDisk(failOn: "/0002.allybox"), tape: tape)
        await rig.session.handle(.wake)
        await rig.say("Раз", heard(1, at: 10))
        XCTAssertEqual(Array(rig.voice.sentences.dropFirst(greeting.count)), ["Ага."])
        XCTAssertFalse(rig.disk.paths.contains { $0.contains("/0002") })
        XCTAssertTrue(rig.box.status.hasSuffix(" · не записано ходов: 1"), rig.box.status)
        await rig.say("Два", heard(1, at: 20))
        XCTAssertEqual(rig.disk.paths.filter { $0.contains("/0003") }.count, 3)
        let open = BoxRig(replies: ["Ага."], disk: MemoryDisk(isPrivate: false), tape: tape)
        await open.session.handle(.wake)
        await open.say("Раз", heard(1, at: 10))
        XCTAssertTrue(open.disk.paths.isEmpty)
        XCTAssertEqual(open.box.status, "не пишу: каталог в бэкапе")
    }

    func testEraseAllSaysWhatWentAndWaitsForTheSession() async throws {  // B9
        let mib = 1 << 20
        let old = ["A/0001.allybox": 10 * mib, "B/0001.allybox": 15 * mib, "C/0001.allybox": 16 * mib]
        let rig = BoxRig(disk: MemoryDisk(preload: old))
        XCTAssertEqual(try rig.box.eraseAll(), .erased(sessions: 3, bytes: 41 * mib))
        XCTAssertTrue(rig.disk.paths.isEmpty)
        XCTAssertEqual(rig.box.status, "стёрто: 3 сес., 41 МБ")
        let busy = BoxRig(disk: MemoryDisk(preload: old))
        await busy.session.handle(.wake)
        XCTAssertEqual(try busy.box.eraseAll(), .busy)
        XCTAssertEqual(busy.disk.paths.count, 4)
    }

    func testOneRecordPerTraceRecordThroughTheRealSession() async throws {  // B10
        let rig = BoxRig(replies: ["Какая пушистая Мурка!", "Красивое имя!", "Рыжая — это здорово!"],
                         routes: scriptRoutes)
        await rig.session.handle(.wake)
        await rig.say("Я нарисовала Мурку", heard(1.2, at: 8))
        await rig.say("Дай мне спички", heard(1.0, at: 18))
        rig.clock.advance(to: 30)
        await rig.session.handle(.silence)
        await rig.say("Её зовут Мурка", heard(1.1, at: 40))
        await rig.say("Она рыжая", heard(0.9, at: 605))
        let kept = try rig.kept()
        XCTAssertEqual(kept.map(\.turn), Array(1...7))
        XCTAssertEqual(Set(kept.map(\.session)).count, 1)
        XCTAssertEqual(kept.map { $0.heard != nil }, [false, true, true, false, true, true, false])
        XCTAssertEqual(kept.map { $0.modelText != nil }, [false, true, false, false, true, true, false])
        XCTAssertEqual(kept.map { $0.childAudio.file != nil }, [false, true, true, false, true, true, false])
        XCTAssertEqual(kept[3].childAudio.missing, "silence")
        XCTAssertEqual(kept.map(\.end), [nil, nil, nil, nil, nil, nil, "limit"])
        XCTAssertEqual(rig.wordlessTrace, 7)
    }

    /// On seeded random sessions, the black box keeps exactly the trace's records, the numbers matching.
    func testRecordsMatchTheTraceOnSeededSessions() async throws {  // B10
        var random = SplitMix(seed: 7)
        for _ in 0..<20 {
            let rig = BoxRig(replies: ["Ага."], routes: scriptRoutes)
            await rig.session.handle(.wake)
            var time = 0.0
            for _ in 0..<12 where rig.session.state != .asleep {
                time += 2 + Double(random.next() % 90)
                switch random.next() % 4 {
                case 0: await rig.say("Раз", heard(1, at: time))
                case 1: await rig.say("", heard(1, at: time))
                case 2:
                    rig.clock.advance(to: time)
                    await rig.session.handle(.silence)
                default: await rig.say("Дай мне спички", heard(1, at: time))
                }
            }
            XCTAssertEqual(try rig.kept().map(\.turn), rig.trace.records.map(\.turn))
        }
    }

    func testFormatsWavRecordAndHash() async throws {  // B12
        let samples: [Int16] = [0, 1, -1, .min, .max] + heard(0, at: 0, samples: 23_995).samples
        let wav = Wav.file(samples, rate: 16_000)
        XCTAssertEqual(wav.count, 48_044)
        XCTAssertEqual(String(bytes: wav[0..<4] + wav[8..<16], encoding: .ascii), "RIFFWAVEfmt ")
        XCTAssertEqual([wav.le32(4), wav.le32(16), wav.le32(24), wav.le32(28), wav.le32(40)],
                       [36 + 48_000, 16, 16_000, 32_000, 48_000])
        XCTAssertEqual([wav.le16(20), wav.le16(22), wav.le16(32), wav.le16(34)], [1, 1, 2, 16])
        XCTAssertEqual(String(bytes: wav[36..<40], encoding: .ascii), "data")
        XCTAssertEqual(readBack(wav), samples)
        XCTAssertEqual(FNV1a.tag(Data()), "fnv1a:cbf29ce484222325")
        XCTAssertEqual(FNV1a.tag(Data("a".utf8)), "fnv1a:af63dc4c8601ec8c")
        let rig = BoxRig(replies: ["Привет, привет!"])
        await rig.session.handle(.wake)
        await rig.say("Привет", heard(0, at: 5))
        XCTAssertEqual(try rig.kept().last?.childAudio.missing, "no_audio")
        XCTAssertFalse(rig.disk.paths.contains { $0.hasSuffix(".wav") })
        let file = try XCTUnwrap(rig.disk.order.last.flatMap { rig.disk.data($0) })
        let text = try XCTUnwrap(String(bytes: file, encoding: .utf8))
        XCTAssertTrue(text.hasPrefix("ALLY-BLACKBOX/1\n{") && text.hasSuffix("}\n"))
        XCTAssertTrue(text.contains("\"heard\":\"Привет\"") && !text.contains("\\u"))
        let keys = ["at", "audience", "cancelled", "child_audio", "contract_hash", "heard"].map { "\"\($0)\":" }
        let places = keys.compactMap { text.range(of: $0)?.lowerBound }
        XCTAssertEqual(places, places.sorted())
        XCTAssertEqual(places.count, keys.count)
        var random = SplitMix(seed: 42)  // any samples of any length read back bit for bit
        for length in [1, 2, 159, 16_000, 32_001] {
            let samples = (0..<length).map { _ in Int16(truncatingIfNeeded: random.next()) }
            XCTAssertEqual(readBack(Wav.file(samples, rate: 16_000)), samples, "\(length)")
        }
    }
}

/// The samples of a PCM16 mono WAV, little-endian after the 44-byte header.
func readBack(_ wav: Data) -> [Int16] {
    stride(from: 44, to: wav.count, by: 2).map { Int16(bitPattern: UInt16(wav.le16($0))) }
}

extension Data {
    func le16(_ at: Int) -> Int { Int(self[at]) | Int(self[at + 1]) << 8 }
    func le32(_ at: Int) -> Int { le16(at) | le16(at + 2) << 16 }
}

/// A seeded generator: the same sessions and samples on every run.
struct SplitMix: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var mixed = (state ^ (state >> 30)) &* 0xbf58_476d_1ce4_e5b9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94d0_49bb_1331_11eb
        return mixed ^ (mixed >> 31)
    }
}
