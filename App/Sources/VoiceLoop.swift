import AllyCore
import AllyLlama
import CryptoKit
import os
import SwiftUI

/// The voice loop behind the adult console (D1): warm-up by stages, then per tap — speech, recognition, a turn through
/// the contract (mode `talk`, TurnRunner's default), her voice, one wordless journal line in `Caches/turns.jsonl`.
@MainActor
final class VoiceLoop: ObservableObject {
    struct Screen { var lines: [String] = [], heard = "", said = "", ready = false, busy = false }
    @Published private(set) var screen = Screen()
    private let recognizer = DictationRecognizer(), audio = AudioIO(), files = FileManager.default
    private let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    private var model: LlamaModel?, registry: ModelRegistry?, voice: SystemVoice?, versions: [String: String] = [:]

    func start() async {
        guard registry == nil else { return }
        do { try await warmUp() } catch { screen.lines.append("ошибка: \(error)") }
    }

    private func warmUp() async throws {
        let bundle = Bundle.main.bundleURL, data = try Data(contentsOf: bundle.appendingPathComponent("model.json"))
        let registry = try ModelRegistry.decode(data), settings = try LlamaSettings.decode(data)
        let profile = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision")
        let days = ProfileExpiry.daysLeft(profile.flatMap { try? Data(contentsOf: $0) }, now: Date())
        let available = os_proc_available_memory() >> 20
        screen.lines = [ProfileExpiry.line(daysLeft: days) + ((days ?? 2) <= 1 ? " — переустанови с Mac" : ""),
                        "доступно памяти: \(available) МБ"]
        let models = files.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Models")
        try files.createDirectory(at: models, withIntermediateDirectories: true)
        try (models as NSURL).setResourceValue(true, forKey: .isExcludedFromBackupKey)  // 4.6 GB, not for backups
        if let missing = ModelCheck.check(registry: data, in: models).message { return screen.lines.append(missing) }
        let persona = try String(contentsOf: bundle.appendingPathComponent(registry.persona), encoding: .utf8)
        let model = try await LlamaModel.load(weights: models.appendingPathComponent(registry.model.file),
                                              persona: persona, settings: settings, cache: caches)
        let start = uptime
        for try await _ in model.reply(to: "Привет!") {}
        model.newConversation()
        screen.lines.append("прогрев: " + line(model.warmup.merging(["reply": uptime - start]) { $1 }))
        let rate = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["voice_rate"] as? Float
        let speech = await recognizer.prepare(), voice = SystemVoice(identifier: registry.voice, rate: rate ?? 0.5)
        let microphone = await AudioIO.microphoneAllowed()
        screen.lines += [speech.line, voice.note, "микрофон: " + (microphone ? "да" : "нет — разреши в Настройках")]
        let personaHash = SHA256.hash(data: Data(persona.utf8)).map { String(format: "%02x", $0) }.joined()
        versions = ["ios": UIDevice.current.systemVersion, "llama": settings.runtime.build, "persona": personaHash,
                    "voice": voice.voice?.identifier ?? "", "weights": "\(registry.model.file):\(registry.model.bytes)"]
        (self.registry, self.model, self.voice) = (registry, model, voice)
        screen.ready = speech.ready && microphone && voice.voice != nil
    }

    func talk() {
        guard screen.ready, !screen.busy, let model, let registry, let voice else { return }
        screen.busy = true
        Task {
            do { try await turn(model, registry, voice) } catch { screen.lines.append("ход: \(error)") }
            screen.busy = false
        }
    }

    private func turn(_ model: LlamaModel, _ registry: ModelRegistry, _ voice: SystemVoice) async throws {
        (screen.heard, screen.said) = ("", "")
        let phrase = try await recognizer.phrase { text in Task { @MainActor in self.screen.heard = text } }
        let detector = TurnDetector(kind: .closed, timing: registry.turn)
        guard let end = try await audio.listen(detector, timeout: registry.listenTimeout, feed: phrase.feed) else {
            await phrase.cancel()
            return screen.heard = "(тишина)"
        }
        let text = try await phrase.finish(), recognized = uptime
        screen.heard = text.isEmpty ? "(не расслышала)" : text
        guard !text.isEmpty else { return }
        voice.resetFirstSound()
        let runner = TurnRunner(model: model, voice: voice, firstSentenceTimeout: registry.firstSentenceTimeout)
        let outcome = try await runner.run(text)
        screen.said = outcome.turn.sentences.joined(separator: " ")
        let stages = ["tail": end.ended - end.voiced, "recognize": recognized - end.ended,
                      "speech_end_to_sound": voice.firstSound.map { $0 - end.voiced }].compactMapValues { $0 }
        screen.lines.append("ход: " + line(stages))
        let thermal = ["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue]
        let log = TurnLog(outcome: outcome, stages: stages, versions: versions, memory: memory(model), thermal: thermal)
        if let entry = log.jsonLine() { append(entry) }
    }

    /// One line into `Caches/turns.jsonl`: out of the backup, pulled to the Mac with `devicectl device copy from`.
    private func append(_ entry: String) {
        let url = caches.appendingPathComponent("turns.jsonl")
        if !files.fileExists(atPath: url.path) { files.createFile(atPath: url.path, contents: nil) }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        handle.seekToEndOfFile()
        handle.write(Data((entry + "\n").utf8))
        try? handle.close()
    }

    /// What the iOS memory limit counts (L22): footprint now and its lifetime peak, headroom left; conversation tokens.
    private func memory(_ model: LlamaModel) -> [String: Int] {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        let base = ["available_mb": os_proc_available_memory() >> 20, "context_tokens": model.promptTokens]
        guard status == KERN_SUCCESS else { return base }
        return base.merging(["footprint_mb": Int(info.phys_footprint >> 20),
                             "footprint_peak_mb": Int(info.ledger_phys_footprint_peak >> 20)]) { $1 }
    }

    private var uptime: Double { ProcessInfo.processInfo.systemUptime }

    private func line(_ stages: [String: Double]) -> String {
        stages.sorted { $0.key < $1.key }.map { "\($0.key) " + String(format: "%.2f с", $0.value) }
            .joined(separator: " · ")
    }
}
