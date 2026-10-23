import AllyVoice
import XCTest

/// Supertonic in Swift on ORT 1.28.0 through the C API against the Python reference with the reference's own noise: the
/// stand on ORT 1.24.2 through the ObjC wrapper gave 82.6 dB on these five phrases (local/spike/tts-swift).
final class SupertonicParityTests: XCTestCase {
    func testF2MatchesPythonReference() throws { // Z2
        let engine = try Fixtures.engine(), folder = try Fixtures.references("F2")
        let texts = try Fixtures.jsonLines(folder.appendingPathComponent("jobs.jsonl"))
            .reduce(into: [String: String]()) { $0[$1["id"] as? String ?? ""] = $1["text"] as? String }
        let rows = try Fixtures.jsonLines(folder.appendingPathComponent("manifest.jsonl"))
        XCTAssertEqual(rows.count, 5)
        for row in rows {
            try checkPhrase(row, text: texts[row["id"] as? String ?? ""] ?? "", style: "F2", in: folder, engine)
        }
    }

    func testMixedStyleMatchesPythonReference() throws { // Z3
        let engine = try Fixtures.engine(), folder = try Fixtures.references("mix")
        let style = try engine.style("F2+F5:0.5"), f2 = try engine.style("F2"), f5 = try engine.style("F5")
        let reference = try Fixtures.floats(folder.appendingPathComponent("style.f32"))
        XCTAssertEqual(reference.count, style.ttl.count + style.dp.count)
        for (index, value) in (style.ttl + style.dp).enumerated() {
            let mean = ((f2.ttl + f2.dp)[index] + (f5.ttl + f5.dp)[index]) / 2
            XCTAssertEqual(value, reference[index], accuracy: 1e-6)
            XCTAssertEqual(value, mean, accuracy: 1e-6)
        }
        for row in try Fixtures.jsonLines(folder.appendingPathComponent("manifest.jsonl")) {
            try checkPhrase(row, text: row["text"] as? String ?? "", style: "F2+F5:0.5", in: folder, engine)
        }
    }

    private func checkPhrase(_ row: [String: Any], text: String, style: String, in folder: URL,
                             _ engine: SupertonicEngine) throws {
        let id = try XCTUnwrap(row["id"] as? String)
        let noise = try Fixtures.floats(folder.appendingPathComponent("\(id).noise.f32"))
        let reference = try Fixtures.floats(folder.appendingPathComponent("\(id).f32"))
        let audio = try engine.synthesize(text, voice: VoicePreset(style: style, speed: 1.05, steps: 8), noise: noise)
        let snr = Fixtures.snr(audio.samples, reference)
        Fixtures.log("\(style) \(id): \(audio.samples.count) отсчётов, SNR \(String(format: "%.1f", snr)) дБ, "
                     + "длительность \(audio.duration)")
        XCTAssertEqual(audio.samples.count, row["samples"] as? Int, id)
        XCTAssertGreaterThanOrEqual(snr, 60, id)
        XCTAssertEqual(audio.duration, try XCTUnwrap(row["duration_pred"] as? Double), accuracy: 1e-6, id)
        XCTAssertEqual(audio.rate, 44_100)
    }
}
