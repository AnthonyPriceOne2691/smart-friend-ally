import AllyCore
import AllyHearing
import AllyOnnx
import XCTest

/// The repository of this file and its `local/` with the data outside git: a worktree's `.git` is a file naming a
/// gitdir inside the main clone's `.git/worktrees`, and the main clone keeps `local/`.
private let repo = URL(fileURLWithPath: #filePath).appendingPathComponent("../../../../..").standardized
private let localData: URL = {
    let git = (try? String(contentsOf: repo.appendingPathComponent(".git"), encoding: .utf8)) ?? ""
    guard git.hasPrefix("gitdir: ") else { return repo.appendingPathComponent("local") }
    let gitdir = URL(fileURLWithPath: git.dropFirst(8).trimmingCharacters(in: .whitespacesAndNewlines))
    return gitdir.appendingPathComponent("../../../local").standardized
}()

/// A phrase of the spike's end-of-turn set and its trace: Silero's flags per window, run-length encoded.
private struct Phrase: Decodable { let id: String, wav: String }
private struct Trace: Decodable { let id: String, rle: [[Int]]? }

final class SileroTests: XCTestCase {
    private func shipped() throws -> Hearing {
        try Hearing.decode(Data(contentsOf: repo.appendingPathComponent("App/Resources/hearing.json")))
    }

    /// The pair linked into this process on the Mac: ORT 1.28.0 serves API 28 (and not 29), sherpa is 1.13.8 — Silero.
    func testThisProcessHasSherpasPairAndListensWithSilero() throws {  // U16
        let pair = OnnxPair.current
        XCTAssertEqual([pair.ort, pair.sherpa], ["1.28.0", "1.13.8"])
        XCTAssertEqual(pair.api, 28)
        XCTAssertTrue(pair.served)
        XCTAssertFalse(OnnxRuntime.serves(api: 29))
        let choice = try shipped().listening(pair: { pair }, fileBytes: { _ in 2_327_524 })
        XCTAssertEqual(choice.line, "слух: Silero · sherpa 1.13.8 · ORT 1.28.0")
    }

    /// Silero with the registry's parameters on the first 100 phrases of the spike's end-of-turn set: its flags per
    /// window are the spike's (2026-10-19, ORT 1.28.2) — public and synthetic audio only.
    func testSileroFlagsAreTheSpikesOnTheFirstHundredPhrases() throws {  // U17
        let spike = localData.appendingPathComponent("spike/speech-in")
        let model = spike.appendingPathComponent("models/silero_vad.onnx")
        guard let manifest = try? String(contentsOf: spike.appendingPathComponent("data/eot.jsonl"), encoding: .utf8),
              let traces = try? String(contentsOf: spike.appendingPathComponent("results/trace/all.jsonl"),
                                       encoding: .utf8),
              FileManager.default.fileExists(atPath: model.path) else {
            throw XCTSkip("U17 пропущен: нет модели Silero или набора спайка в local/ — паритет не проверен")
        }
        let hearing = try shipped(), settings = try XCTUnwrap(hearing.vad)
        XCTAssertEqual([settings.threshold, settings.minSpeech, settings.minSilence], [0.5, 0.25, 0.1])
        let vad = try XCTUnwrap(SileroVAD(model: model, vad: settings, maxSpeech: hearing.turn.maxTurn))
        let decoder = JSONDecoder(), runs = Dictionary(uniqueKeysWithValues: try traces.split(separator: "\n").map {
            let trace = try decoder.decode(Trace.self, from: Data($0.utf8))
            return (trace.id, trace.rle ?? [])
        })
        let phrases = try manifest.split(separator: "\n").prefix(100).map {
            try decoder.decode(Phrase.self, from: Data($0.utf8))
        }
        var same = 0
        for phrase in phrases {
            let audio = try samples(spike.appendingPathComponent("data/eot")
                .appendingPathComponent(URL(fileURLWithPath: phrase.wav).lastPathComponent))
            vad.reset()
            let flags = stride(from: 0, through: audio.count - SileroVAD.window, by: SileroVAD.window).map {
                vad.accept(Array(audio[$0..<$0 + SileroVAD.window]))
            }
            if encoded(flags) == runs[phrase.id] { same += 1 }
        }
        XCTAssertEqual(phrases.count, 100)
        XCTAssertEqual(same, 100)
    }

    /// The spike's run-length code: [flag, windows] per run; no speech at all — no runs.
    private func encoded(_ flags: [Bool]) -> [[Int]] {
        guard flags.contains(true) else { return [] }
        return flags.reduce(into: [[Int]]()) { runs, flag in
            if let last = runs.last, last[0] == (flag ? 1 : 0) { runs[runs.count - 1][1] += 1 } else {
                runs.append([flag ? 1 : 0, 1])
            }
        }
    }

    /// A 16-bit mono WAV as the spike read it: each sample / 32768.
    private func samples(_ url: URL) throws -> [Float] {
        let data = try Data(contentsOf: url)
        var offset = 12
        while offset + 8 <= data.count {
            let size = Int(data.subdata(in: offset + 4..<offset + 8).withUnsafeBytes {
                $0.loadUnaligned(as: UInt32.self)
            })
            if data.subdata(in: offset..<offset + 4) == Data("data".utf8) {
                let body = data.subdata(in: offset + 8..<min(offset + 8 + size, data.count))
                return body.withUnsafeBytes { raw in
                    (0..<body.count / 2).map {
                        Float(raw.loadUnaligned(fromByteOffset: $0 * 2, as: Int16.self)) / 32_768
                    }
                }
            }
            offset += 8 + size
        }
        throw CocoaError(.fileReadCorruptFile)
    }
}
