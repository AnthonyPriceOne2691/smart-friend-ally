import AllyLlama
import Foundation
import Memory

/// The memory's parse on the app's model (`memory-app`, M35): sequence 2 beside the conversation, the JSON grammar
/// the parse asks for in `extract.json`.
struct MemoryLlama: MemoryModel {
    let model: LlamaModel

    func answer(_ messages: [ExtractMessage], _ params: ExtractParams) async throws -> String {
        try await model.complete(messages.map { (role: $0.role.rawValue, text: $0.text) },
                                 temperature: Float(params.temperature), seed: UInt32(params.seed),
                                 grammar: params.grammar == "json" ? LlamaModel.jsonGrammar : nil)
    }

    /// One wordless journal line of a parse: the talks parsed and not, the facts, the last answer's tokens, seconds.
    static func line(_ done: [Extraction], seconds: Double, stats: CompletionStats) -> Data? {
        let record: [String: Any] = [
            "parsed": done.filter { $0.status == .parsed }.count, "failed": done.filter { $0.status != .parsed }.count,
            "added": done.compactMap(\.written?.added).reduce(0, +), "prompt_tokens": stats.prompt,
            "output_tokens": stats.output, "seconds": (seconds * 10).rounded() / 10
        ]
        return try? JSONSerialization.data(withJSONObject: record, options: .sortedKeys) + Data("\n".utf8)
    }
}
