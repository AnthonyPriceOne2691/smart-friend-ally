// Replays saved replies through the turn contract (frozen sets of the stand): stdin JSONL {"id","mode","reply"} →
// stdout JSONL {"id","final","source","rules"}. A line that does not parse goes to stderr with its number.
//   swift run --package-path Packages/AllyDiscipline discipline-replay < replies.jsonl > final.jsonl
import Discipline
import Foundation

struct Line: Decodable { let id, reply: String, mode: String? }
struct Final: Encodable { let id, final, source: String, rules: [String] }

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
var number = 0
while let text = readLine() {
    number += 1
    guard !text.allSatisfy(\.isWhitespace) else { continue }
    do {
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
