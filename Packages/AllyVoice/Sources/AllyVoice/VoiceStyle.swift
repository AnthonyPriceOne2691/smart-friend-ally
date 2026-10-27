import Foundation

/// A voice of Supertonic: the style vectors `style_ttl` [1, 50, 256] and `style_dp` [1, 8, 16] from
/// `voice_styles/<name>.json`, parsed as Double and narrowed to Float — the rounding of numpy's `np.array(…, float32)`.
public struct VoiceStyle: Sendable, Equatable {
    public let ttl: [Float], ttlShape: [Int], dp: [Float], dpShape: [Int]

    private struct Component: Decodable {
        let dims: [Int], data: [[[Double]]]
    }

    private struct File: Decodable {
        let styleTtl: Component, styleDp: Component
    }

    init(ttl: [Float], ttlShape: [Int], dp: [Float], dpShape: [Int]) {
        (self.ttl, self.ttlShape, self.dp, self.dpShape) = (ttl, ttlShape, dp, dpShape)
    }

    static func load(_ url: URL) throws -> VoiceStyle {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let file = try decoder.decode(File.self, from: Data(contentsOf: url))
        func flat(_ part: Component) throws -> [Float] {
            let values = part.data.flatMap { $0.flatMap { $0 } }.map(Float.init)
            guard values.count == part.dims.reduce(1, *) else {
                throw SpeechError.badModel("style \(url.lastPathComponent): \(values.count) values for \(part.dims)")
            }
            return values
        }
        return VoiceStyle(ttl: try flat(file.styleTtl), ttlShape: file.styleTtl.dims,
                          dp: try flat(file.styleDp), dpShape: file.styleDp.dims)
    }

    /// "F2" — a voice of the model; "F2+F5:0.5" — the linear mix (1 − w)·A + w·B of both vectors, as the stand's
    /// `style_for` and the Voice Mixer do.
    static func resolve(_ spec: String, in folder: URL) throws -> VoiceStyle {
        let voice = { (name: String) in try load(folder.appendingPathComponent("\(name).json")) }
        guard let plus = spec.firstIndex(of: "+") else { return try voice(spec) }
        let rest = spec[spec.index(after: plus)...].split(separator: ":")
        guard rest.count == 2, let weight = Float(rest[1]) else { throw SpeechError.badModel("style \(spec)") }
        return try voice(String(spec[..<plus])).mixed(with: voice(String(rest[0])), weight: weight)
    }

    func mixed(with other: VoiceStyle, weight: Float) -> VoiceStyle {
        let blend = { (a: [Float], b: [Float]) in zip(a, b).map { (1 - weight) * $0 + weight * $1 } }
        return VoiceStyle(ttl: blend(ttl, other.ttl), ttlShape: ttlShape, dp: blend(dp, other.dp), dpShape: dpShape)
    }
}
