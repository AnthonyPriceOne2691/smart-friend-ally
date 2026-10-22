import AllyLlama
import XCTest

/// A23: the product model against the accepted v2.4 bench, on the Mac (the macOS slice of the same xcframework): the
/// persona and registry of the app bundle, n_ctx of the bench; no weights or bench replies — a visible skip (П34).
final class StandParityTests: XCTestCase {
    private let repo = URL(fileURLWithPath: #filePath).appendingPathComponent("../../../../..").standardized

    func testStandParity() async throws { // A23
        let weights = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("models/gemma-4-E4B-it-Q4_K_M.gguf")
        let bench = repo.appendingPathComponent("local/spike/persona-v2/results/bench-v24-gemma4-e4b-s42.jsonl")
        guard FileManager.default.fileExists(atPath: weights.path),
              let lines = try? String(contentsOf: bench, encoding: .utf8) else {
            throw XCTSkip("A23 пропущен: нет весов в ~/models или ответов стенда в local/ — паритет не проверен")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let cases = lines.split(separator: "\n").compactMap { try? decoder.decode(BenchCase.self, from: Data($0.utf8)) }
            .filter { $0.history.isEmpty }
        let bench4096 = try await run(cases, nCtx: 4096, weights: weights)
        let bench8192 = try await run(cases, nCtx: 8192, weights: weights)
        FileHandle.standardError.write(Data(("A23: токены \(bench4096.tokens), ответы \(bench4096.replies) из "
            + "\(cases.count) при n_ctx 4096; ответы \(bench8192.replies) при 8192\n").utf8))
        XCTAssertEqual(cases.count, 37)
        XCTAssertEqual(bench4096.tokens, cases.count)
        XCTAssertGreaterThanOrEqual(bench4096.replies, cases.count - 2)
    }

    private func run(_ cases: [BenchCase], nCtx: UInt32, weights: URL) async throws -> (tokens: Int, replies: Int) {
        let resources = repo.appendingPathComponent("App/Resources")
        var settings = try LlamaSettings.decode(Data(contentsOf: resources.appendingPathComponent("model.json")))
        settings.runtime.nCtx = nCtx
        let persona = try String(contentsOf: resources.appendingPathComponent("persona.v2.4.ru.md"), encoding: .utf8)
        let cache = FileManager.default.temporaryDirectory.appendingPathComponent("ally-a23-\(nCtx)")
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        let model = try await LlamaModel.load(weights: weights, persona: persona, settings: settings, cache: cache)
        FileHandle.standardError.write(Data("A23 n_ctx \(nCtx), прогрев \(model.warmup)\n".utf8))
        var tokens = 0, replies = 0
        for item in cases {
            model.newConversation()
            var reply = ""
            for try await text in model.reply(to: item.userText) { reply = text }
            tokens += model.promptTokens == item.promptTokens ? 1 : 0
            replies += reply.trimmingCharacters(in: .whitespacesAndNewlines) == item.response ? 1 : 0
        }
        return (tokens, replies)
    }
}

/// One bench row: the user's phrase, the accepted reply, its prompt tokens, the history (such cases are skipped).
private struct BenchCase: Decodable {
    let userText: String, response: String, promptTokens: Int, history: [[String: String]]
}
