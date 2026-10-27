import AllyCore
@testable import StepThreeTool
import XCTest

/// A Common Voice clip of the ASR study and the speech-in spike's GigaAM hypothesis for it — public data in `local/`.
private struct Clip: Decodable { let id: String, ref: String, wav: String }
private struct Hypothesis: Decodable { let id: String, hyp: String }
/// A synthetic export in a temporary folder, the references as `refs.csv` text, the invented live texts.
private struct Export { let root: URL, refs: String, heard: [String] }

private let weights = localData.appendingPathComponent("spike/speech-in-ort/models/gigaam-ctc-extdata")

final class StepThreeRunTests: XCTestCase {
    private var root: URL?

    override func tearDownWithError() throws {
        if let root { try FileManager.default.removeItem(at: root) }
    }

    /// The run's sums are those of the spike's GigaAM hypotheses on the same clips, and no clip's text is in its lines.
    func testTheExportGivesOnlySumsAndNoTextOfTheClips() throws {  // U27
        let (clips, gigaam) = try publicSet()
        let export = try makeExport(clips), heard = export.heard
        let hearing = try Hearing.decode(Data(contentsOf: repo.appendingPathComponent("App/Resources/hearing.json")))
        let run = try StepThreeRun.run(export: export.root, refs: StepThreeRun.references(export.refs),
                                       hearing: hearing, models: weights)
        XCTAssertEqual([run.compared, run.lines.count], [20, 6])
        XCTAssertEqual(run.lines.first, "шаг 3: реплик 20; пропущено — без эталона 1, без звука 1, с живым GigaAM 1")
        XCTAssertEqual(run.lines[4], "модели: GigaAM gigaam-v3-ctc:224757733 sha256 02a443f4 fa9a4816 17cc5144; "
                       + "dictation iOS 27.0")
        let spiked = clips.compactMap { clip in gigaam.first { $0.id == clip.id }?.hyp }
        let expected = StepThree.summary(zip(clips, zip(heard, spiked)).map {
            StepThree.Pair(ref: $0.0.ref, dictation: $0.1.0, gigaam: $0.1.1)
        })
        XCTAssertEqual(Array(run.lines[1...3]) + [run.lines[5]],
                       StepThree.lines(expected, skipped: .init(), models: []).dropFirst().filter {
                           !$0.hasPrefix("модели")
                       })
        let output = run.lines.joined(separator: "\n").lowercased(), texts = clips.map(\.ref) + heard + spiked
        XCTAssertEqual(texts.count, 60)
        XCTAssertEqual(texts.filter { text in
            [text.lowercased(), StepThree.normalize(text).joined(separator: " ")]
                .contains { !$0.isEmpty && output.contains($0) }
        }, [])
    }

    /// The first 20 clips of the study's Common Voice set and the spike's hypotheses; a visible skip without them.
    private func publicSet() throws -> ([Clip], [Hypothesis]) {
        let manifest = localData.appendingPathComponent("research/asr/manifests/cv.jsonl")
        let spike = localData.appendingPathComponent("spike/speech-in/results/asr/ctc_cv.jsonl")
        guard let lines = try? String(contentsOf: manifest, encoding: .utf8),
              let hyps = try? String(contentsOf: spike, encoding: .utf8),
              FileManager.default.fileExists(atPath: weights.appendingPathComponent("model.int8.onnx.data").path)
        else { throw XCTSkip("U27 на Mac пропущен: нет клипов Common Voice или весов GigaAM в local/") }
        let decoder = JSONDecoder()
        let clips = lines.split(separator: "\n").prefix(20).compactMap {
            try? decoder.decode(Clip.self, from: Data($0.utf8))
        }
        return (clips, hyps.split(separator: "\n").compactMap {
            try? decoder.decode(Hypothesis.self, from: Data($0.utf8))
        })
    }

    /// A synthetic export: the clips with an invented `heard` (every other one loses its first word) and the three
    /// skips — the live GigaAM, no sound, no reference; the references as the parent's `refs.csv`.
    private func makeExport(_ clips: [Clip]) throws -> Export {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session = root.appendingPathComponent("2026-10-26T10-00-00Z-abcd1234"), name = session.lastPathComponent
        self.root = root
        try FileManager.default.createDirectory(at: session, withIntermediateDirectories: true)
        var refs = ["session,turn,ref"], heard: [String] = []
        for (turn, clip) in clips.enumerated() {
            let words = clip.ref.split(separator: " ")
            heard.append(turn.isMultiple(of: 2) ? words.dropFirst().joined(separator: " ") : clip.ref)
            try write(session, turn, heard: heard[turn], audio: clip.wav)
            refs.append("\(name),\(turn),\(clip.ref)")
        }
        try write(session, 20, heard: "мурка", audio: clips[0].wav, asr: "gigaam-v3-ctc:224757733")
        try write(session, 21, heard: "тёма", audio: nil)
        try write(session, 22, heard: "соня", audio: clips[1].wav)
        return Export(root: root, refs: (refs + ["\(name),20,мурка", "\(name),21,тёма"]).joined(separator: "\n"),
                      heard: heard)
    }

    /// One record of the box: `NNNN.allybox` — the header line and the JSON — and the WAV beside it, or why it is
    /// missing.
    private func write(_ session: URL, _ turn: Int, heard: String, audio: String?, asr: String = "dictation") throws {
        let name = String(format: "%04d", turn)
        var box: [String: Any] = ["heard": heard, "versions": ["asr": asr, "ios": "27.0"],
                                  "child_audio": ["missing": "silence"]]
        if let audio {
            try FileManager.default.copyItem(at: URL(fileURLWithPath: audio),
                                             to: session.appendingPathComponent(name + "-child.wav"))
            box["child_audio"] = ["file": name + "-child.wav"]
        }
        let json = try JSONSerialization.data(withJSONObject: box, options: [.sortedKeys])
        try (Data("ALLY-BLACKBOX/1\n".utf8) + json + Data("\n".utf8))
            .write(to: session.appendingPathComponent(name + ".allybox"))
    }
}
