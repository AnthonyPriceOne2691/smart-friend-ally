import AllyCore
import ShellCore
import XCTest

final class MusicTests: XCTestCase {
    private let line = MusicLine.standard

    /// The child screen after the warm-up, Ellie asleep.
    private var idle: MusicCue.Scene {
        var scene = MusicCue.Scene()
        (scene.child, scene.ready) = (true, true)
        return scene
    }

    private func fader(_ cues: [(MusicCue, Double)]) -> MusicFader {
        var fader = MusicFader()
        for (cue, time) in cues { _ = fader.cue(cue, line: line, at: time) }
        return fader
    }

    /// The level after `cues` (at their times), read at `times` to a thousandth.
    private func levels(_ cues: [(MusicCue, Double)], at times: [Double]) -> [Double] {
        let fader = fader(cues)
        return times.map { (fader.level(at: $0) * 1000).rounded() / 1000 }
    }

    func testTheMusicComesTwoSecondsAfterTheScreenAndRisesForThree() {
        // Y1 0 until 2 s, 0,4 at 3,5 s, 0,8 from 5 s
        XCTAssertEqual(MusicCue.of(idle, line: line), .full)
        XCTAssertEqual(levels([(.full, 0)], at: [0, 2, 3.5, 5, 60]), [0, 0, 0.4, 0.8, 0.8])
    }

    func testATapTakesItToBarelyAudibleInFourTenthsAndThenTheMicrophoneOpens() {
        // Y2 0,8 → 0,08 from 10 to 10,4 s; the microphone waits for 10,4
        var scene = idle
        scene.waking = true
        XCTAssertEqual(MusicCue.of(scene, line: line), .quiet)
        XCTAssertEqual(line.quiet, 0.08, accuracy: 1e-9)
        XCTAssertEqual(levels([(.full, 0), (.quiet, 10)], at: [10, 10.2, 10.4, 30]), [0.8, 0.44, 0.08, 0.08])
        XCTAssertEqual(fader([(.full, 0), (.quiet, 10)]).end, 10.4, accuracy: 1e-9)
    }

    func testEveryPhaseOfATalkIsBarelyAudible() {
        // Y3 greeting, listening, thinking, speaking, winding down, goodbye, paused — quiet; asleep — full
        let talk: [SessionState] = [.greeting, .listening, .thinking, .speaking, .windingDown, .goodbye, .paused]
        for phase in talk {
            var scene = idle
            scene.phase = phase
            XCTAssertEqual(MusicCue.of(scene, line: line), .quiet, "\(phase)")
        }
        XCTAssertEqual(MusicCue.of(idle, line: line), .full)
    }

    func testAfterATalkTheMusicWaitsTwoSecondsAndRisesForThree() {
        // Y4 asleep at 100: 0,08 until 102, 0,44 at 103,5, 0,8 at 105
        let cues: [(MusicCue, Double)] = [(.full, 0), (.quiet, 10), (.full, 100)]
        XCTAssertEqual(levels(cues, at: [101, 102, 103.5, 105]), [0.08, 0.08, 0.44, 0.8])
    }

    func testATapWhileItWaitsOpensAtOnceAndWhileItRisesGoesDownInFourTenths() {
        // Y5 a tap at 101 (waiting) — no way, the microphone at once; at 103,5 (rising, 0,44) — 0,08 at 103,9
        var waiting = fader([(.full, 0), (.quiet, 10), (.full, 100)]), rising = waiting
        _ = waiting.cue(.quiet, line: line, at: 101)
        XCTAssertEqual(waiting.end, 101, accuracy: 1e-9)
        XCTAssertEqual(waiting.level(at: 101), 0.08, accuracy: 1e-9)
        _ = rising.cue(.quiet, line: line, at: 103.5)
        XCTAssertEqual(rising.end, 103.9, accuracy: 1e-9)
        XCTAssertEqual(rising.level(at: 103.7), 0.26, accuracy: 1e-9)
        XCTAssertNil(rising.cue(.quiet, line: line, at: 104), "the same level — no new way")
        let early = fader([(.full, 0), (.quiet, 1)])
        XCTAssertEqual(early.end, 1, accuracy: 1e-9, "a tap before the music rose does not wait for it")
        XCTAssertEqual(early.level(at: 1.5), 0.08, accuracy: 1e-9)
    }

    func testTheConsoleTheBackgroundAndTheWarmUpHaveNoMusic() {
        // Y6 Y7 the console (and its talks), the app behind, before the warm-up — off; the console: 0,8 → 0 in 0,4 s
        let off: [(inout MusicCue.Scene) -> Void] = [{ $0.child = false }, { $0.front = false }, { $0.ready = false },
                                                     { ($0.child, $0.phase) = (false, .listening) }]
        for (index, change) in off.enumerated() {
            var scene = idle
            change(&scene)
            XCTAssertEqual(MusicCue.of(scene, line: line), .off, "case \(index)")
        }
        XCTAssertEqual(levels([(.full, 0), (.off, 10)], at: [10.2, 10.4, 20]), [0.4, 0, 0])
        XCTAssertEqual(levels([(.full, 0), (.off, 10), (.full, 20)], at: [22, 23.5, 25]), [0, 0.4, 0.8])
    }

