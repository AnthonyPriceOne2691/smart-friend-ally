#if canImport(SwiftUI) && os(macOS)
import ImageIO
import ShellCore
import ShellUI
import SwiftUI
import XCTest

/// The app's icon (app-icon; variant В — the parent's choice 2026-10-29): `IconScene` rendered the way the catalogs
/// store it — `IconPicture` — into `local/shell-snapshots/icon/` (outside git) for `scripts/render_app_icon.sh`, and
/// the catalogs of the app and the demo held to it: the icon is reproducible from the code.
@MainActor
final class IconTests: XCTestCase {
    /// Day, night and the demo, saved for the script (I7): 1024 × 1024 sRGB. The drawing covers every pixel — a pixel
    /// left transparent would turn black once the picture loses its alpha.
    func testTheIconsRenderOpaqueAt1024() throws {  // I1
        let folder = try snapshots("icon")
        for (name, view) in IconPicture.all {
            XCTAssertEqual(IconPicture.translucent(try XCTUnwrap(IconPicture.drawing(view), name)), 0, name)
            let image = try XCTUnwrap(IconPicture.render(name), name)
            XCTAssertEqual([image.width, image.height], [1024, 1024], name)
            XCTAssertEqual(image.colorSpace?.name, CGColorSpace.sRGB, name)
            try save(image, to: folder.appendingPathComponent(name))
        }
    }

    /// The app's catalog: the day and its night pair for the dark theme; the demo's: one icon. All 1024 × 1024 PNG
    /// without alpha.
    func testTheCatalogsHoldTheDayTheNightAndTheDemo() throws {  // I2
        let app = try IconPicture.entries(IconPicture.app)
        XCTAssertEqual(app.map(\.file), ["AppIcon.png", "AppIcon-night.png"])
        XCTAssertEqual(app.map(\.dark), [false, true])
        let demo = try IconPicture.entries(IconPicture.demo)
        XCTAssertEqual(demo.map(\.file), ["AppIcon.png"])
        XCTAssertEqual(demo.map(\.dark), [false])
        for (folder, entry) in app.map({ (IconPicture.app, $0) }) + demo.map({ (IconPicture.demo, $0) }) {
            XCTAssertEqual(entry.form, ["universal", "ios", "1024x1024"], entry.file)
            let image = try XCTUnwrap(IconPicture.decode(folder.appendingPathComponent(entry.file)), entry.file)
            XCTAssertEqual([image.width, image.height], [1024, 1024], entry.file)
            XCTAssertTrue([.none, .noneSkipLast, .noneSkipFirst].contains(image.alphaInfo), entry.file)
        }
    }

    /// The PNG of each catalog against a fresh render of the code: off by ≤ 1 level on average, ≤ 0.5% of the pixels
    /// off by more than 16 — a drawing changed without `render_app_icon.sh` turns this red.
    func testTheCatalogsMatchTheCode() throws {  // I3
        let stored = [IconPicture.app.appendingPathComponent("AppIcon.png"),
                      IconPicture.app.appendingPathComponent("AppIcon-night.png"),
                      IconPicture.demo.appendingPathComponent("AppIcon.png")]
        for ((name, _), url) in zip(IconPicture.all, stored) {
            let fresh = try XCTUnwrap(IconPicture.render(name), name)
            let kept = try XCTUnwrap(IconPicture.decode(url), name)
            let (mean, far) = IconPicture.difference(fresh, kept)
            XCTAssertLessThanOrEqual(mean, 1, "\(name) mean \(mean)")
            XCTAssertLessThanOrEqual(far, 0.005, "\(name) far \(far)")
        }
    }

    /// At 60 pt (180 px of the phone) and 29 pt (87 px) her eyes and the bubble's rim are still there, by day and by
    /// night; thresholds ≈ 0.7 of the stand's variant В (eyes 524 and 92, rim 603 and 596 at night).
    func testTheEyesAndTheRimReadSmall() throws {  // I4
        let eyes = { (rgb: [Int]) in Tone(UInt32(rgb[0] << 16 | rgb[1] << 8 | rgb[2])).luminance < 0.06 }
        let rim = { (rgb: [Int]) in near(rgb, 0xC2185B, 40) }
        for night in [false, true] {
            let big = try XCTUnwrap(IconPicture.render(night ? "AppIcon-night.png" : "AppIcon.png"))
            let home = try XCTUnwrap(Pixels(try XCTUnwrap(IconPicture.scaled(big, to: 180)), scale: 1))
            let settings = try XCTUnwrap(Pixels(try XCTUnwrap(IconPicture.scaled(big, to: 87)), scale: 1))
            XCTAssertGreaterThanOrEqual(home.area(where: eyes), 360, "night \(night)")
            XCTAssertGreaterThanOrEqual(settings.area(where: eyes), 60, "night \(night)")
            XCTAssertGreaterThanOrEqual(home.area(where: rim), 420, "night \(night)")
        }
    }
}

/// The demo's icon: the day icon with a raspberry capsule and the white word «демо» at the bottom. Only the demo
/// carries it — it lives in the simulator on the Mac and never goes to the phone; `ShellUI` itself draws no words
/// (rule 1, SwiftLint `child_screen_text`).
struct DemoIcon: View {
    var body: some View {
        IconScene().overlay(alignment: .bottom) {
            let raspberry = Palette.raspberry
            Text("демо").font(.system(size: 60, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                .padding(.horizontal, 32).frame(height: 86)
                .background(Capsule().fill(Color(.sRGB, red: raspberry.red, green: raspberry.green,
                                                 blue: raspberry.blue)))
                .padding(.bottom, 22)
        }
    }
}
#else
import XCTest

final class IconTests: XCTestCase {
    /// The icon is drawn by SwiftUI and ImageRenderer: on Linux the tests are skipped visibly (П34), the Mac runs them.
    func testTheIconsRenderOpaqueAt1024() throws {  // I1
        throw XCTSkip("значок — только на Mac")
    }

    func testTheCatalogsHoldTheDayTheNightAndTheDemo() throws {  // I2
        throw XCTSkip("каталоги значка — только на Mac")
    }

    func testTheCatalogsMatchTheCode() throws {  // I3
        throw XCTSkip("сверка значка с кодом — только на Mac")
    }

    func testTheEyesAndTheRimReadSmall() throws {  // I4
        throw XCTSkip("значок в малых размерах — только на Mac")
    }
}
#endif
