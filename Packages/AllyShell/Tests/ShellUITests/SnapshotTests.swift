#if canImport(SwiftUI) && os(macOS)
import AllyCore
import ImageIO
import ShellCore
import ShellUI
import SwiftUI
import UniformTypeIdentifiers
import XCTest

/// The parent's phone: 440×956 pt at 3× with its safe area; a frame at 2 s of every phase.
private let phone = CGSize(width: 440, height: 956)
private let layout = Layout(width: 440, height: 956, safeTop: 62, safeBottom: 34)
private let phases: [SessionState] = [.asleep, .greeting, .listening, .thinking, .speaking, .windingDown, .goodbye]

@MainActor
final class SnapshotTests: XCTestCase {
    /// Seven PNG for the parent's eye in `local/shell-snapshots/` (outside git) and probes frozen by the spike (L19).
    func testSevenPhasesMatchTheProbes() throws {  // V8
        let folder = try snapshots("")
        for phase in phases {
            let image = try XCTUnwrap(render(ShellScene(phase: phase, time: 2, safeTop: 62, safeBottom: 34)))
            XCTAssertEqual([image.width, image.height], [1320, 2868])
            try save(image, to: folder.appendingPathComponent("\(phase.rawValue).png"))
            let probe = try XCTUnwrap(Pixels(image))
            let eyes = probe.area(in: CGRect(x: 150, y: 420, width: 140, height: 120)) { luminance($0) < 0.06 }
            let mouth = probe.area(in: CGRect(x: 190, y: 490, width: 60, height: 70)) { near($0, 0x7A2F57, 24) }
            if phase == .asleep { XCTAssertLessThanOrEqual(eyes, 500, "\(phase)") } else {
                XCTAssertGreaterThanOrEqual(eyes, 1000, "\(phase)")
            }
            if TalkState(phase: phase).pose == .speaks { XCTAssertGreaterThanOrEqual(mouth, 100, "\(phase)") } else {
                XCTAssertLessThanOrEqual(mouth, 85, "\(phase)")
            }
            for side in [-1.0, 1.0] {
                let rim = probe.colour(x: layout.centre.x + side * (layout.diameter / 2 - 2), y: layout.centre.y)
                XCTAssertTrue(near(rim, 0xC2185B, 12), "\(phase) rim \(rim)")
            }
        }
        try save(try XCTUnwrap(sheet()), to: folder.appendingPathComponent("sheet.png"))
    }

    /// All seven phases side by side at 1× — one picture for the parent's eye.
    private func sheet() -> CGImage? {
        let row = HStack(spacing: 0) {
            ForEach(phases, id: \.self) { ShellScene(phase: $0, time: 2, safeTop: 62, safeBottom: 34) }
        }
        return ImageRenderer(content: row.frame(width: phone.width * 7, height: phone.height)).cgImage
    }

    /// Waking up and dozing off after a goodbye, five frames each, for the parent's eye; probes by V8's thresholds.
    func testWakeAndSleepStrips() throws {  // V18
        let folder = try snapshots("motion")
        let wake = frames([(0, .asleep), (5, .greeting)], at: [5, 5.15, 5.3, 5.45, 6])
        let sleep = frames([(0, .greeting), (2, .goodbye), (4, .asleep)], at: [4, 4.6, 5.2, 6.4, 7.5])
        for (name, strip) in [("wake", wake), ("sleep", sleep)] {
            let row = HStack(spacing: 0) {
                ForEach(strip.indices, id: \.self) { ShellScene(frame: strip[$0], safeTop: 62, safeBottom: 34) }
            }
            let image = ImageRenderer(content: row.frame(width: phone.width * 5, height: phone.height)).cgImage
            try save(try XCTUnwrap(image), to: folder.appendingPathComponent("\(name).png"))
        }
        let closed = try pixels(wake[0]), open = try pixels(wake[4]), yawn = try pixels(sleep[2])
        let face = CGRect(x: 150, y: 420, width: 140, height: 120)
        let mouth = CGRect(x: 190, y: 490, width: 60, height: 70)
        XCTAssertLessThanOrEqual(closed.area(in: face) { luminance($0) < 0.06 }, 500)
        XCTAssertGreaterThanOrEqual(open.area(in: face) { luminance($0) < 0.06 }, 1000)
        XCTAssertGreaterThanOrEqual(yawn.area(in: mouth) { near($0, 0x7A2F57, 24) }, 150)
        XCTAssertNotNil(ImageRenderer(content: LiveScene(phase: .asleep).frame(width: 440, height: 956)).cgImage)
    }

