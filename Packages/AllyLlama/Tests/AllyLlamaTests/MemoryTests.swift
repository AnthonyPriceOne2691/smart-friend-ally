import AllyLlama
import XCTest

/// D5 `kv-spoken`: the model's memory keeps only what sounded. With the weights on the Mac (the macOS slice of the
/// same xcframework) a turn rewritten by `commit` or removed by `retract` must leave the KV exactly as a clean prefill
/// of the same conversation does — the next reply is the same text; no weights — a visible skip (П34).
final class MemoryTests: XCTestCase {
    private let repo = URL(fileURLWithPath: #filePath).appendingPathComponent("../../../../..").standardized
    private let weights = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("models/gemma-4-E4B-it-Q4_K_M.gguf")

    func testSwaFullOffRefusesToLoad() async throws {  // X7
        var settings = try registry()
        settings.runtime.swaFull = false
        do {
            _ = try await LlamaModel.load(weights: weights, persona: "Ты Элли.", settings: settings, cache: cache("x7"))
            XCTFail("the model loaded with swa_full off")
        } catch {
            XCTAssertEqual(error as? LlamaError, .swaFullOff)
        }
        XCTAssertEqual(LlamaError.swaFullOff.line, "swa_full выключен — память модели не держит только сказанное")
        XCTAssertNil(LlamaError.context.line)
    }

    /// The reply sounded only up to its first sentence (a stop, the contract's cut): after `commit` the next reply is
    /// the one a conversation that only ever held that sentence gives.
    func testCommitKeepsOnlyWhatSounded() async throws {  // X1
        let model = try await loaded("x1")
        model.newConversation()
        let full = try await reply(model, "Расскажи про жирафа.")
        let spoken = String(full.prefix { !".!?…".contains($0) }) + "."
        model.commit(spoken: spoken)
        let afterCommit = try await reply(model, "А слона ты видела?")
        model.newConversation()
        model.remember(heard: "Расскажи про жирафа.", spoken: spoken)
        let clean = try await reply(model, "А слона ты видела?")
        FileHandle.standardError.write(Data("X1: сказано «\(spoken)» из \(full.count) знаков\n".utf8))
        XCTAssertGreaterThan(full.count, spoken.count)
        XCTAssertEqual(afterCommit, clean)
    }

    /// Tails of about 8, 64, 236 and 600 tokens leave the KV by `retract`: the next reply is the control's (the stand
    /// of 2026-10-19 — bitwise with the full SWA cache, not without it for 600).
    func testLongTailsLeaveExactly() async throws {  // X6
        let model = try await loaded("x6")
        model.newConversation()
        model.remember(heard: "Привет!", spoken: "Привет! Что у тебя нового?")
        let control = try await reply(model, "Мы ходили в парк.")
        for repeats in [1, 6, 22, 56] {  // ≈ 8, 64, 236, 600 tokens of her line
            model.newConversation()
            model.remember(heard: "Привет!", spoken: "Привет! Что у тебя нового?")
            let line = String(repeating: "Мы гуляли и видели уток. ", count: repeats)
            model.remember(heard: line, spoken: "Ой, как интересно!")
            model.retract()
            let after = try await reply(model, "Мы ходили в парк.")
            XCTAssertEqual(after, control, "tail of \(repeats) sentences")
        }
    }

    private func registry() throws -> LlamaSettings {
        try LlamaSettings.decode(Data(contentsOf: repo.appendingPathComponent("App/Resources/model.json")))
    }

    private func cache(_ name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ally-d5-\(name)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func loaded(_ name: String) async throws -> LlamaModel {
        guard FileManager.default.fileExists(atPath: weights.path) else {
            throw XCTSkip("\(name.uppercased()) пропущен: нет весов в ~/models — память модели не проверена")
        }
        let persona = try String(contentsOf: repo.appendingPathComponent("App/Resources/persona.v2.4.ru.md"),
                                 encoding: .utf8)
        return try await LlamaModel.load(weights: weights, persona: persona, settings: registry(), cache: cache(name))
    }

    private func reply(_ model: LlamaModel, _ utterance: String) async throws -> String {
        var text = ""
        for try await piece in model.reply(to: utterance) { text = piece }
        return text
    }
}
