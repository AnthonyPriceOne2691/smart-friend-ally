#if canImport(SwiftUI) && os(macOS)
import Accelerate
import ImageIO
import ShellUI
import SwiftUI
import XCTest

/// How the catalogs store the icon (app-icon): `ImageRenderer` draws the 440-pt square at 1024 px — the first picture
/// of a fresh process can come out empty and is drawn again (L137) — then the renderer's dither leaves the smooth
/// areas and the picture loses its alpha. Without that step the PNG weighs ≈ 1 MB and the gate's limit is 512 KiB.
@MainActor
enum IconPicture {
    /// The catalogs of the app and of the demo, in the repository.
    static let app = repository("App/Resources/Assets.xcassets/AppIcon.appiconset")
    static let demo = repository("App/Demo/Assets.xcassets/AppIcon.appiconset")

    /// What the script puts into the catalogs, under the names the test saves them with.
    static var all: [(String, AnyView)] {
        [("AppIcon.png", AnyView(IconScene())), ("AppIcon-night.png", AnyView(IconScene(night: true))),
         ("AppIcon-demo.png", AnyView(DemoIcon()))]
    }

    /// A smooth area: the 5 × 5 neighbourhood of a channel spans ≤ 6 levels and the pixel is within 3 of its mean.
    static let radius = 2, span = 6, reach = 3

    /// Each picture is drawn once per test process: the tests share them.
    private static var drawn: [String: CGImage] = [:]

    static func render(_ name: String) -> CGImage? {
        if let image = drawn[name] { return image }
        guard let view = all.first(where: { $0.0 == name })?.1, let image = render(view) else { return nil }
        drawn[name] = image
        return image
    }

    static func render(_ view: some View) -> CGImage? {
        guard let image = drawing(view) else { return nil }
        return picture(smooth(bytes(image), width: image.width, height: image.height), width: image.width,
                       height: image.height)
    }

    /// What `ImageRenderer` draws, with its alpha: an empty first picture is drawn again (L137).
    static func drawing(_ view: some View) -> CGImage? {
        for _ in 0..<3 {
            let renderer = ImageRenderer(content: view.frame(width: 440, height: 440))
            renderer.scale = 1024.0 / 440
            guard let image = renderer.cgImage else { continue }
            let raw = bytes(image)
            if stride(from: 3, to: raw.count, by: 4).contains(where: { raw[$0] > 0 }) { return image }
        }
        return nil
    }

    /// RGBA bytes of the picture drawn into sRGB with premultiplied alpha.
    static func bytes(_ image: CGImage) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: image.width * image.height * 4)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: &buffer, width: image.width, height: image.height, bitsPerComponent: 8,
                                  bytesPerRow: image.width * 4, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return [] }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return buffer
    }

    /// How many pixels are not fully opaque.
    static func translucent(_ image: CGImage) -> Int {
        let raw = bytes(image)
        return stride(from: 3, to: raw.count, by: 4).filter { raw[$0] < 255 }.count
    }

    /// The renderer's dither out of the smooth areas, channel by channel: the channel takes the rounded mean of its
    /// neighbourhood; edges keep their pixels.
    static func smooth(_ rgba: [UInt8], width: Int, height: Int) -> [UInt8] {
        var out = rgba
        for channel in 0..<3 {
            let plane = stride(from: channel, to: rgba.count, by: 4).map { rgba[$0] }
            let near = neighbourhood(plane, width: width, height: height)
            for index in plane.indices where Int(near.hi[index]) - Int(near.lo[index]) <= span
                && abs(Int(plane[index]) - Int(near.mean[index])) <= reach {
                out[index * 4 + channel] = near.mean[index]
            }
        }
        return out
    }

    /// The lowest, the highest and the rounded mean of each pixel's 5 × 5 neighbourhood.
    struct Neighbourhood {
        let lo: [UInt8], hi: [UInt8], mean: [UInt8]
    }

    /// The neighbourhoods of a channel by vImage: the minimum and the maximum take the pixels inside the picture, the
    /// mean repeats the edge.
    private static func neighbourhood(_ plane: [UInt8], width: Int, height: Int) -> Neighbourhood {
        var (source, lo, hi, mean) = (plane, plane, plane, plane)
        let side = vImagePixelCount(2 * radius + 1)
        let frame = { (bytes: UnsafeMutableRawBufferPointer) in
            vImage_Buffer(data: bytes.baseAddress, height: vImagePixelCount(height), width: vImagePixelCount(width),
                          rowBytes: width)
        }
        source.withUnsafeMutableBytes { input in
            var from = frame(input)
            lo.withUnsafeMutableBytes { output in
                var into = frame(output)
                _ = vImageMin_Planar8(&from, &into, nil, 0, 0, side, side, vImage_Flags(kvImageNoFlags))
            }
            hi.withUnsafeMutableBytes { output in
                var into = frame(output)
                _ = vImageMax_Planar8(&from, &into, nil, 0, 0, side, side, vImage_Flags(kvImageNoFlags))
            }
            mean.withUnsafeMutableBytes { output in
                var into = frame(output)
                _ = vImageBoxConvolve_Planar8(&from, &into, nil, 0, 0, UInt32(side), UInt32(side), 0,
                                              vImage_Flags(kvImageEdgeExtend))
            }
        }
        return Neighbourhood(lo: lo, hi: hi, mean: mean)
    }

    /// An opaque sRGB picture of RGBA bytes whose alpha is skipped: a PNG of it carries no alpha channel.
    static func picture(_ rgba: [UInt8], width: Int, height: Int) -> CGImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let provider = CGDataProvider(data: Data(rgba) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: space, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }

    /// The picture made smaller with Core Graphics at high quality, as the phone shows a small icon.
    static func scaled(_ image: CGImage, to side: Int) -> CGImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        return ctx.makeImage()
    }

    static func decode(_ url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    /// The mean difference of the colour channels in levels, and the share of pixels off by more than 16 in a channel.
    static func difference(_ one: CGImage, _ other: CGImage) -> (mean: Double, far: Double) {
        let (left, right) = (bytes(one), bytes(other))
        guard left.count == right.count, !left.isEmpty else { return (255, 1) }
        var (total, far) = (0, 0)
        for pixel in stride(from: 0, to: left.count, by: 4) {
            let gaps = (0..<3).map { abs(Int(left[pixel + $0]) - Int(right[pixel + $0])) }
            total += gaps.reduce(0, +)
            if gaps.contains(where: { $0 > 16 }) { far += 1 }
        }
        let pixels = Double(left.count / 4)
        return (Double(total) / (pixels * 3), Double(far) / pixels)
    }

    /// An image of a catalog's `Contents.json`: its file, whether it is the dark theme's, idiom, platform and size.
    struct Entry {
        let file: String, dark: Bool, form: [String]
    }

    static func entries(_ folder: URL) throws -> [Entry] {
        let data = try Data(contentsOf: folder.appendingPathComponent("Contents.json"))
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let images = try XCTUnwrap(json["images"] as? [[String: Any]])
        return images.map { image in
            let looks = image["appearances"] as? [[String: String]] ?? []
            let dark = looks.contains { $0["appearance"] == "luminosity" && $0["value"] == "dark" }
            let form = ["idiom", "platform", "size"].map { image[$0] as? String ?? "" }
            return Entry(file: image["filename"] as? String ?? "", dark: dark, form: form)
        }
    }

    /// A path of the repository, found from this file (Packages/AllyShell/Tests/ShellUITests).
    static func repository(_ path: String) -> URL {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return root.appendingPathComponent(path)
    }
}
#endif
