import AllyCore
import ShellCore
import XCTest

final class BubblesTests: XCTestCase {
    /// The sky's bubbles start at the prototype's places, rise and come back from below; the water's rise inside; the
    /// sky's glints twinkle; Reduce Motion keeps 0.4 of the speed and the sway.
    func testSkyAndWaterBubblesRiseAndComeBackFromBelow() {  // V32
        let first = Motion(seed: 3).step(step, phase: .listening).bubbles
        XCTAssertEqual(first.sky.map(\.size), [88, 44, 118, 34, 62, 76, 100, 40])
        let places = [[4.0, 10], [80, 7], [72, 30], [20, 34], [4, 58], [82, 66], [30, 84], [50, 4]]
        for (bubble, place) in zip(first.sky, places) {
            XCTAssertEqual(bubble.x * 440 - bubble.size / 2, place[0] * 4.4, accuracy: 0.2)
            XCTAssertEqual(bubble.y * 956 - bubble.size / 2, place[1] * 9.56, accuracy: 0.2)
            XCTAssertTrue((4...9).contains(bubble.speed) && (6...12).contains(bubble.sway), "\(bubble)")
            XCTAssertTrue((0.2...0.4).contains(bubble.tempo), "\(bubble)")
        }
        for calm in [false, true] {
            let swing = calm ? 0.4 : 1, shots = film([(0, .listening)], for: 60, seed: 3, calm: calm)
            let fields = shots.map(\.frame.bubbles)
            for sky in [true, false] {
                XCTAssertTrue(rises(fields, sky: sky).filter { !$0.back }.allSatisfy { abs($0.ratio - swing) < 1e-6 })
            }
            let sways = fields.prefix(Int(31.5 / step)).map { $0.sky[2].x * 440 }
            XCTAssertEqual((sways.max() ?? 0) - (sways.min() ?? 0), 2 * first.sky[2].sway * swing, accuracy: 0.01)
            let glints = shots.flatMap(\.frame.light.glints)
            XCTAssertTrue(glints.allSatisfy { (0.38 - 1e-9...0.82 + 1e-9).contains($0) })
        }
        let fields = film([(0, .listening)], for: 60, seed: 3).map(\.frame.bubbles)
        let backs = rises(fields, sky: true).filter(\.back)
        XCTAssertFalse(backs.isEmpty)
        let below = 956 + 20 - 1e-6...956 + 100 + 1e-6
        XCTAssertTrue(backs.allSatisfy { $0.from < -24 + 9 * step && below.contains($0.to) })
        XCTAssertTrue(fields[0].water.allSatisfy { (3.2...7).contains($0.radius) && (8...18).contains($0.speed) })
        let wraps = rises(fields, sky: false).filter(\.back)
        XCTAssertFalse(wraps.isEmpty)
        XCTAssertTrue(wraps.allSatisfy { $0.from < -205 + 18 * step + 1e-9 && $0.to == 205 })
    }

