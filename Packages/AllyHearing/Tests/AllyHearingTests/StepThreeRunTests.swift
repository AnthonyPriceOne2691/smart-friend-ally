import AllyCore
@testable import StepThreeTool
import XCTest

/// A Common Voice clip of the ASR study and the speech-in spike's GigaAM hypothesis for it — public data in `local/`.
private struct Clip: Decodable { let id: String, ref: String, wav: String }
private struct Hypothesis: Decodable { let id: String, hyp: String }

final class StepThreeRunTests: XCTestCase {
    private var root: URL?

    override func tearDownWithError() throws {
        if let root { try FileManager.default.removeItem(at: root) }
    }

    /// A synthetic export: 20 clips with an invented `heard` (every other one loses its first word) and the three
    /// skips — the live GigaAM, no sound, no reference.
    func testTheExportGivesOnlySumsAndNoTextOfTheClips() throws {  // U27
        let weights = localData.appendingPathComponent("spike/speech-in-ort/models/gigaam-ctc-extdata")
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
        let gigaam = hyps.split(separator: "\n").compactMap {
            try? decoder.decode(Hypothesis.self, from: Data($0.utf8))
        }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session = root.appendingPathComponent("2026-10-26T10-00-00Z-abcd1234")
        self.root = root
        try FileManager.default.createDirectory(at: session, withIntermediateDirectories: true)
        var refs = ["session,turn,ref"], heard: [String] = []
        for (turn, clip) in clips.enumerated() {
            let words = clip.ref.split(separator: " ")
            heard.append(turn.isMultiple(of: 2) ? words.dropFirst().joined(separator: " ") : clip.ref)
            try write(session, turn, heard: heard[turn], audio: clip.wav)
            refs.append("\(session.lastPathComponent),\(turn),\(clip.ref)")
        }
        try write(session, 20, heard: "мурка", audio: clips[0].wav, asr: "gigaam-v3-ctc:224757733")
        try write(session, 21, heard: "тёма", audio: nil)
        try write(session, 22, heard: "соня", audio: clips[1].wav)
        refs += ["\(session.lastPathComponent),20,мурка", "\(session.lastPathComponent),21,тёма"]
        let hearing = try Hearing.decode(Data(contentsOf: repo.appendingPathComponent("App/Resources/hearing.json")))
        let run = try StepThreeRun.run(export: root, refs: StepThreeRun.references(refs.joined(separator: "\n")),
                                       hearing: hearing, models: weights)
        XCTAssertEqual([run.compared, run.lines.count], [20, 6])
        XCTAssertEqual(run.lines.first, "шаг 3: реплик 20; пропущено — без эталона 1, без звука 1, с живым GigaAM 1")
        XCTAssertEqual(run.lines[4], "модели: GigaAM gigaam-v3-ctc:224757733 sha256 02a443f4 fa9a4816 17cc5144; "
                       + "dictation iOS 27.0")
        XCTAssertTrue(run.lines[5].hasPrefix("вердикт: "))
        let output = run.lines.joined(separator: "\n").lowercased()
        let texts = clips.map(\.ref) + heard + gigaam.filter { hyp in clips.contains { $0.id == hyp.id } }.map(\.hyp)
        XCTAssertEqual(texts.count, 60)
        XCTAssertEqual(texts.filter { text in
            [text.lowercased(), StepThree.normalize(text).joined(separator: " ")]
                .contains { !$0.isEmpty && output.contains($0) }
        }, [])
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
