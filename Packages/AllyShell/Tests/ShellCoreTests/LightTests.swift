import AllyCore
import ShellCore
import XCTest

final class LightTests: XCTestCase {
    /// Night at once when she sleeps from the start, dawn on waking, dusk after a stop and after the goodbye's yawn.
    func testNightComesWithSleepAndDawnsOnWaking() {  // V30
        XCTAssertEqual(Motion(seed: 1).step(step, phase: .asleep).light.night, 1, accuracy: 1e-9)
        let wake = nights(film([(0, .asleep), (5, .greeting)], for: 8))
        XCTAssertLessThanOrEqual(night(wake, at: 7.1), 0.05)
        XCTAssertTrue(zip(wake, wake.dropFirst()).filter { $1.time > 5 }.allSatisfy { $1.night <= $0.night + 1e-12 })
        let stop = nights(film([(0, .speaking), (5, .asleep)], for: 8))
        XCTAssertGreaterThanOrEqual(night(stop, at: 7.1), 0.95)
        let goodbye = nights(film([(0, .goodbye), (5, .asleep)], for: 10))
        XCTAssertTrue(goodbye.filter { $0.time > 4.5 && $0.time <= 7.1 }.allSatisfy { $0.night <= 0.05 })
        XCTAssertGreaterThanOrEqual(night(goodbye, at: 9.8), 0.95)
        for film in [wake, stop, goodbye] {
            XCTAssertTrue(zip(film, film.dropFirst()).allSatisfy { abs($1.night - $0.night) <= 0.02 })
        }
        let stars = (0..<7200).flatMap { Light.still(.asleep, time: Double($0) / 120).stars }
        XCTAssertGreaterThanOrEqual(stars.min() ?? 0, 0.15 - 1e-9)
        XCTAssertLessThanOrEqual(stars.max() ?? 1, 0.95 + 1e-9)
        XCTAssertEqual([Light.still(.asleep, time: 2).night, Light.still(.listening, time: 2).night], [1, 0])
    }

    /// The lilac follows thinking, the glow and the pearls follow listening with a soft pulse; Reduce Motion calms
    /// both.
    func testTintGlowAndPearlsFollowTheirPoses() {  // V31
        let thinking = film([(0, .listening), (2, .thinking)], for: 4)
        XCTAssertGreaterThanOrEqual(shot(thinking, at: 2.45).frame.light.think, 0.85)
        XCTAssertEqual(shot(thinking, at: 1.9).frame.light.think, 0, accuracy: 1e-9)
        let listening = film([(0, .listening)], for: 14).filter { $0.time >= 2 }.map(\.frame.light)
        let auras = listening.map(\.aura)
        XCTAssertEqual(auras.min() ?? 0, 0.6225, accuracy: 0.003)
        XCTAssertEqual(auras.max() ?? 0, 0.76, accuracy: 0.003)
        XCTAssertEqual(Light.pulse(1.3), Light.pulse(1.3 + 2.4), accuracy: 1e-9)
        XCTAssertTrue(listening.allSatisfy { $0.pearls.count == 28 && abs($0.pearlsShown - 1) < 1e-6 })
        XCTAssertTrue(listening.flatMap(\.pearls).allSatisfy { (0.4 - 1e-9...1.5 + 1e-9).contains($0) })
        XCTAssertEqual(Light.pearlRing * 378.4, 206.2, accuracy: 0.05)  // 206 pt on the parent's phone
        XCTAssertEqual(Light.pearlSize, 0.032)
        let asleep = Light.still(.asleep, time: 3)
        XCTAssertEqual([asleep.aura, asleep.pearlsShown, asleep.think], [0.28, 0, 0])
        let calm = film([(0, .listening)], for: 14, calm: true).filter { $0.time >= 2 }.map(\.frame.light)
        let reach = { (lights: [Light]) in (lights.flatMap(\.pearls).max() ?? 0) - 0.4 }
        XCTAssertEqual(reach(calm) / reach(listening), 0.5, accuracy: 0.08)
        XCTAssertEqual((calm.map(\.auraScale).max() ?? 1) - 1, ((listening.map(\.auraScale).max() ?? 1) - 1) * 0.4,
                       accuracy: 1e-4)
    }

    /// The bubble floats ±3.5 pt over 7.85 s (±1.4 with Reduce Motion); its floor shadow shrinks against it.
    func testTheBubbleFloatsAndItsShadowAnswers() {  // V35
        let floats = (0..<943).map { Light.still(.listening, time: Double($0) / 120) }
        XCTAssertEqual(floats.map(\.bob).max() ?? 0, 3.5, accuracy: 0.001)
        XCTAssertEqual(floats.map(\.bob).min() ?? 0, -3.5, accuracy: 0.001)
        XCTAssertEqual(floats.map(\.floor).min() ?? 0, 1 - 0.042, accuracy: 0.0001)
        XCTAssertEqual(Light.still(.listening, time: 1).bob, Light.still(.listening, time: 1 + 2 * .pi / 0.8).bob,
                       accuracy: 1e-9)
        let calm = film([(0, .listening)], for: 8, calm: true).map(\.frame.light.bob)
        XCTAssertEqual(calm.map(abs).max() ?? 0, 1.4, accuracy: 0.002)
    }

    private func nights(_ shots: [Shot]) -> [(time: Double, night: Double)] {
        shots.map { (time: $0.time, night: $0.frame.light.night) }
    }

    private func night(_ nights: [(time: Double, night: Double)], at t: Double) -> Double {
        nights[Int((t / step).rounded()) - 1].night
    }
}
