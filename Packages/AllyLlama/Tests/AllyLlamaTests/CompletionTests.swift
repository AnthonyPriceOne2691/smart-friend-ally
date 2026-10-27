import AllyLlama
import XCTest

/// M35 `memory-app`: the memory's parse runs on the app's model beside the conversation — sequence 2, the JSON
/// grammar — and the task's cancellation stops it; with the weights on the Mac, else a visible skip (П34).
final class CompletionTests: XCTestCase {
    private let repo = URL(fileURLWithPath: #filePath).appendingPathComponent("../../../../..").standardized
    private let weights = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("models/gemma-4-E4B-it-Q4_K_M.gguf")

    func testParseAnswersJSONBesideTheConversationAndStopsOnCancel() async throws {  // M35
        guard FileManager.default.fileExists(atPath: weights.path) else {
            throw XCTSkip("M35 пропущен: нет весов в ~/models — разбор моделью не проверен")
        }
        let registry = repo.appendingPathComponent("App/Resources/model.json")
        let settings = try LlamaSettings.decode(Data(contentsOf: registry))
        let cache = FileManager.default.temporaryDirectory.appendingPathComponent("ally-m35")
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        let model = try await LlamaModel.load(weights: weights, persona: "Ты Элли.", settings: settings, cache: cache)
        let ask = [(role: "system", text: "Ответь одним объектом JSON с полем «кличка»."),
                   (role: "user", text: "Девочка сказала: у меня кошка мурка.")]
        let text = try await model.complete(ask, temperature: 0.2, seed: 42, grammar: LlamaModel.jsonGrammar)
        XCTAssertNotNil(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any], text)
        XCTAssertGreaterThan(model.completionStats.prompt, 0)
        var reply = ""
        for try await piece in model.reply(to: "Привет!") { reply = piece }
        XCTAssertFalse(reply.isEmpty)

        let long = [(role: "user", text: "Расскажи очень длинную сказку про кошку, на тысячу слов.")]
        let task = Task { try await model.complete(long, temperature: 0.2, seed: 7, grammar: nil) }
        try await Task.sleep(nanoseconds: 1_500_000_000)
        let cancelled = ProcessInfo.processInfo.systemUptime
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("the parse was not stopped")
        } catch {
            XCTAssertEqual(error as? LlamaError, .stopped)
        }
        XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - cancelled, 2)
    }
}
