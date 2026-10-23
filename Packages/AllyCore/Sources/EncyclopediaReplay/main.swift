// The encyclopedia over a stand's questions: the base file is an argument (no default path, L47), the config — the
// bundled one or a stand file; stdin JSONL {"id","text"} → stdout JSONL {"card","hint","id","rules","top"}, top — the
// best three [card, score]. Texts are never printed, so the lead may run it on a blind set; time goes to stderr.
//   swift run -c release --package-path Packages/AllyCore encyclopedia-replay <cards.jsonl> [config.json] < q.jsonl
import AllyCore
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("encyclopedia-replay: \(message)\n".utf8))
    exit(2)
}

let arguments = CommandLine.arguments.dropFirst()
guard let cardsPath = arguments.first, let cards = FileManager.default.contents(atPath: cardsPath) else {
    fail("usage: encyclopedia-replay <cards.jsonl> [config.json]")
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
    var lookup = encyclopedia.lookup(text), best = Duration.seconds(1)
    for _ in 0..<3 {
        let start = clock.now
        lookup = encyclopedia.lookup(text)
        best = min(best, clock.now - start)
    }
    times.append(best)
    let row: [String: Any] = ["id": id, "hint": lookup.hint != nil, "card": lookup.record.card ?? NSNull(),
                              "rules": lookup.record.rules, "top": lookup.top.map { [$0.card, $0.score] }]
    let data = try JSONSerialization.data(withJSONObject: row, options: [.sortedKeys, .withoutEscapingSlashes])
    FileHandle.standardOutput.write(data + Data("\n".utf8))
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
