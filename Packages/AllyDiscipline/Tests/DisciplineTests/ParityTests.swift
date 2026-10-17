import XCTest
@testable import Discipline

/// One reply of the model and what the Python reference makes of it (Fixtures/make_fixtures.py).
struct ParityPair: Decodable {
    let input: String
    let output: String

    enum CodingKeys: String, CodingKey {
        case input = "in", output = "out"
    }
}

enum Fixture {
    struct Missing: Error {}

    static func pairs() throws -> [ParityPair] {
        guard let url = Bundle.module.url(forResource: "repair_parity", withExtension: "jsonl") else { throw Missing() }
        return try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
            .map { try JSONDecoder().decode(ParityPair.self, from: Data($0.utf8)) }
    }
}

/// The rules that fired on `text`.
func fired(_ text: String) -> Set<String> {
    Set(Repair.apply(text).actions.map(\.rule))
}

/// The first letter in the other case.
func toggleFirstLetter(_ text: String) -> String {
    guard let index = text.firstIndex(where: \.isLetter) else { return text }
    let letter = String(text[index])
    var out = text
    out.replaceSubrange(index...index, with: letter == letter.uppercased() ? letter.lowercased() : letter.uppercased())
    return out
}

/// Noise that must not change which rules fire: ё written as е, extra spaces, the case of the first letter.
let noise: [(name: String, apply: (String) -> String)] = [
    ("ё→е", { $0.replacingOccurrences(of: "ё", with: "е").replacingOccurrences(of: "Ё", with: "Е") }),
    ("extra spaces", { " " + $0.replacingOccurrences(of: " ", with: "  ") + " " }),
    ("first letter case", toggleFirstLetter)
]

final class ParityTests: XCTestCase {
    func testMatchesTheReferenceOnModelReplies() throws {  // C5
        let pairs = try Fixture.pairs()
        XCTAssertEqual(pairs.count, 110)
        let mismatches = pairs.enumerated().compactMap { index, pair -> String? in
            let got = Repair.apply(pair.input).text
            return got.unicodeScalars.elementsEqual(pair.output.unicodeScalars) ? nil : "#\(index + 1): «\(got)»"
        }
        XCTAssertEqual(mismatches, [])
    }

    /// On the fixtures and on the probes (the corpus has no reply that opens with an endearment).
    func testNoiseKeepsTheRulesThatFire() throws {  // C5
        let inputs = try Fixture.pairs().map(\.input) + (violators + cleans).map(\.input)
        let broken = inputs.flatMap { input in
            noise.compactMap { item -> String? in
                fired(item.apply(input)) == fired(input) ? nil : "\(item.name): «\(input)»"
            }
        }
        XCTAssertEqual(broken, [])
    }
}
