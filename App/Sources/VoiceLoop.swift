import AllyCore
import AllyLlama
import CryptoKit
import os
import SwiftUI

/// The voice loop behind the adult console: warm-up by stages, then a session (D2.2) — a tap wakes her, she listens by
/// herself while the session listens, each utterance goes through the router and each reply through the contract, one
/// wordless record a turn in `Caches/turns.jsonl`.
@MainActor
final class VoiceLoop: ObservableObject {
    struct Screen { var lines: [String] = [], heard = "", said = "", ready = false }
    @Published private(set) var screen = Screen()
    @Published private(set) var talk = TalkState()  // the session for a screen: phase, pose, why the last one ended
    private var conversation: Conversation?
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
        let hearing = try Hearing.decode(Data(contentsOf: bundle.appendingPathComponent("hearing.json")))
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
        let rate = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["voice_rate"] as? Double ?? 0.5
        let speech = await recognizer.prepare(), voice = SystemVoice(identifier: registry.voice, rate: Float(rate))
        let microphone = await AudioIO.microphoneAllowed()
        screen.lines += [speech.line, voice.note, "микрофон: " + (microphone ? "да" : "нет — разреши в Настройках")]
        let personaHash = SHA256.hash(data: Data(persona.utf8)).map { String(format: "%02x", $0) }.joined()
        versions = ["ios": UIDevice.current.systemVersion, "llama": settings.runtime.build, "persona": personaHash,
                    "voice": voice.voice?.identifier ?? "", "weights": "\(registry.model.file):\(registry.model.bytes)"]
        (self.registry, self.model, self.voice) = (registry, model, voice)
        screen.ready = speech.ready && microphone && voice.voice != nil
        if screen.ready { converse(model, hearing, voice) }
    }

    /// A tap on the sleeping friend: she greets and then talks without buttons until the session sleeps.
    func wake() {
        guard let conversation, talk.phase == .asleep else { return }
        (screen.heard, screen.said) = ("", "")
        Task { await conversation.wake() }
    }

    /// Her «я всё» — the console's button, a tap on Elly while she listens: the utterance ends now.
    func done() {
        guard let conversation else { return }
        Task { await conversation.done() }
    }

    /// The parent's stop: silence now, no phrase.
    func stop() {
        guard let conversation else { return }
        Task { await conversation.stop() }
    }

    /// The session (D2.2): the router before the model, the parent's limit key (`-session_limit_minutes 2` at launch),
    /// a wordless record a turn with the listening's stages into `Caches/turns.jsonl`; heard and said go to the screen.
    private func converse(_ model: LlamaModel, _ hearing: Hearing, _ voice: SystemVoice) {
        let heard: @Sendable (String) -> Void = { text in Task { @MainActor in self.screen.heard = text } }
        let ear = PhoneListener(recognizer: recognizer, audio: audio, hearing: hearing,
                                resetSound: { voice.resetFirstSound() }, firstSound: { voice.firstSound }, heard: heard)
        let echo = EchoVoice(voice) { sentence in Task { @MainActor in self.screen.said += sentence + " " } }
        let settings = SessionSettings(limitMinutes: UserDefaults.standard.object(forKey: SessionSettings.key)
            .map { "\($0)" })
        let versions = versions, sink = TraceFile(url: caches.appendingPathComponent("turns.jsonl"))
        let stamp: @Sendable () -> TraceStamp = {
            let thermal = ["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue]
            return TraceStamp(versions: versions, memory: Self.memory(model), thermal: thermal,
                              stages: ear.takeStages())
        }
        let parts = SessionParts(model: model, voice: echo, sink: sink, router: RouterRouting(), stamp: stamp)
        let conversation = Conversation(parts, settings: settings, listener: ear)
        self.conversation = conversation
        screen.lines.append(settings.note ?? "лимит: \(Int(settings.limit / 60)) мин")
        if !RouterRouting.healthy { screen.lines.append("маршрутизатор: самопроверка не прошла") }
        Task { for await state in conversation.updates { talk = state } }
    }

    /// What the iOS memory limit counts (L22): footprint now and its lifetime peak, headroom left; conversation tokens.
    nonisolated private static func memory(_ model: LlamaModel) -> [String: Int] {
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
