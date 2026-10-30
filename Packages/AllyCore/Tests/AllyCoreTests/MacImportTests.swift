@testable import AllyCore
import XCTest

final class MacImportTests: XCTestCase {
    private func registry(_ name: String) throws -> Data {
        try Data(contentsOf: appResources.appendingPathComponent(name))
    }

    /// The folder's list as `scripts/mac_files.py` writes it for the bundle's registries: the weights and Silero with
    /// the registries' sizes and the script's sha256, each voice file with `voice.json`'s size and sha256.
    private func manifest(_ edit: (inout [[String: Any]]) -> Void = { _ in }) throws -> Data {
        let model = try XCTUnwrap(JSONSerialization.jsonObject(with: registry("model.json")) as? [String: Any])
        let hearing = try XCTUnwrap(JSONSerialization.jsonObject(with: registry("hearing.json")) as? [String: Any])
        let voice = try XCTUnwrap(JSONSerialization.jsonObject(with: registry("voice.json")) as? [String: Any])
        let weights = try XCTUnwrap(model["model"] as? [String: Any])
        let vad = try XCTUnwrap(hearing["vad"] as? [String: Any])
        var files: [[String: Any]] = [
            ["path": "Models/\(weights["file"] ?? "")", "bytes": weights["bytes"] ?? 0, "sha256": "85a896a0"],
            ["path": "Models/\(vad["file"] ?? "")", "bytes": vad["bytes"] ?? 0, "sha256": "1a153a22"]
        ]
        for file in try XCTUnwrap(voice["files"] as? [[String: Any]]) {
            files.append(["path": "Voice/\(file["to"] ?? "")", "bytes": file["bytes"] ?? 0,
                          "sha256": file["sha256"] ?? ""])
        }
        edit(&files)
        return try JSONSerialization.data(withJSONObject: ["files": files])
    }

    private func plan(_ list: Data) throws -> [MacImport.Item] {
        try MacImport.plan(manifest: list, model: registry("model.json"), hearing: registry("hearing.json"),
                           voice: registry("voice.json"))
    }

    private func refusal(_ list: Data) throws -> String? {
        do {
            _ = try plan(list)
            return nil
        } catch let refused as MacImport.Refusal {
            return refused.line
        }
    }

    func testThePlanTakesEveryRegistryFileWithItsSizeAndHash() throws {  // N4
        let voice = try VoiceSettings.decode(registry("voice.json"))
        let items = try plan(manifest())
        XCTAssertEqual(items.count, voice.files.count + 2)
        XCTAssertEqual(items.count, 28)  // the registries of 2026-10-29: weights, Silero, 26 voice and accent files
        XCTAssertEqual(items[0], MacImport.Item(path: "Models/gemma-4-E4B-it-Q4_K_M.gguf", bytes: 4_977_171_584,
                                                sha256: "85a896a0"))
        XCTAssertEqual(items[1], MacImport.Item(path: "Models/silero_vad.onnx", bytes: 2_327_524, sha256: "1a153a22"))
        for (item, file) in zip(items.dropFirst(2), voice.files) {
            XCTAssertEqual(item, MacImport.Item(path: "Voice/" + file.path, bytes: file.bytes,
                                                sha256: file.sha256 ?? ""))
        }
    }

    func testAWrongSizeAStrangerPathOrAWrongHashRefusesTheWholeFolder() throws {  // N5
        let wrongSize = try manifest { $0[0]["bytes"] = 4_977_171_583 }
        XCTAssertEqual(try refusal(wrongSize),
                       "файл не тот: gemma-4-E4B-it-Q4_K_M.gguf — 4977171583 байт вместо 4977171584")
        for stranger in ["Memory/memory.sqlite", "../Caches/turns.jsonl", "Ally/child-mode.json",
                         "Models/../Memory/memory.sqlite", "Models/turns.jsonl"] {
            let list = try manifest { $0.append(["path": stranger, "bytes": 1, "sha256": "00"]) }
            XCTAssertEqual(try refusal(list), "чужой файл в списке: \(stranger)")
        }
        let voice = try VoiceSettings.decode(registry("voice.json")), first = try XCTUnwrap(voice.files.first)
        let wrongHash = try manifest { $0[2]["sha256"] = String(repeating: "0", count: 64) }
        XCTAssertEqual(try refusal(wrongHash), "файл не тот: \(first.path) — sha256 не сходится")
        XCTAssertEqual(try refusal(Data("не json".utf8)), "список файлов не читается")
    }

