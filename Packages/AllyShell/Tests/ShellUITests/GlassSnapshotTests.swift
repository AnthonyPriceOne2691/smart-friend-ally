#if canImport(SwiftUI) && os(macOS)
import AllyCore
import AppKit
import ShellCore
import ShellUI
import SwiftUI
import XCTest

/// The real glass (app-glass): `ImageRenderer` does not draw it — glass on an empty shape comes out opaque white, a
/// view with glass on its own content drops out with it — so these frames come from the window server (`WindowCamera`).
/// PNG for the parent's eye in `local/shell-snapshots/glass/` (outside git).
@MainActor
final class GlassSnapshotTests: XCTestCase {
    private let phone = Layout(width: 440, height: 956, safeTop: 62, safeBottom: 34)

    /// The adult's corner by day and by night on real glass: the plate stays white and the sign plum by V21's
    /// thresholds, and without the glass the same probes differ by at most 10% — the underlay holds them, not the
    /// glass.
    func testTheRealGlassKeepsThePlateWhiteAndTheSignPlum() throws {  // F3
        let camera = try WindowCamera(), folder = try snapshots("glass")
        let plate = CGRect(x: 150, y: 62, width: 226, height: 44), stop = CGRect(x: 380, y: 62, width: 44, height: 44)
        let white = { (rgb: [Int]) in rgb.allSatisfy { $0 >= 251 } }, plum = { (rgb: [Int]) in near(rgb, 0x5E1A42, 12) }
        for (name, phase) in [("day", SessionState.speaking), ("night", .asleep)] {
            let strip = corner(Frame.at(phase, time: 2)), glass = try camera.shoot(strip, height: 160)
            try save(glass, to: folder.appendingPathComponent("corner-\(name).png"))
            let real = try XCTUnwrap(Pixels(glass, scale: camera.scale))
            let bare = try XCTUnwrap(Pixels(try XCTUnwrap(flat(strip, height: 160, scale: camera.scale)),
                                            scale: camera.scale))
            let whites = (real.area(in: plate, where: white), bare.area(in: plate, where: white))
            let plums = (real.area(in: stop, where: plum), bare.area(in: stop, where: plum))
            XCTAssertGreaterThanOrEqual(whites.0, 1500, name)
            XCTAssertGreaterThanOrEqual(plums.0, 500, name)
            XCTAssertLessThanOrEqual(abs(whites.0 - whites.1), 0.1 * whites.1, "\(name) white \(whites)")
            XCTAssertLessThanOrEqual(abs(plums.0 - plums.1), 0.1 * plums.1, "\(name) plum \(plums)")
        }
    }

    /// The console's glass capsule enabled above and disabled below on the console's sky: plum words that fade when the
    /// button is disabled; at least 44 pt high.
    func testGlassButtonsFadeWhenDisabled() throws {  // F4
        let camera = try WindowCamera()
        let pair = AdultSky {
            VStack(spacing: 0) {
                Button("Стоп") {}.buttonStyle(GlassCapsule()).frame(maxHeight: .infinity)
                Button("Стоп") {}.buttonStyle(GlassCapsule()).disabled(true).frame(maxHeight: .infinity)
            }
            .frame(width: 440, height: 200)
        }
        let image = try camera.shoot(pair, height: 200)
        try save(image, to: try snapshots("glass").appendingPathComponent("buttons.png"))
        let probe = try XCTUnwrap(Pixels(image, scale: camera.scale))
        let plum = { (rgb: [Int]) in near(rgb, 0x5E1A42, 24) }
        XCTAssertGreaterThanOrEqual(probe.area(in: CGRect(x: 0, y: 0, width: 440, height: 100), where: plum), 80)
        XCTAssertLessThanOrEqual(probe.area(in: CGRect(x: 0, y: 100, width: 440, height: 100), where: plum), 5)
        XCTAssertGreaterThanOrEqual(NSHostingView(rootView: Button("Стоп") {}.buttonStyle(GlassCapsule())).fittingSize
            .height, 44)
    }

    /// The top 160 pt of the child screen: the scene drawn for the whole phone, the adult's corner over it.
    private func corner(_ frame: Frame) -> some View {
        ZStack {
            ShellScene(frame: frame, safeTop: 62, safeBottom: 34)
            AdultZone(label: "при родителе · до 29.10 в 21:00", layout: phone, onStop: {})
        }
        .frame(width: 440, height: 956).frame(width: 440, height: 160, alignment: .top).clipped()
    }

    private func flat(_ view: some View, height: Double, scale: Double) -> CGImage? {
        let renderer = ImageRenderer(content: view.frame(width: 440, height: height))
        renderer.scale = scale
        return renderer.cgImage
    }
}

/// One borderless window at the top right of the screen, shown for a moment per frame and captured alone: an app may
/// capture its own windows without the screen-recording permission. The capture call is obsolete in the SDK, so it is
/// found by name; no call, no screen or an empty frame — a visible skip (П34), and the glass is the parent's eye.
@MainActor
final class WindowCamera {
    private typealias Capture = @convention(c) (CGRect, UInt32, UInt32, UInt32) -> Unmanaged<CGImage>?
    private let capture: Capture, screen: NSRect
    let scale: Double

    init() throws {
        NSApplication.shared.setActivationPolicy(.accessory)
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGWindowListCreateImage"),
              let main = NSScreen.main else { throw XCTSkip("нет снимка окна или экрана: стекло судит глаз родителя") }
        (capture, screen, scale) = (unsafeBitCast(symbol, to: Capture.self), main.visibleFrame, main.backingScaleFactor)
    }

    func shoot(_ view: some View, height: Double) throws -> CGImage {
        let rect = NSRect(x: screen.maxX - 448, y: screen.maxY - height - 8, width: 440, height: height)
        let window = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        (window.isOpaque, window.level) = (true, .floating)
        window.appearance = NSAppearance(named: .aqua)  // the phone's light look; the Mac may be dark
        window.contentView = NSHostingView(rootView: view.environment(\.colorScheme, .light))
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.9))
        let bounds: UInt32 = (1 << 0) | (1 << 3)  // the window without its frame, at the screen's resolution
        guard let image = capture(.null, 1 << 3, UInt32(window.windowNumber), bounds)?.takeRetainedValue(),
              let probe = Pixels(image, scale: scale), image.width >= 440,
              probe.area(where: { $0.allSatisfy { $0 < 8 } }) < 0.9 * 440 * height else {
            throw XCTSkip("окно не снялось: стекло судит глаз родителя")
        }
        return image
    }
}
#else
import XCTest

final class GlassSnapshotTests: XCTestCase {
    /// The real glass needs the Mac's window server: on Linux the tests skip visibly (П34).
    func testTheRealGlassKeepsThePlateWhiteAndTheSignPlum() throws {  // F3
        throw XCTSkip("настоящее стекло — только на Mac")
    }

    func testGlassButtonsFadeWhenDisabled() throws {  // F4
        throw XCTSkip("стеклянные кнопки — только на Mac")
    }
}
#endif