    func testWithoutAnEchoCancellerATalkHasNoMusic() {
        // Y8 Milena: a tap — 0 in 0,4 s, the talk silent, after it — up from 0 as Y4
        var milena = idle
        (milena.cancelsEcho, milena.waking) = (false, true)
        XCTAssertEqual(MusicCue.of(milena, line: line), .off)
        milena.waking = false
        XCTAssertEqual(MusicCue.of(milena, line: line), .full)
        XCTAssertEqual(levels([(.full, 0), (.off, 10), (.full, 100)], at: [10.4, 101, 103.5, 105]), [0, 0, 0.4, 0.8])
    }

    func testTheLineTakesThreePointsAtEachEdgeAndRefusesTheRest() throws {
        // Y9 the standard without keys; 0, 0,01, 1 kept; −0,1, 1,1 and a word refused with the console's line
        XCTAssertEqual(decode("{}"), .standard)
        XCTAssertEqual(MusicLine.standard.console, "музыка: «Шкатулка Элли» · 0,80 · -20,00 дБ")
        for (raw, volume) in [("0", 0.0), ("0.01", 0.01), ("1", 1.0), ("0.99", 0.99)] {
            XCTAssertEqual(decode("{\"volume\": \(raw)}").volume, volume, raw)
            XCTAssertEqual(decode("{\"volume\": \(raw)}").notes, [], raw)
        }
        for raw in ["-0.1", "1.1", "\"тихо\"", "true"] {
            let refused = decode("{\"volume\": \(raw)}")
            XCTAssertEqual(refused.volume, 0.8, raw)
            XCTAssertEqual(refused.notes, ["музыка: громкость вне 0–1 — взято 0,80"], raw)
        }
        let edges = decode("{\"duck_db\": -60, \"fade_out\": 5, \"delay\": 60, \"fade_in\": 30}")
        XCTAssertEqual([edges.duckDB, edges.fadeOut, edges.delay, edges.fadeIn], [-60, 5, 60, 30])
        let past = decode("{\"duck_db\": 0.5, \"fade_out\": -0.1, \"delay\": 61, \"fade_in\": 30.5, \"on\": 1}")
        XCTAssertEqual([past.duckDB, past.fadeOut, past.delay, past.fadeIn], [-20, 0.4, 2, 3])
        XCTAssertEqual(past.notes.count, 5)
        XCTAssertEqual(decode("[1]").notes, ["музыка: music.json не читается"])
        for raw in ["{\"on\": false}", "{\"volume\": 0}"] {  // Y9 off or silent: off everywhere, a tap never waits
            let silent = decode(raw)
            XCTAssertEqual([MusicCue.of(idle, line: silent), MusicCue.of(idle, line: .standard)], [.off, .full], raw)
            XCTAssertEqual(silent.console, "музыка: выключена", raw)
            var fader = MusicFader()
            XCTAssertNil(fader.cue(.off, line: silent, at: 5), raw)
        }
    }

    func testTheLevelNeverJumpsAndAWayDownEndsInFourTenthsOnAHundredScenes() {
        // Y2 Y5 a property on 100 random cue sequences (seeded): no jump at a cue, the level stays in 0…0,8, a way down
        // ends within 0,4 s; the steepest way is 0,8 in 0,4 s, and the one step is the rise to «еле слышно» (0,08)
        var seed: UInt64 = 2026_10_29
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(seed >> 11) / Double(1 << 53)
        }
        for scenario in 0..<100 {
            var (fader, time) = (MusicFader(), 0.0)
            for _ in 0..<20 {
                time += next() * 4
                let before = fader.level(at: time), cue = [MusicCue.off, .quiet, .full][Int(next() * 3) % 3]
                guard let ramp = fader.cue(cue, line: line, at: time) else { continue }
                XCTAssertEqual(fader.level(at: time), before, accuracy: 1e-9, "scenario \(scenario): a jump")
                XCTAssertTrue((0...0.8).contains(ramp.to), "scenario \(scenario)")
                if ramp.to < before { XCTAssertLessThanOrEqual(fader.end, time + 0.4 + 1e-9, "scenario \(scenario)") }
                let step = 0.01, change = abs(fader.level(at: time + step) - fader.level(at: time))
                XCTAssertLessThanOrEqual(change, max(0.8 / 0.4 * step, line.quiet) + 1e-9, "scenario \(scenario)")
            }
        }
    }

    private func decode(_ json: String) -> MusicLine { MusicLine.decode(Data(json.utf8)) }
}