    func testTheButtonIsTheMacsOnlyAndOnlyWhileSheSleeps() {  // N7
        XCTAssertFalse(MacImport.offered(onMac: false, asleep: true))
        XCTAssertFalse(MacImport.offered(onMac: false, asleep: false))
        XCTAssertTrue(MacImport.offered(onMac: true, asleep: true))
        XCTAssertFalse(MacImport.offered(onMac: true, asleep: false))
    }

    func testTheCopyPutsAFileInPlaceOnlyAfterItsCopyMatched() throws {  // N6
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("ally-mac"), support = root.appendingPathComponent("Support")
        try write("new weights", to: folder.appendingPathComponent("Models/w.gguf"))
        try write("voice", to: folder.appendingPathComponent("Voice/a.bin"))
        try write("accent", to: folder.appendingPathComponent("Voice/b.bin"))
        try write("old weights", to: support.appendingPathComponent("Models/w.gguf"))
        let memory = support.appendingPathComponent("Memory/memory.sqlite")
        try write("her memory", to: memory)
        let before = try FileManager.default.attributesOfItem(atPath: memory.path)[.modificationDate] as? Date
        let content: (URL) throws -> String = { String(bytes: try Data(contentsOf: $0), encoding: .utf8) ?? "" }
        let items = [MacImport.Item(path: "Models/w.gguf", bytes: 11, sha256: "new weights"),
                     MacImport.Item(path: "Voice/a.bin", bytes: 5, sha256: "voicX"),
                     MacImport.Item(path: "Voice/b.bin", bytes: 6, sha256: "accent")]
        XCTAssertThrowsError(try MacImport.copy(items, from: folder, into: support, sha256: content)) {
            XCTAssertEqual(($0 as? MacImport.Refusal)?.line, "файл не тот после копии: Voice/a.bin")
        }
        XCTAssertEqual(try content(support.appendingPathComponent("Models/w.gguf")), "new weights")
        XCTAssertFalse(FileManager.default.fileExists(atPath: support.appendingPathComponent("Voice/a.bin").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: support.appendingPathComponent("Voice/b.bin").path))
        let voice = support.appendingPathComponent("Voice").path
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: voice), [])
        try write("old voice", to: support.appendingPathComponent("Voice/a.bin"))
        XCTAssertThrowsError(try MacImport.copy([items[1]], from: folder, into: support, sha256: content))
        XCTAssertEqual(try content(support.appendingPathComponent("Voice/a.bin")), "old voice")
        let fixed = [items[0], MacImport.Item(path: "Voice/a.bin", bytes: 5, sha256: "voice"), items[2]]
        XCTAssertEqual(try MacImport.copy(fixed, from: folder, into: support, sha256: content),
                       "файлы с Mac на месте: 3, 0,00 ГБ")
        XCTAssertEqual(try ["Voice/a.bin", "Voice/b.bin"].map { try content(support.appendingPathComponent($0)) },
                       ["voice", "accent"])
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: voice).sorted(), ["a.bin", "b.bin"])
        XCTAssertEqual(try content(memory), "her memory")
        let after = try FileManager.default.attributesOfItem(atPath: memory.path)[.modificationDate] as? Date
        XCTAssertEqual(after, before)
    }

    #if canImport(CryptoKit)
    func testTheMacsHashIsTheFilesSha256() throws {  // N6 (Mac): the copy checks with CryptoKit
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("Models/abc.bin")
        try write("abc", to: file)
        // FIPS 180-2, «abc»:
        let abc = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"  // pragma: allowlist secret
        XCTAssertEqual(try FileDigest.sha256(of: file), abc)
        let support = root.appendingPathComponent("Support")
        XCTAssertNoThrow(try MacImport.copy([MacImport.Item(path: "Models/abc.bin", bytes: 3, sha256: abc)], from: root,
                                            into: support, sha256: FileDigest.sha256(of:)))
        XCTAssertEqual(try FileDigest.sha256(of: support.appendingPathComponent("Models/abc.bin")), abc)
    }
    #endif

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url)
    }
}
