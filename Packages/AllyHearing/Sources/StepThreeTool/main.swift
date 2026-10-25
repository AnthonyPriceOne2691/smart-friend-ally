// Step 3 of the recognizer choice (D7.4): dictation's live text against GigaAM on the black box export, judged by the
// parent's references — only sums go to stdout, never a reference or a hypothesis. Every path is an argument (L47):
//   swift run --disable-keychain --package-path Packages/AllyHearing asr-step3 \
//     local/blackbox/<дата> local/step3/refs.csv ~/models/asr/gigaam-extdata App/Resources/hearing.json
// Exit 0 — compared; 1 — nothing to compare (the count line says why); 2 — a refusal, on stderr.
import AllyCore
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("asr-step3: \(message)\n".utf8))
    exit(2)
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 4 else { fail("usage: asr-step3 <export> <refs.csv> <GigaAM folder> <hearing.json>") }
guard let refs = try? String(contentsOfFile: arguments[1], encoding: .utf8) else { fail("no refs at \(arguments[1])") }
guard let registry = FileManager.default.contents(atPath: arguments[3]), let hearing = try? Hearing.decode(registry)
else { fail("no hearing registry at \(arguments[3])") }
do {
    let run = try StepThreeRun.run(export: URL(fileURLWithPath: arguments[0]), refs: StepThreeRun.references(refs),
                                   hearing: hearing, models: URL(fileURLWithPath: arguments[2]))
    FileHandle.standardOutput.write(Data((run.lines.joined(separator: "\n") + "\n").utf8))
    exit(run.compared == 0 ? 1 : 0)
} catch {
    fail("\(error)")
}