    /// The whole child screen for the parent's eye: each phase at 2 s with the crown and the adult's corner; probes by
    /// calculation before the code (L19) — leaves, the stop sign, the plate — and V8's on the same frames.
    func testTheWholeScreenWithTheCrownAndTheAdultsCorner() throws {  // V21
        let folder = try snapshots("app")
        let crown = CGRect(x: 140, y: 360, width: 190, height: 130), stop = CGRect(x: 380, y: 62, width: 44, height: 44)
        let plate = CGRect(x: 150, y: 62, width: 226, height: 44)
        let leaf = { (rgb: [Int]) in near(rgb, 0x8FD9B6, 16) || near(rgb, 0x6FC4A2, 16) }
        let plum = { (rgb: [Int]) in near(rgb, 0x5E1A42, 12) }, white = { (rgb: [Int]) in rgb.allSatisfy { $0 >= 251 } }
        for phase in phases {
            let image = try XCTUnwrap(render(screen(phase, label: "при родителе · до 29.10 в 21:00")))
            try save(image, to: folder.appendingPathComponent("\(phase.rawValue).png"))
            let probe = try XCTUnwrap(Pixels(image)), leaves = probe.area(in: crown, where: leaf)
            XCTAssertGreaterThanOrEqual(leaves, 100, "\(phase)")
            XCTAssertLessThanOrEqual(probe.area(where: leaf) - leaves, 5, "\(phase)")
            XCTAssertGreaterThanOrEqual(probe.area(in: stop, where: plum), 500, "\(phase)")
            XCTAssertGreaterThanOrEqual(probe.area(in: plate, where: white), 1500, "\(phase)")
            let eyes = probe.area(in: CGRect(x: 150, y: 420, width: 140, height: 120)) { luminance($0) < 0.06 }
            let mouth = probe.area(in: CGRect(x: 190, y: 490, width: 60, height: 70)) { near($0, 0x7A2F57, 24) }
            XCTAssertTrue(phase == .asleep ? eyes <= 500 : eyes >= 1000, "\(phase) eyes \(eyes)")
            let speaks = TalkState(phase: phase).pose == .speaks
            XCTAssertTrue(speaks ? mouth >= 100 : mouth <= 85, "\(phase) mouth \(mouth)")
        }
        let bare = try XCTUnwrap(Pixels(try XCTUnwrap(render(screen(.asleep, label: nil)))))
        XCTAssertLessThanOrEqual(bare.area(in: plate, where: white), 100)
        XCTAssertGreaterThanOrEqual(bare.area(in: stop, where: plum), 500)
        let live = ChildShell(talk: TalkState(), until: nil, onTap: {}, onStop: {})
        XCTAssertNotNil(ImageRenderer(content: live.frame(width: phone.width, height: phone.height)).cgImage)
    }

    /// A still frame of the child screen: the scene of a phase at 2 s and the adult's corner over it.
    private func screen(_ phase: SessionState, label: String?) -> some View {
        screen(Frame.at(phase, time: 2), label: label)
    }

    private func screen(_ frame: Frame, label: String?) -> some View {
        ZStack {
            ShellScene(frame: frame, safeTop: 62, safeBottom: 34)
            AdultZone(label: label, layout: layout, onStop: {})
        }
    }

