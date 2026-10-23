import Foundation

/// Text → Supertonic input ids, step by step as `UnicodeProcessor._preprocess_text` of supertonic-py 1.3.1, on Unicode
/// scalars: combining marks — U+0301 (stress), U+0308 and U+0306 from NFKD of «ё» and «й» — stay separate scalars the
/// way Python sees them. One Russian sentence per call: no language list and no chunking (the stand's other half).
struct SupertonicText {
    let indexer: [Int64]
    static let lang = "ru"

    init(indexerURL: URL) throws {
        indexer = try JSONDecoder().decode([Int64].self, from: Data(contentsOf: indexerURL))
        if indexer.isEmpty { throw SpeechError.badModel("unicode_indexer.json is empty") }
    }

    /// Python `_SYMBOL_REPLACEMENTS`: single scalars, no value is a key, so one pass equals the sequential replaces.
    private static let symbols: [UInt32: UInt32] = [
        0x2013: 0x2D, 0x2011: 0x2D, 0x2014: 0x2D,  // – ‑ — → -
        0x00AF: 0x20, 0x5F: 0x20,  // ¯ _ → space
        0x201C: 0x22, 0x201D: 0x22,  // “ ” → "
        0x2018: 0x27, 0x2019: 0x27, 0x00B4: 0x27, 0x60: 0x27,  // ‘ ’ ´ ` → '
        0x5B: 0x20, 0x5D: 0x20, 0x7C: 0x20, 0x2F: 0x20, 0x23: 0x20, 0x2192: 0x20, 0x2190: 0x20,  // [ ] | / # → ←
    ]
    private static let decorative: Set<UInt32> = [0x2665, 0x2606, 0x2661, 0x00A9, 0x5C]  // ♥ ☆ ♡ © \
    private static let endings = Set(".!?;:,'\"')]}…。」』】〉》›»".unicodeScalars.map(\.value))
    private static let emoji: [ClosedRange<UInt32>] = [
        0x1F600...0x1F64F, 0x1F300...0x1F5FF, 0x1F680...0x1F6FF, 0x1F700...0x1F77F, 0x1F780...0x1F7FF,
        0x1F800...0x1F8FF, 0x1F900...0x1F9FF, 0x1FA00...0x1FA6F, 0x1FA70...0x1FAFF, 0x2600...0x26FF, 0x2700...0x27BF,
        0x1F1E6...0x1F1FF,
    ]
    private static let abbreviations = [("@", " at "), ("e.g.,", "for example, "), ("i.e.,", "that is, ")]
    private static let spacing = [(" ,", ","), (" .", "."), (" !", "!"), (" ?", "?"), (" ;", ";"), (" :", ":"),
                                  (" '", "'")]

    /// The text as the model reads it: «<ru>…</ru>».
    func preprocess(_ text: String) -> String {
        var scalars = Array(text.decomposedStringWithCompatibilityMapping.unicodeScalars)
        scalars.removeAll { value in Self.emoji.contains { $0.contains(value.value) } }
        scalars = scalars.map { Self.symbols[$0.value].flatMap(Unicode.Scalar.init) ?? $0 }
        scalars.removeAll { Self.decorative.contains($0.value) }
        for (from, to) in Self.abbreviations + Self.spacing { scalars = Self.replace(scalars, from, to) }
        scalars = Self.squeezeQuotes(scalars)
        scalars = Self.squeezeSpaces(scalars)
        if !(scalars.last.map { Self.endings.contains($0.value) } ?? false) { scalars.append(".") }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: "<\(Self.lang)>".unicodeScalars)
        view.append(contentsOf: scalars)
        view.append(contentsOf: "</\(Self.lang)>".unicodeScalars)
        return String(view)
    }

    /// Model ids of the preprocessed text; scalars the model does not know are dropped (Python would raise).
    func encode(_ text: String) -> [Int64] {
        preprocess(text).unicodeScalars.compactMap { scalar in
            let code = Int(scalar.value)
            return code < indexer.count && indexer[code] >= 0 ? indexer[code] : nil
        }
    }

    /// Left-to-right, non-overlapping replacement of a literal, as `str.replace`.
    private static func replace(_ text: [Unicode.Scalar], _ from: String, _ to: String) -> [Unicode.Scalar] {
        let pattern = Array(from.unicodeScalars), replacement = Array(to.unicodeScalars)
        guard text.count >= pattern.count else { return text }
        var out: [Unicode.Scalar] = [], index = 0
        out.reserveCapacity(text.count)
        while index < text.count {
            if index + pattern.count <= text.count, text[index..<(index + pattern.count)].elementsEqual(pattern) {
                out += replacement
                index += pattern.count
            } else {
                out.append(text[index])
                index += 1
            }
        }
        return out
    }

    /// `(["'`])\1+` → `\1`.
    private static func squeezeQuotes(_ text: [Unicode.Scalar]) -> [Unicode.Scalar] {
        var out: [Unicode.Scalar] = []
        for scalar in text where !(out.last == scalar && "\"'`".unicodeScalars.contains(scalar)) { out.append(scalar) }
        return out
    }

    /// `\s+` → one space, trimmed.
    private static func squeezeSpaces(_ text: [Unicode.Scalar]) -> [Unicode.Scalar] {
        var out: [Unicode.Scalar] = []
        for scalar in text {
            let space = scalar.properties.isWhitespace
            if space && (out.isEmpty || out.last == " ") { continue }
            out.append(space ? " " : scalar)
        }
        if out.last == " " { out.removeLast() }
        return out
    }
}
