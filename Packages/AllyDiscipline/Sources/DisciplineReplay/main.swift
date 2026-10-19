// Replays saved replies through the turn contract (frozen sets of the stand): stdin JSONL {"id","mode","reply"} →
// stdout JSONL {"id","final","source","rules"}. With `router`: stdin JSONL {"id","text","game"} → stdout JSONL
// {"id","kind","topic","key","rules"} — the router's decision without the text — and the time per line to stderr.
// A line that does not parse goes to stderr with its number.
//   swift run --package-path Packages/AllyDiscipline discipline-replay < replies.jsonl > final.jsonl
//   swift run -c release --package-path Packages/AllyDiscipline discipline-replay router < said.jsonl > routed.jsonl
import Discipline
import Foundation

struct Line: Decodable { let id, reply: String, mode: String? }
struct Final: Encodable { let id, final, source: String, rules: [String] }
struct Said: Decodable { let id, text: String, game: Bool? }
struct Decided: Encodable { let id, kind: String, topic, key: String?, rules: [String] }

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
let routerMode = CommandLine.arguments.dropFirst().first == "router", clock = ContinuousClock()
var number = 0, times: [Duration] = []
if routerMode { _ = Router.shared.route("") }  // data, compilation and self-test before the first timed line
while let text = readLine() {
    number += 1
    guard !text.allSatisfy(\.isWhitespace) else { continue }
    do {
        if routerMode {
            let said = try JSONDecoder().decode(Said.self, from: Data(text.utf8)), start = clock.now
            let record = Router.shared.route(said.text, state: RouterState(game: said.game ?? false)).record
            times.append(clock.now - start)
            let decided = Decided(id: said.id, kind: record.kind, topic: record.topic, key: record.key,
                                  rules: record.rules)
            FileHandle.standardOutput.write(try encoder.encode(decided) + Data("\n".utf8))
            continue
        }
        let line = try JSONDecoder().decode(Line.self, from: Data(text.utf8))
        let turn = TurnContract(mode: TurnMode(rawValue: line.mode ?? "talk") ?? .talk).finish(line.reply)
        var source = "model"
        if case .canned(let kind) = turn.source { source = "canned:" + kind }
        let final = Final(id: line.id, final: turn.sentences.joined(separator: " "), source: source,
                          rules: turn.record.rules)
        FileHandle.standardOutput.write(try encoder.encode(final) + Data("\n".utf8))
    } catch {
        FileHandle.standardError.write(Data("discipline-replay: line \(number): \(error)\n".utf8))
    }
}
if let worst = times.max() {
    let sorted = times.sorted(), at = { (share: Double) in sorted[Int(share * Double(sorted.count - 1))] }
    let ms = [at(0.5), at(0.95), worst].map { String(format: "%.3f", $0 / .milliseconds(1)) }
    let summary = "router: \(times.count) lines, ms p50 \(ms[0]) p95 \(ms[1]) max \(ms[2])\n"
    FileHandle.standardError.write(Data(summary.utf8))
}