    /// Night from the start, listening and thinking from the animator, the whole screen: the sky's top strip, the moon,
    /// the pearls on their ring; V8's and V21's probes on the same frames (thresholds by calculation before the code).
    func testNightThinkingAndListeningLight() throws {  // V36
        let folder = try snapshots("light"), term = "при родителе · до 29.10 в 21:00"
        let night = frames([(0, .asleep)], at: [2])[0]
        let day = [frames([(0, .greeting), (1, .listening)], at: [4.9])[0],
                   frames([(0, .greeting), (1, .listening), (3, .thinking)], at: [4])[0]]
        var probes: [String: Pixels] = [:]
        for (name, frame) in [("night", night), ("listening", day[0]), ("thinking", day[1])] {
            let image = try XCTUnwrap(render(screen(frame, label: term)))
            try save(image, to: folder.appendingPathComponent("\(name).png"))
            probes[name] = try XCTUnwrap(Pixels(image))
        }
        let strip = CGRect(x: 0, y: 0, width: 440, height: 40)
        XCTAssertLessThanOrEqual(try XCTUnwrap(probes["night"]).mean(in: strip, luminance), 0.70)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(probes["listening"]).mean(in: strip, luminance), 0.85)
        let moon = CGRect(x: 290, y: 380, width: 72, height: 90), moonTone = { (rgb: [Int]) in near(rgb, 0xFFF1B8, 16) }
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(probes["night"]).area(in: moon, where: moonTone), 150)
        XCTAssertLessThanOrEqual(try XCTUnwrap(probes["listening"]).area(in: moon, where: moonTone), 10)
        let ring = { (name: String, frame: Frame) in
            try XCTUnwrap(probes[name]).ring(centre: CGPoint(x: 220, y: 535 + frame.light.bob), from: 0.51 * 378.4,
                                             to: 0.58 * 378.4) { near($0, 0xFF8FC0, 24) }
        }
        XCTAssertGreaterThanOrEqual(try ring("listening", day[0]), 150)
        XCTAssertLessThanOrEqual(try ring("thinking", day[1]), 20)
        for (name, asleep) in [("night", true), ("listening", false), ("thinking", false)] {
            let probe = try XCTUnwrap(probes[name])
            let eyes = probe.area(in: CGRect(x: 150, y: 420, width: 140, height: 120)) { luminance($0) < 0.06 }
            XCTAssertTrue(asleep ? eyes <= 500 : eyes >= 1000, "\(name) eyes \(eyes)")
            XCTAssertLessThanOrEqual(probe.area(in: CGRect(x: 190, y: 490, width: 60, height: 70)) {
                near($0, 0x7A2F57, 24) }, 85, name)
            XCTAssertGreaterThanOrEqual(probe.area(in: CGRect(x: 140, y: 360, width: 190, height: 130)) {
                near($0, 0x8FD9B6, 16) || near($0, 0x6FC4A2, 16) }, 100, name)
            XCTAssertGreaterThanOrEqual(probe.area(in: CGRect(x: 380, y: 62, width: 44, height: 44)) {
                near($0, 0x5E1A42, 12) }, 500, name)
            XCTAssertGreaterThanOrEqual(probe.area(in: CGRect(x: 150, y: 62, width: 226, height: 44)) {
                $0.allSatisfy { $0 >= 251 } }, 1500, name)
            for side in [-1.0, 1.0] {
                let rim = probe.colour(x: layout.centre.x + side * (layout.diameter / 2 - 2), y: layout.centre.y)
                XCTAssertTrue(near(rim, 0xC2185B, 12), "\(name) rim \(rim)")
            }
        }
    }

    private func pixels(_ frame: Frame) throws -> Pixels {
        try XCTUnwrap(Pixels(try XCTUnwrap(render(ShellScene(frame: frame, safeTop: 62, safeBottom: 34)))))
    }

    /// A motion stepped at 1/120 s along a script of (from second, phase); the frames at the given seconds.
    private func frames(_ script: [(at: Double, phase: SessionState)], at moments: [Double]) -> [Frame] {
        let motion = Motion(seed: 1), step = 1.0 / 120
        var shots: [Frame] = [], time = 0.0
        for moment in moments {
            while time < moment - 1e-9 {
                let phase = script.last { $0.at <= time + 1e-9 }?.phase ?? .asleep
                shots.append(motion.step(step, phase: phase))
                time += step
            }
        }
        return moments.map { shots[max(Int(($0 / step).rounded()) - 1, 0)] }
    }

    /// `local/shell-snapshots/<sub>` in the repository (outside git), created if missing.
    private func snapshots(_ sub: String) throws -> URL {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let folder = root.appendingPathComponent("local/shell-snapshots").appendingPathComponent(sub)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func render(_ scene: some View) -> CGImage? {
        let renderer = ImageRenderer(content: scene.frame(width: phone.width, height: phone.height))
        renderer.scale = 3
        return renderer.cgImage
    }

    private func save(_ image: CGImage, to url: URL) throws {
        let png = UTType.png.identifier as CFString
        let target = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, png, 1, nil))
        CGImageDestinationAddImage(target, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(target))
    }
}

