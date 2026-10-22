// Replays saved data through the discipline (frozen sets of the stand); a line that does not parse goes to stderr with
// its number.
//   (no argument): stdin JSONL {"id","mode","reply"} → stdout JSONL {"id","final","source","rules"} — the turn contract
//   router: {"id","text","game"} → {"id","kind","topic","key","rules"} — the decision without the text; time to stderr
//   turn: {"id","text","reply","mode","game"} → {"id","kind","topic","rules","routed","routed_source","plain",
//     "plain_source"} — the product's turn on a saved reply: the router's script or the reply through the contract with
//     the decision and her utterance; and the same reply through the contract alone, no router (the reference run)
//   swift run --package-path Packages/AllyDiscipline discipline-replay < replies.jsonl > final.jsonl
//   swift run -c release --package-path Packages/AllyDiscipline discipline-replay router < said.jsonl > routed.jsonl
import Discipline
import Foundation

struct Line: Decodable { let id, reply: String, mode: String? }
struct Final: Encodable { let id, final, source: String, rules: [String] }
struct Said: Decodable { let id, text: String, game: Bool? }
struct Decided: Encodable { let id, kind: String, topic, key: String?, rules: [String] }
struct Exchange: Decodable { let id, text, reply: String, mode: String?, game: Bool? }
struct Played: Encodable {
    let id, kind: String, topic: String?, rules: [String], routed, routedSource, plain, plainSource: String
}

/// What reaches the voice and where it came from: the model's sentences or a canned kind.
func spoken(_ turn: Turn) -> (text: String, source: String) {
    if case .canned(let kind) = turn.source { return (turn.sentences.joined(separator: " "), "canned:" + kind) }
    return (turn.sentences.joined(separator: " "), "model")
}

func play(_ exchange: Exchange) -> Played {
    let mode = TurnMode(rawValue: exchange.mode ?? "talk") ?? .talk
    let routed = Router.shared.route(exchange.text, state: RouterState(game: exchange.game ?? false))
    let plain = spoken(TurnContract(mode: mode, heard: exchange.text).finish(exchange.reply))
    var turn = spoken(TurnContract(mode: mode, heard: exchange.text, decision: routed.decision).finish(exchange.reply))
    if case .script(let key) = routed.decision { turn = (Router.script(for: key) ?? "", "script:" + key) }
    return Played(id: exchange.id, kind: routed.record.kind, topic: routed.record.topic, rules: routed.record.rules,
                  routed: turn.text, routedSource: turn.source, plain: plain.text, plainSource: plain.source)
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
encoder.keyEncodingStrategy = .convertToSnakeCase
let mode = CommandLine.arguments.dropFirst().first ?? "", clock = ContinuousClock()
var number = 0, times: [Duration] = []
if mode == "router" { _ = Router.shared.route("") }  // data, compilation and self-test before the first timed line
while let text = readLine() {
    number += 1
    guard !text.allSatisfy(\.isWhitespace) else { continue }
    do {
        let data = Data(text.utf8)
        switch mode {
        case "router":
            let said = try JSONDecoder().decode(Said.self, from: data), start = clock.now
            let record = Router.shared.route(said.text, state: RouterState(game: said.game ?? false)).record
            times.append(clock.now - start)
            let decided = Decided(id: said.id, kind: record.kind, topic: record.topic, key: record.key,
                                  rules: record.rules)
            FileHandle.standardOutput.write(try encoder.encode(decided) + Data("\n".utf8))
        case "turn":
            FileHandle.standardOutput.write(try encoder.encode(play(JSONDecoder().decode(Exchange.self, from: data)))
                                            + Data("\n".utf8))
        default:
            let line = try JSONDecoder().decode(Line.self, from: data)
            let turn = TurnContract(mode: TurnMode(rawValue: line.mode ?? "talk") ?? .talk).finish(line.reply)
            let said = spoken(turn)
            let final = Final(id: line.id, final: said.text, source: said.source, rules: turn.record.rules)
            FileHandle.standardOutput.write(try encoder.encode(final) + Data("\n".utf8))
        }
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
