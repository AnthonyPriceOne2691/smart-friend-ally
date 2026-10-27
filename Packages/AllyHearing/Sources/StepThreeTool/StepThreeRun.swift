import AllyCore
import AllyHearing
import AllySherpa
import CryptoKit
import Foundation

/// The step-3 run over a black box export (D7.4): each of her utterances with a parent's reference, dictation's live
/// `heard` and GigaAM's text of the same WAV — the recognizer of the phone, the sound of the box bit for bit. Only the
/// lines of sums come out; nothing is written.
enum StepThreeRun {
    /// Why the run did not compare: GigaAM did not open, a sound is not the box's 16 kHz.
    struct Refusal: Error, CustomStringConvertible {
        let description: String
    }

    /// A record of the export as the run reads it: the live text, her sound, who listened.
    private struct Box: Decodable {
        struct Audio: Decodable { let file: String? }
        let heard: String?, childAudio: Audio?, versions: [String: String]?
    }

    /// The parent's `refs.csv`: `session,turn,ref` per line, keyed `session/turn`; a comma inside the reference is its
    /// own; the header and malformed lines do not count.
    static func references(_ text: String) -> [String: String] {
        var refs: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 3, let turn = Int(parts[1]) else { continue }
            refs["\(parts[0])/\(turn)"] = parts[2].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return refs
    }

    /// The lines of sums and how many utterances were compared; GigaAM's files are checked by the registry's sizes.
    static func run(export: URL, refs: [String: String], hearing: Hearing,
                    models: URL) throws -> (lines: [String], compared: Int) {
        let files = hearing.asr?.gigaam ?? []
        let asked = Hearing(turn: hearing.turn, listenTimeout: hearing.listenTimeout,
                            asr: Recognition(engine: "gigaam", gigaam: files))
        let choice = GigaAMRecognizer.choose(asked, models: models)
        guard let decode = choice.decode else { throw Refusal(description: choice.line ?? choice.label) }
        var pairs: [StepThree.Pair] = [], noRef = 0, noAudio = 0, live = 0, ios = Set<String>()
        for record in try records(export) {
            guard let box = try? read(record) else { continue }
            if let asr = box.versions?["asr"], asr != "dictation" {
                live += 1
                continue
            }
            let session = record.deletingLastPathComponent().lastPathComponent
            let turn = Int(record.deletingPathExtension().lastPathComponent) ?? -1
            guard let ref = refs["\(session)/\(turn)"] else {
                noRef += 1
                continue
            }
            guard let file = box.childAudio?.file else {
                noAudio += 1
                continue
            }
            let sound = try samples(record.deletingLastPathComponent().appendingPathComponent(file))
            pairs.append(StepThree.Pair(ref: ref, dictation: box.heard ?? "", gigaam: decode(sound)))
            if let version = box.versions?["ios"] { ios.insert(version) }
        }
        let models = ["GigaAM \(choice.label) sha256 " + files.map { hash(models.appendingPathComponent($0.file)) }
            .joined(separator: " "), "dictation iOS " + ios.sorted().joined(separator: ", ")]
        let skipped = StepThree.Skipped(noRef: noRef, noAudio: noAudio, live: live)
        let lines = StepThree.lines(StepThree.summary(pairs), skipped: skipped, models: models)
        return (pairs.isEmpty ? Array(lines.prefix(1)) : lines, pairs.count)
    }

    /// Every `NNNN.allybox` under the export, in path order.
    private static func records(_ export: URL) throws -> [URL] {
        guard let walk = FileManager.default.enumerator(at: export, includingPropertiesForKeys: nil) else {
            throw Refusal(description: "no export at \(export.path)")
        }
        return walk.compactMap { $0 as? URL }.filter { $0.pathExtension == "allybox" }.sorted { $0.path < $1.path }
    }

    /// The record's JSON after its header line `ALLY-BLACKBOX/1`.
    private static func read(_ record: URL) throws -> Box {
        let lines = try String(contentsOf: record, encoding: .utf8).split(separator: "\n", maxSplits: 1)
        guard lines.count == 2, lines[0] == "ALLY-BLACKBOX/1" else { throw Refusal(description: "not a record") }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Box.self, from: Data(lines[1].utf8))
    }

    /// Her WAV as GigaAM hears it on the phone: Int16 / 32768 at 16 kHz.
    private static func samples(_ url: URL) throws -> [Float] {
        guard let wave = SherpaOnnxReadWave(url.path) else {
            throw Refusal(description: "no WAV \(url.lastPathComponent)")
        }
        defer { SherpaOnnxFreeWave(wave) }
        guard wave.pointee.sample_rate == 16_000 else {
            throw Refusal(description: "\(url.lastPathComponent): \(wave.pointee.sample_rate) Hz, not 16000")
        }
        return Array(UnsafeBufferPointer(start: wave.pointee.samples, count: Int(wave.pointee.num_samples)))
    }

    /// The first 8 hex digits of a file's SHA-256 — the runbook prints the same.
    private static func hash(_ url: URL) -> String {
        guard let data = try? Data(contentsOf: url, options: .alwaysMapped) else { return "?" }
        return SHA256.hash(data: data).prefix(4).map { String(format: "%02x", $0) }.joined()
    }
}