/// The rendered frame as RGBA bytes, read in points of the 3× image.
private struct Pixels {
    let width: Int, bytes: [UInt8]

    init?(_ image: CGImage) {
        width = image.width
        var buffer = [UInt8](repeating: 0, count: image.width * image.height * 4)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: &buffer, width: image.width, height: image.height, bitsPerComponent: 8,
                                  bytesPerRow: image.width * 4, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        bytes = buffer
    }

    func colour(x: Double, y: Double) -> [Int] {
        let index = (Int(y * 3) * width + Int(x * 3)) * 4
        return [Int(bytes[index]), Int(bytes[index + 1]), Int(bytes[index + 2])]
    }

    /// Area in pt² of the pixels of the whole frame that pass the test.
    func area(where test: ([Int]) -> Bool) -> Double {
        let count = stride(from: 0, to: bytes.count, by: 4).filter { test([Int(bytes[$0]), Int(bytes[$0 + 1]),
                                                                          Int(bytes[$0 + 2])]) }.count
        return Double(count) / 9
    }

    /// The mean of a value over the pixels inside the box.
    func mean(in box: CGRect, _ value: ([Int]) -> Double) -> Double {
        var (sum, count) = (0.0, 0)
        for y in Int(box.minY * 3)..<Int(box.maxY * 3) {
            for x in Int(box.minX * 3)..<Int(box.maxX * 3) {
                sum += value(colour(x: Double(x) / 3, y: Double(y) / 3))
                count += 1
            }
        }
        return sum / Double(max(count, 1))
    }

    /// Area in pt² of the pixels between two radii round a centre that pass the test.
    func ring(centre: CGPoint, from inner: Double, to outer: Double, where test: ([Int]) -> Bool) -> Double {
        let box = CGRect(x: centre.x - outer, y: centre.y - outer, width: outer * 2, height: outer * 2)
        var count = 0
        for y in Int(max(box.minY, 0) * 3)..<Int(box.maxY * 3) {
            for x in Int(max(box.minX, 0) * 3)..<Int(min(box.maxX, Double(width) / 3) * 3) {
                let distance = hypot(Double(x) / 3 - centre.x, Double(y) / 3 - centre.y)
                if distance >= inner, distance <= outer, test(colour(x: Double(x) / 3, y: Double(y) / 3)) { count += 1 }
            }
        }
        return Double(count) / 9
    }

    /// Area in pt² of the pixels inside the box that pass the test.
    func area(in box: CGRect, where test: ([Int]) -> Bool) -> Double {
        var count = 0
        for y in Int(box.minY * 3)..<Int(box.maxY * 3) {
            for x in Int(box.minX * 3)..<Int(box.maxX * 3) where test(colour(x: Double(x) / 3, y: Double(y) / 3)) {
                count += 1
            }
        }
        return Double(count) / 9
    }
}

private func near(_ rgb: [Int], _ hex: UInt32, _ tolerance: Int) -> Bool {
    let target = [Int((hex >> 16) & 0xFF), Int((hex >> 8) & 0xFF), Int(hex & 0xFF)]
    return zip(rgb, target).allSatisfy { abs($0 - $1) <= tolerance }
}

private func luminance(_ rgb: [Int]) -> Double {
    Tone(UInt32(rgb[0] << 16 | rgb[1] << 8 | rgb[2])).luminance
}
#else
import XCTest

final class SnapshotTests: XCTestCase {
    /// Snapshots need SwiftUI and ImageRenderer: on Linux the test is skipped visibly (П34), the Mac runs it.
    func testSevenPhasesMatchTheProbes() throws {  // V8
        throw XCTSkip("снимки — только на Mac")
    }

    func testWakeAndSleepStrips() throws {  // V18
        throw XCTSkip("полосы кадров — только на Mac")
    }

    func testTheWholeScreenWithTheCrownAndTheAdultsCorner() throws {  // V21
        throw XCTSkip("экран целиком — только на Mac")
    }

    func testNightThinkingAndListeningLight() throws {  // V36
        throw XCTSkip("свет и пузырьки — только на Mac")
    }
}
#endif
