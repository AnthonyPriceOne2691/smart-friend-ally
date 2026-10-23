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
        let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("local/shell-snapshots")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for phase in phases {
            let image = try XCTUnwrap(render(phase))
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

    private func render(_ phase: SessionState) -> CGImage? {
        let scene = ShellScene(phase: phase, time: 2, safeTop: layout.safeTop, safeBottom: layout.safeBottom)
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
}
#endif