    /// Thinking puffs every 0.6 s while thinking weighs over half, «Z» every 1.7 s in sleep, one «Z» on a tap; all
    /// fade in and out.
    func testThoughtsAndZsAreBornOnTheirClocksAndFadeSoftly() {  // V33
        let thinking = film([(0, .listening), (2, .thinking)], for: 14, seed: 5)
        let thoughts = births(thinking, z: false)
        XCTAssertTrue((2...2.6).contains(thoughts.first?.time ?? 0), "\(thoughts.first?.time ?? 0)")
        XCTAssertTrue(zip(thoughts, thoughts.dropFirst()).allSatisfy { abs($1.time - $0.time - 0.6) < 0.02 })
        for birth in thoughts {
            XCTAssertTrue((-128 - 0.4...(-108)).contains(birth.y + 8 - birth.rise), "\(birth)")
            XCTAssertTrue((-38 - 1e-6...(-26) + 1e-6).contains(birth.speed), "\(birth)")
        }
        XCTAssertTrue(thoughts.filter { $0.time + 2.8 < 14 }.allSatisfy { (2.2 - 0.02...2.8 + 0.02).contains($0.life) })
        XCTAssertTrue(births(film([(0, .listening)], for: 20, seed: 5), z: false).isEmpty)
        let calm = births(film([(0, .listening), (2, .thinking)], for: 14, seed: 5, calm: true), z: false)
        XCTAssertTrue(zip(calm, calm.dropFirst()).allSatisfy { abs($1.time - $0.time - 1.1) < 0.02 })

        let dozing = births(film([(0, .goodbye), (2, .asleep)], for: 14, seed: 5), z: true)
        XCTAssertTrue((4.6...5.0).contains(dozing.first?.time ?? 0), "\(dozing.first?.time ?? 0)")
        XCTAssertTrue(zip(dozing, dozing.dropFirst()).allSatisfy { abs($1.time - $0.time - 1.7) < 0.02 })
        XCTAssertTrue(dozing.dropLast(2).allSatisfy { abs($0.life - 3.6) < 0.02 && $0.grown > 2.35 })
        let sleeping = births(film([(0, .asleep)], for: 8, seed: 5), z: true)
        XCTAssertTrue((1.0...1.4).contains(sleeping.first?.time ?? 0), "\(sleeping.first?.time ?? 0)")

        let motion = Motion(seed: 5)
        for _ in 0..<60 { _ = motion.step(step, phase: .asleep) }
        XCTAssertTrue(motion.step(step, phase: .asleep).bubbles.puffs.allSatisfy { $0.opacity == 0 })
        motion.poke()
        XCTAssertEqual(motion.step(step, phase: .asleep).bubbles.puffs.filter { $0.z && $0.opacity > 0 }.count, 1)
    }

    /// A puff's birth: when, where it rose from (units, and the body's float then), its speed, life and growth.
    private struct Birth {
        let time: Double, y: Double, rise: Double, speed: Double, life: Double, grown: Double
    }

    private func births(_ shots: [Shot], z: Bool) -> [Birth] {
        let slots = shots[0].frame.bubbles.puffs.indices.filter { shots[0].frame.bubbles.puffs[$0].z == z }
        return slots.flatMap { slot in
            shots.indices.dropFirst().compactMap { index -> Birth? in
                let puff = shots[index].frame.bubbles.puffs[slot]
                guard shots[index - 1].frame.bubbles.puffs[slot].opacity == 0, puff.opacity > 0,
                      index + 1 < shots.count else { return nil }
                let rest = shots[index...].prefix { $0.frame.bubbles.puffs[slot].opacity > 0 }
                let next = shots[index + 1].frame.bubbles.puffs[slot]
                return Birth(time: shots[index].time, y: puff.y, rise: shots[index].frame.rise,
                             speed: (next.y - puff.y) / step, life: Double(rest.count) * step,
                             grown: (rest.last?.frame.bubbles.puffs[slot].scale ?? 0) / puff.scale)
            }
        }.sorted { $0.time < $1.time }
    }

    /// One bubble between two frames: its rise as a share of its own speed, or its jump from the top back below
    /// (the sky's — edges in pt, the water's — centres in units).
    private struct Rise {
        let back: Bool, ratio: Double, from: Double, to: Double
    }

    private func rises(_ fields: [BubbleField], sky: Bool) -> [Rise] {
        zip(fields, fields.dropFirst()).flatMap { before, after in
            (0..<(sky ? before.sky.count : before.water.count)).map { index in
                let speed = sky ? before.sky[index].speed : before.water[index].speed
                let top = { (field: BubbleField) in sky ? field.sky[index].y * 956 : field.water[index].y }
                let half = sky ? before.sky[index].size / 2 : 0, fall = (top(before) - top(after)) / step
                return Rise(back: fall < 0, ratio: fall / speed, from: top(before) + half, to: top(after) - half)
            }
        }
    }
}
