@testable import AllyLlama
import XCTest

/// M36 `memory-recall`: the system turn with the memory's block is rebuilt, read back from its state file by a new load
/// that counts the block with the model's tokenizer, and fits the context with 40 turns; empty memory gives today's
/// prefix file; a rebuild that fails keeps the prefix the model had. With the weights on the Mac, else a visible skip.
final class PrefixTests: XCTestCase {
    private struct Stand {
        let settings: LlamaSettings, persona: String, cache: URL
    }

    private let repo = URL(fileURLWithPath: #filePath).appendingPathComponent("../../../../..").standardized
    private let weights = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("models/gemma-4-E4B-it-Q4_K_M.gguf")
    private let block = """
        Что ты помнишь о ней из прошлых разговоров. Это для тебя: не пересказывай и не перечисляй, вспоминай что-то \
        одно, когда к месту.
        Она: Соня, пять лет.
        Брат Тёма, восемь лет: строили замок из подушек.
        Кошка Мурка, рыжая: любит спать на батарее.
        """
    private let turn = "<|turn>user\nа у меня кошка мурка она рыжая и любит спать на батарее<turn|>\n<|turn>model\n"
        + "Рыжая Мурка на тёплой батарее — вот это уют! Наверное, она мурлычет во сне. А ты с ней играешь?<turn|>\n"

    func testBlockPrefixIsRebuiltReadFromItsFileAndFitsTheContext() async throws {  // M36
        let stand = try makeStand(), (settings, persona, cache) = (stand.settings, stand.persona, stand.cache)
        defer { try? FileManager.default.removeItem(at: cache) }
        let model = try await LlamaModel.load(weights: weights, persona: persona, settings: settings, cache: cache)
        let today = try prefixes(cache), bare = model.prefixInKV
        XCTAssertLessThanOrEqual(model.tokenCount(block), 300)
        _ = try await firstPrompt(model)  // a finished reply leaves its raised stop flag behind
        try await model.rebuildPrefix(persona + "\n\n" + block, cache: cache)
        XCTAssertEqual(try prefixes(cache).count, 1)
        XCTAssertNotEqual(try prefixes(cache), today)
        let withBlock = model.prefixInKV, prompt = try await firstPrompt(model)
        XCTAssertGreaterThan(withBlock, bare)

        let again = try await LlamaModel.load(weights: weights, settings: settings, cache: cache) { [block] count in
            count(block) <= 300 ? persona + "\n\n" + block : persona
        }
        let read = try XCTUnwrap(again.warmup["prefix_file"], "the prefix was built again, not read from its file")
        FileHandle.standardError.write(Data("M36: префикс с блоком из файла за \(read) с\n".utf8))
        XCTAssertEqual(again.prefixInKV, withBlock)
        let readPrompt = try await firstPrompt(again)
        XCTAssertEqual(readPrompt, prompt)
        try await again.rebuildPrefix(persona, cache: cache)
        XCTAssertEqual(try prefixes(cache), today)
        XCTAssertEqual(again.prefixInKV, bare)

        let context = model.tokenCount(persona) + 300 + 40 * model.tokenCount(turn)
        XCTAssertLessThanOrEqual(context, Int(Double(settings.runtime.nCtx) * 0.85))
    }

    func testFailedRebuildKeepsThePrefixTheModelHad() async throws {  // M36
        let stand = try makeStand(), (settings, persona, cache) = (stand.settings, stand.persona, stand.cache)
        defer { try? FileManager.default.removeItem(at: cache) }
        let model = try await LlamaModel.load(weights: weights, persona: persona + "\n\n" + block, settings: settings,
                                              cache: cache)
        let file = try prefixes(cache), prefix = model.prefixInKV, before = try await firstPrompt(model)
        let overflow = persona + "\n\n" + String(repeating: "Кошка Мурка любит спать на тёплой батарее. ", count: 900)
        do {
            try await model.rebuildPrefix(overflow, cache: cache)
            XCTFail("a system turn longer than the context must not build")
        } catch {
            FileHandle.standardError.write(Data("M36: пересборка не уместилась — \(error), префикс прежний\n".utf8))
        }
        XCTAssertEqual(try prefixes(cache), file)
        XCTAssertEqual(model.prefixInKV, prefix)
        let after = try await firstPrompt(model)
        XCTAssertEqual(after, before)
    }

    func testRebuildAfterALongConversationFindsRoom() async throws {  // M36
        let stand = try makeStand(), (settings, persona, cache) = (stand.settings, stand.persona, stand.cache)
        defer { try? FileManager.default.removeItem(at: cache) }
        let model = try await LlamaModel.load(weights: weights, persona: persona, settings: settings, cache: cache)
        let bare = model.prefixInKV, target = Int(settings.runtime.nCtx) - 600 - bare
        var heard = ""
        while model.tokenCount(heard) < target { heard += "Мурка спит на тёплой батарее, а Тёма строит замок. " }
        model.remember(heard: heard, spoken: "")  // the session filled the context almost to the end
        try await model.rebuildPrefix(persona + "\n\n" + block, cache: cache)
        XCTAssertGreaterThan(model.prefixInKV, bare)
        _ = try await firstPrompt(model)
    }

    /// The registry and persona of the app bundle, a fresh cache folder; no weights — a visible skip.
    private func makeStand() throws -> Stand {
        guard FileManager.default.fileExists(atPath: weights.path) else {
            throw XCTSkip("M36 пропущен: нет весов в ~/models — префикс с блоком не проверен")
        }
        let registry = repo.appendingPathComponent("App/Resources/model.json")
        let settings = try LlamaSettings.decode(Data(contentsOf: registry))
        let persona = try String(contentsOf: repo.appendingPathComponent("App/Resources/persona.v2.4.ru.md"),
                                 encoding: .utf8)
        let cache = FileManager.default.temporaryDirectory.appendingPathComponent("ally-m36-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        return Stand(settings: settings, persona: persona, cache: cache)
    }

    private func prefixes(_ cache: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: cache.path).filter { $0.hasPrefix("persona-") }
    }

    /// Tokens before the first reply of a new conversation: the prefix and her line — the prefix the model talks from.
    private func firstPrompt(_ model: LlamaModel) async throws -> Int {
        model.newConversation()
        for try await _ in model.reply(to: "Привет!") {}
        return model.promptTokens
    }
}
