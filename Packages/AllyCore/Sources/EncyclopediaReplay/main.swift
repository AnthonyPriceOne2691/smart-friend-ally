// The encyclopedia over a stand's questions: the base file is an argument (no default path, L47), the config — the
// bundled one or a stand file; stdin JSONL {"id","text"} → stdout JSONL {"card","hint","id","rules","top"}, top — the
// best three [card, score]. Texts are never printed, so the lead may run it on a blind set; time goes to stderr.
//   swift run -c release --package-path Packages/AllyCore encyclopedia-replay <cards.jsonl> [config.json] < q.jsonl
// `--said` (card-fallback, the P18 stand): stdin JSONL {"id","text","reply"} → stdout {"card","fallback","id","said"} —
// her words looked up, the saved reply through the real `TurnRunner` (`why` with a hint, else `talk`; the card's text
// when the reply misses its essence). It prints Elly's words: open sets only.
//   swift run -c release --package-path Packages/AllyCore encyclopedia-replay <cards.jsonl> --said < replies.jsonl
import AllyCore
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("encyclopedia-replay: \(message)\n".utf8))
    exit(2)
}

func write(_ row: [String: Any]) throws {
    let data = try JSONSerialization.data(withJSONObject: row, options: [.sortedKeys, .withoutEscapingSlashes])
    FileHandle.standardOutput.write(data + Data("\n".utf8))
}

/// A saved reply as the model's stream: the whole text at once, then the end.
final class SavedReply: LanguageModel, @unchecked Sendable {
    private let text: String
    init(_ text: String) { self.text = text }
    func reply(to utterance: String) -> AsyncThrowingStream<String, Error> {
        let (stream, output) = AsyncThrowingStream<String, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        output.yield(text)
        output.finish()
        return stream
    }
    func cancel() {}
    func commit(spoken: String) {}
    func retract() {}
    func remember(heard: String, spoken: String) {}
}

/// A voice that keeps the sentences it was given, in order.
final class Transcript: VoiceOutput, @unchecked Sendable {
    private(set) var sentences: [String] = []
    func speak(_ sentence: String) async throws { sentences.append(sentence) }
    func stop() {}
}

/// What Elly would say to her words over the saved reply, as a session's model turn does it.
func said(_ encyclopedia: Encyclopedia, text: String, reply: String) async throws -> [String: Any] {
    let lookup = encyclopedia.lookup(text), voice = Transcript()
    let card = lookup.hint.flatMap { hint in lookup.key.map { HintCard(text: hint, key: $0) } }
    let runner = TurnRunner(model: SavedReply(reply), voice: voice, mode: lookup.hint == nil ? .talk : .why)
    let outcome = try await runner.run(text, card: card)
    return ["card": lookup.record.card ?? NSNull(), "fallback": outcome.cardSaid,
            "said": voice.sentences.joined(separator: " ")]
}

let arguments = CommandLine.arguments.dropFirst().filter { $0 != "--said" }
let saying = CommandLine.arguments.contains("--said")
guard let cardsPath = arguments.first, let cards = FileManager.default.contents(atPath: cardsPath) else {
    fail("usage: encyclopedia-replay <cards.jsonl> [config.json] [--said]")
}
let clock = ContinuousClock(), loading = clock.now
let encyclopedia: Encyclopedia
if let configPath = arguments.dropFirst().first {
    guard let config = FileManager.default.contents(atPath: configPath) else { fail("no config at \(configPath)") }
    encyclopedia = Encyclopedia(cards: cards, config: config)
} else {
    encyclopedia = Encyclopedia(cards: cards)
}
let loaded = clock.now - loading
var times: [Duration] = [], number = 0
while let line = readLine() {
    number += 1
    guard !line.allSatisfy(\.isWhitespace) else { continue }
    guard let object = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
          let id = object["id"] as? String, let text = object["text"] as? String else {
        fail("line \(number) is not {id, text}")
    }
    if saying {
        guard let reply = object["reply"] as? String else { fail("line \(number) has no reply") }
        try write(try await said(encyclopedia, text: text, reply: reply).merging(["id": id]) { $1 })
        continue
    }
    var lookup = encyclopedia.lookup(text), best = Duration.seconds(1)
    for _ in 0..<3 {
        let start = clock.now
        lookup = encyclopedia.lookup(text)
        best = min(best, clock.now - start)
    }
    times.append(best)
    try write(["id": id, "hint": lookup.hint != nil, "card": lookup.record.card ?? NSNull(),
               "rules": lookup.record.rules, "top": lookup.top.map { [$0.card, $0.score] }])
}
func milliseconds(_ duration: Duration) -> Double {
    Double(duration.components.seconds) * 1000 + Double(duration.components.attoseconds) / 1e15
}
let sorted = times.sorted()
let p50 = sorted.isEmpty ? 0 : milliseconds(sorted[sorted.count / 2])
let p95 = sorted.isEmpty ? 0 : milliseconds(sorted[min(sorted.count - 1, sorted.count * 95 / 100)])
let summary = String(format: "healthy %@, hash %@, load %.1f ms, %d questions, lookup p50 %.3f ms, p95 %.3f ms",
                     encyclopedia.healthy ? "yes" : "no", encyclopedia.lookup("").record.dataHash,
                     milliseconds(loaded), times.count, p50, p95)
FileHandle.standardError.write(Data("encyclopedia-replay: \(summary)\n".utf8))
