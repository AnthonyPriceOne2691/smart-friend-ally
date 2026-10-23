import AllyCore
import AllyHearing
import AllySherpa
import Darwin
import XCTest

/// A clip of the ASR study's manifests and a hypothesis of the speech-in spike (2026-10-19, ORT 1.28.2).
private struct Clip: Decodable { let id: String, wav: String }
private struct Hypothesis: Decodable { let id: String, hyp: String }

/// GigaAM-v3 CTC int8 as the ASR study downloaded it, and the same weights as external data (de-risk 2026-10-23).
private let study = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
    "models/asr/sherpa-onnx-nemo-ctc-giga-am-v3-russian-2025-12-16/sherpa-onnx-nemo-ctc-giga-am-v3-russian-2025-12-16")
private let external = localData.appendingPathComponent("spike/speech-in-ort/models/gigaam-ctc-extdata")

/// What iOS limits, in MB: `phys_footprint` of this process.
private func footprint() -> Double {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
    _ = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    return Double(info.phys_footprint) / 1_048_576
}

final class GigaAMTests: XCTestCase {
    /// The clips of a manifest and the spike's hypotheses for them; nil when the public sets are not on this Mac.
    private func set(_ name: String, spike: String) -> (clips: [Clip], expected: [String: String])? {
        let manifests = localData.appendingPathComponent("research/asr/manifests")
        let results = localData.appendingPathComponent("spike/speech-in/results/asr")
        guard let lines = try? String(contentsOf: manifests.appendingPathComponent(name), encoding: .utf8),
              let hyps = try? String(contentsOf: results.appendingPathComponent(spike), encoding: .utf8)
        else { return nil }
        let decoder = JSONDecoder()
        let clips = lines.split(separator: "\n").compactMap { try? decoder.decode(Clip.self, from: Data($0.utf8)) }
        let expected = hyps.split(separator: "\n").compactMap {
            try? decoder.decode(Hypothesis.self, from: Data($0.utf8))
        }
        return (clips, Dictionary(uniqueKeysWithValues: expected.map { ($0.id, $0.hyp) }))
    }

    /// How many hypotheses equal the spike's: each WAV read as 16 kHz mono float.
    private func same(_ recognizer: GigaAMRecognizer, _ clips: [Clip], _ expected: [String: String],
                      peak: inout Double) throws -> Int {
        var equal = 0
        for clip in clips {
            let samples = try wave(URL(fileURLWithPath: clip.wav))
            equal += recognizer.decode(samples) == expected[clip.id] ? 1 : 0
            peak = max(peak, footprint())
        }
        return equal
    }

    /// The WAV as sherpa reads it — the way the spike read it.
    private func wave(_ url: URL) throws -> [Float] {
        guard let wave = SherpaOnnxReadWave(url.path) else { throw CocoaError(.fileReadCorruptFile) }
        defer { SherpaOnnxFreeWave(wave) }
        return Array(UnsafeBufferPointer(start: wave.pointee.samples, count: Int(wave.pointee.num_samples)))
    }

    func testGigaAMHypothesesAreTheSpikes() throws {  // U23
        guard let cv = set("cv.jsonl", spike: "ctc_cv.jsonl"), let noisy = set("cv_child_noise.jsonl",
                                                                            spike: "ctc_cv_child_noise.jsonl"),
              let recognizer = GigaAMRecognizer(model: study.appendingPathComponent("model.int8.onnx"),
                                                tokens: study.appendingPathComponent("tokens.txt"))
        else { throw XCTSkip("U23 пропущен: нет GigaAM в ~/models или наборов в local/ — паритет не проверен") }
        var peak = 0.0
        XCTAssertEqual(cv.clips.count, 300)
        XCTAssertEqual(try same(recognizer, cv.clips, cv.expected, peak: &peak), 300)
        XCTAssertEqual(noisy.clips.count, 88)
        XCTAssertEqual(try same(recognizer, noisy.clips, noisy.expected, peak: &peak), 88)
    }

    func testExternalDataGivesTheSameHypothesesInLessMemory() throws {  // U24
        let before = footprint()
        guard let cv = set("cv.jsonl", spike: "ctc_cv.jsonl"),
              let recognizer = GigaAMRecognizer(model: external.appendingPathComponent("model.int8.onnx"),
                                                tokens: external.appendingPathComponent("tokens.txt"))
        else { throw XCTSkip("U24 пропущен: нет весов external data в local/ — память не проверена") }
        let loaded = footprint() - before
        var peak = 0.0
        XCTAssertEqual(try same(recognizer, cv.clips, cv.expected, peak: &peak), 300)
        XCTAssertLessThanOrEqual(loaded, 450)
        XCTAssertLessThanOrEqual(peak - before, 500)
    }
}
