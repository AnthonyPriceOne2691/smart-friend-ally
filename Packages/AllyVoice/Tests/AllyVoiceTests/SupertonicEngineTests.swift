import AllyVoice
import XCTest

/// The engine's own guarantees on the Mac: the speed floor, memory with external-data weights and the session options,
/// time of a sentence. Numbers go to the log for verify-report.
final class SupertonicEngineTests: XCTestCase {
    func testSpeedFloorRefusesBelow085() throws { // Z4
        let engine = try Fixtures.engine()
        XCTAssertThrowsError(try engine.synthesize("Привет!", voice: VoicePreset(speed: 0.84))) { error in
            XCTAssertEqual("\(error)", "скорость синтеза 0,84 ниже 0,85")
        }
        let slow = try engine.synthesize("Привет!", voice: VoicePreset(speed: 0.85))
        XCTAssertFalse(slow.samples.isEmpty)
        // A relation instead of an expected value: the predicted length scales as 1 / speed.
        let fast = try engine.synthesize("Привет!", voice: VoicePreset(speed: 1.05))
        XCTAssertEqual(slow.duration * 0.85, fast.duration * 1.05, accuracy: 1e-5)
    }

    func testExternalDataKeepsFootprintSmall() throws { // Z5
        _ = try Fixtures.engine()  // the skip, if the weights are missing
        let before = Footprint.read()
        let engine = try SupertonicEngine(folder: Fixtures.model)
        let loaded = Footprint.read(), sampler = FootprintSampler()
        sampler.start()
        _ = try engine.synthesize("Мой аксолотлик сегодня весёлый, он машет розовыми жабрами и улыбается.",
                                  voice: VoicePreset(style: "F2+F5:0.5"))
        let peak = max(sampler.stop(), Footprint.read().now)
        Fixtures.log(String(format: "отпечаток: до %.1f, после загрузки %.1f (+%.1f), пик фразы %.1f (+%.1f) МБ",
                            before.now, loaded.now, loaded.now - before.now, peak, peak - before.now))
        XCTAssertLessThanOrEqual(loaded.now - before.now, 100)
        XCTAssertLessThanOrEqual(peak - before.now, 250)
        XCTAssertEqual(engine.options.description, "threads=2 spin=0")
    }

    func testSentenceTimeOnMac() throws { // Z6
        _ = try Fixtures.engine()
        let start = Date()
        let engine = try SupertonicEngine(folder: Fixtures.model)
        let load = Date().timeIntervalSince(start)
        let sentences = ["Смотри, какой высокий замок я построила из кубиков сегодня!",
                         "Давай поиграем в прятки, а потом нарисуем большую радугу вместе.",
                         "Мой аксолотлик сегодня весёлый, он машет розовыми жабрами и улыбается.",
                         "Знаешь, почему небо голубое, когда на улице светит яркое солнце?"]
        _ = try engine.synthesize("Привет!", voice: VoicePreset())  // the first run after loading builds the graphs
        var times: [Double] = [], cpu: [Double] = []
        for round in 0..<3 {
            for sentence in sentences {
                let begin = Date(), cpuBegin = Self.cpuSeconds()
                _ = try engine.synthesize(sentence, voice: VoicePreset(seed: UInt64(round)))
                (times, cpu) = (times + [Date().timeIntervalSince(begin)], cpu + [Self.cpuSeconds() - cpuBegin])
            }
        }
        let median = times.sorted()[times.count / 2], load1 = Self.loadAverage()
        Fixtures.log(String(format: "время: загрузка %.2f с, фраза медиана %.2f с (мин %.2f, макс %.2f), CPU медиана "
                            + "%.2f с, load average %.1f", load, median, times.min() ?? 0, times.max() ?? 0,
                            cpu.sorted()[cpu.count / 2], load1))
        XCTAssertLessThanOrEqual(load, 1)
        XCTAssertLessThanOrEqual(median, 1.3)
    }
}

extension SupertonicEngineTests {
    /// CPU seconds of the process (user + system): the engine's own cost, apart from what other processes take.
    static func cpuSeconds() -> Double {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        let seconds = { (time: timeval) in Double(time.tv_sec) + Double(time.tv_usec) / 1e6 }
        return seconds(usage.ru_utime) + seconds(usage.ru_stime)
    }

    /// The one-minute load average: a slow run on a busy Mac says so in the log.
    static func loadAverage() -> Double {
        var load = [Double](repeating: 0, count: 3)
        return getloadavg(&load, 3) > 0 ? load[0] : -1
    }
}

/// Footprint sampled every 20 ms while a sentence is synthesized: the lifetime peak of the process already holds the
/// peaks of earlier tests, so the peak of this sentence is taken by sampling.
final class FootprintSampler: @unchecked Sendable {
    private let timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "footprint"))
    private let lock = NSLock()
    private var high = 0.0

    func start() {
        timer.schedule(deadline: .now(), repeating: .milliseconds(20))
        timer.setEventHandler { [self] in
            let now = Footprint.read().now
            lock.lock()
            high = max(high, now)
            lock.unlock()
        }
        timer.resume()
    }

    func stop() -> Double {
        timer.cancel()
        lock.lock()
        defer { lock.unlock() }
        return high
    }
}
