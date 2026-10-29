import AllyCore
import AllyHearing
import AllyLlama
import AVFoundation
import CryptoKit
import Memory
import os
import ShellCore
import SwiftUI

/// The voice loop behind the adult console: warm-up by stages, then a session (D2.2) — a tap wakes her, she listens by
/// herself while the session listens, each utterance goes through the router and each reply through the contract, one
/// wordless record a turn in `Caches/turns.jsonl`.
@MainActor
final class VoiceLoop: ObservableObject {
    struct Screen { var lines: [String] = [], heard = "", said = "", ready = false }
    @Published private(set) var screen = Screen()
    @Published private(set) var talk = TalkState() {  // the session for a screen: phase, pose, why the last one ended
        didSet { music?.update { $0.phase = talk.phase } }
    }
    private var conversation: Conversation?
    // The child mode (R, R2): who may talk on the child screen, whether it is shown, an exception in the container, the
    // acceptance's line; its own session (audience `supervised`, or `child` once the acceptance holds) and the last
    // wake, which the next one waits for — one ear for both sessions.
    @Published private(set) var access = ChildAccess.parentOnly([])
    @Published private(set) var child = false { didSet { music?.update { $0.child = child } } }
    @Published private(set) var exception = false
    @Published private(set) var acceptance = ""
    // The break after a goodbye by the limit (Ш3): the parent's key, none by default («Без перерыва», 2026-10-23).
    @Published private(set) var nap = Nap(raw: UserDefaults.standard.object(forKey: Nap.key).map { "\($0)" })
    private var childMode: ChildMode?, childTalk: Conversation?, running: Task<Void, Never>?
    private let recognizer = DictationRecognizer(), audio = AudioIO(), files = FileManager.default
    private let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    private var model: LlamaModel?, registry: ModelRegistry?, voice: (any HerVoice)?, versions: [String: String] = [:]
    // The memory (memory-app): the base out of the backup, the parse after a session sleeps — cancelled by a wake.
    private var memory: MemoryStore?, parsing: Task<Void, Never>?, slot = 0
    // memory-recall: the persona, the system turn with the memory's block (M36) and the console's memory lines (M39).
    private var persona = "", system = ""
    @Published private(set) var memoryLines: [String] = []
    private var encyclopedia: Encyclopedia?  // Э2: loaded at warm-up, both sessions get it
    // background-music: «Шкатулка Элли» on the child screen; a wake waits for it to go quiet, a second tap — no wake
    private var music: BackgroundMusic?, waking = false

    func start() async {
        guard registry == nil else { return }
        do { try await warmUp() } catch { screen.lines.append((error as? LlamaError)?.line ?? "ошибка: \(error)") }
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
        openMemory()
        let store = memory  // the block by the model's own tokenizer: a new load reads the prefix the last wrote (M36)
        let model = try await LlamaModel.load(weights: models.appendingPathComponent(registry.model.file),
                                              settings: settings, cache: caches) {
            MemoryBlock.system(persona: persona, block: Self.block(store, $0))
        }
        system = MemoryBlock.system(persona: persona, block: Self.block(store, model.tokenCount))
        self.persona = persona
        let start = uptime
        for try await _ in model.reply(to: "Привет!") {}
        model.newConversation()
        screen.lines.append("прогрев: " + line(model.warmup.merging(["reply": uptime - start]) { $1 }))
        let rate = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["voice_rate"] as? Double ?? 0.5
        let speech = await recognizer.prepare(), voice = makeVoice(registry, rate: rate)
        let microphone = await AudioIO.microphoneAllowed()
        screen.lines += [speech.line, voice.note, "микрофон: " + (microphone ? "да" : "нет — разреши в Настройках")]
        let (silero, listening) = SileroActivity.choose(hearing, models: models)  // D7.2: no Silero — energy
        let asr = GigaAMRecognizer.choose(hearing, models: models)  // D7.3: dictation unless GigaAM is asked and there
        screen.lines += [listening.line] + [asr.line].compactMap { $0 }
        let encyclopedia = Encyclopedia.bundled()  // Э2: the base and FTS5 on the phone — the self-test says if not
        screen.lines.append(encyclopedia.line(searchP95: encyclopedia.searchP95()))
        let music = makeMusic(bundle)  // its node joins the session's engine before voice processing (X9)
        let sound = duplex(voice, hearing, models: models, silero: silero)
        startMusic(music, sound: sound)
        let personaHash = SHA256.hash(data: Data(persona.utf8)).map { String(format: "%02x", $0) }.joined()
        versions = ["ios": UIDevice.current.systemVersion, "llama": settings.runtime.build, "persona": personaHash,
                    "voice": voice.label, "weights": "\(registry.model.file):\(registry.model.bytes)",
                    "vad": silero == nil ? "energy" : "silero:\(hearing.vad?.bytes ?? 0)", "asr": asr.label,
                    "audio": sound]
        (self.registry, self.model, self.voice, self.encyclopedia) = (registry, model, voice, encyclopedia)
        screen.ready = speech.ready && microphone && voice.ready
        if screen.ready { converse(model, hearing, voice, silero, asr.decode) }
        parseMemory()  // what a closed app left in the queue (M34)
    }

    /// The memory's base in `Application Support/Memory` (M38): out of the backup as read back, complete protection;
    /// a refusal — no memory, and the console says why.
    private func openMemory() {
        let support = files.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        switch MemoryFiles.prepare(under: support) {
        case .ready(let folder):
            memory = try? MemoryStore(directory: folder, flags: MemoryFiles.flags)
            screen.lines.append(memory == nil ? "память выключена: база не открылась" : "память: включена")
            if memory != nil, let off = MemoryConsole.conversation { screen.lines.append(off) }  // M40, 2026-10-28
            refreshMemoryLines()
        case .refused(let reason):
            screen.lines.append("память выключена: " + (reason == .backup ? "пометка «не в бэкап» не прочиталась"
                                                                         : "каталог не создан"))
        }
    }

    /// The queue's parse while she sleeps (M35): oldest first, a wordless line into `Caches/memory.jsonl`.
    private func parseMemory() {
        guard let memory, let model, parsing == nil else { return }
        let journal = caches.appendingPathComponent("memory.jsonl")
        occupy { [self] in
            let start = uptime, done = (try? await memory.drain(model: MemoryLlama(model: model))) ?? []
            if !done.isEmpty, let line = MemoryLlama.line(done, seconds: uptime - start, stats: model.completionStats) {
                if let handle = try? FileHandle(forWritingTo: journal) {
                    _ = try? handle.seekToEnd()
                    try? handle.write(contentsOf: line)
                } else {
                    try? line.write(to: journal)
                }
            }
            if !Task.isCancelled { await refreshPrefix(model) }  // what she knows now goes into the prefix (M36)
            refreshMemoryLines()
        }
    }

    /// The background or a wake: the parse stops at once and waits for the next sleep (M35).
    func pauseMemory() -> Task<Void, Never>? {
        let task = parsing
        task?.cancel()
        return task
    }

    /// Her voice: Supertonic when the files of voice.json are on the phone (V4b2), else Milena — the console says why.
    private func makeVoice(_ registry: ModelRegistry, rate: Double) -> any HerVoice {
        let milena = SystemVoice(identifier: registry.voice, rate: Float(rate))
        do {
            let settings = try VoiceSettings.decode(Data(contentsOf: Bundle.main.bundleURL
                .appendingPathComponent("voice.json")))
            let folder = files.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(settings.folder)
            if let note = settings.note { screen.lines.append(note) }
            if let missing = VoiceCheck.check(settings, in: folder).message {
                screen.lines.append(missing)
                return milena
            }
            // The app assembles the voice on the session's engine (D6.1): the player's node joins the graph before
            // voice processing goes on, and its sound tells the overlap counter when the voice sounds; the session for
            // the speaker before the first phrase is set by AudioIO.
            let accent = AccentPlacer.load(settings, folder: folder)
            screen.lines.append(accent.line)
            let renderer = try SupertonicRenderer(settings: settings, folder: folder, placer: accent.placer)
            let audio = audio
            let player = SoundingPlayer(EnginePlayer(engine: audio.engine, rate: renderer.rate),
                                        began: { audio.voiceStarted() }, ended: { audio.voiceEnded(at: $0) })
            let spoken = SpokenVoice(renderer: renderer, player: player, gap: 0.45 / settings.preset.speed)
            return SupertonicVoice(spoken, preset: settings.preset)
        } catch {
            screen.lines.append("голос не загрузился: " + "\(error)")
            return milena
        }
    }

    /// A tap on the sleeping friend: she greets and then talks without buttons until the session sleeps. The session of
    /// the shown screen wakes after the last one has ended (L60, L69); the microphone is open from its wake to its
    /// sleep (D6.1).
    func wake() {
        guard let talker = child ? childTalk : conversation, talk.phase == .asleep, !waking else { return }
        (screen.heard, screen.said) = ("", "")
        let previous = running, audio = audio, parse = pauseMemory(), music = music
        waking = true
        running = Task {
            await parse?.value  // one model: the parse gives it back first (M35)
            await previous?.value
            await music?.duck()  // the music quiet and on the voice's engine before the microphone opens (Y2)
            do { try audio.start() } catch { screen.lines.append("микрофон не открылся: \(error)") }
            music?.join()
            await talker.wake()
            await music?.release()
            audio.stop()
            waking = false
        }
    }

    /// background-music: the parent's line and the music's node on the session's engine.
    private func makeMusic(_ bundle: URL) -> BackgroundMusic {
        let line = MusicLine.decode((try? Data(contentsOf: bundle.appendingPathComponent("music.json"))) ?? Data())
        return BackgroundMusic(line: line, engine: audio.engine)
    }

    /// The console's music lines and the loop made in the background; no echo canceller (Milena) — no music in a talk.
    private func startMusic(_ music: BackgroundMusic, sound: String) {
        screen.lines += [music.line.console] + music.line.notes
            + (sound == "half" && music.line.on ? ["музыка: в разговоре молчит" + " — нет эхоподавления"] : [])
        self.music = music
        Task { await music.load(cancelsEcho: sound != "half") }
    }

    /// The microphone and the voice of a session (D6.1): Supertonic — one engine with voice processing, the ring and
    /// the counter outside a listening; Milena — half-duplex. The journal's `audio`: `vp+agc`, `vp` or `half`.
    private func duplex(_ voice: any HerVoice, _ hearing: Hearing, models: URL, silero: SileroActivity?) -> String {
        guard voice is SupertonicVoice else {
            screen.lines.append("звук: полудуплекс (Milena)")
            return "half"
        }
        // The ring's own activity: the listening's is reset at every listening (TurnDetector).
        let own = silero == nil ? nil : hearing.vad.flatMap {
            SileroActivity(model: models.appendingPathComponent($0.file), hearing: hearing)
        }
        do {
            let mode = try audio.goDuplex(hearing, activity: own ?? EnergyActivity(), feed: own.map { ring in
                { ring.feed($0) }
            }, flagMinimum: own == nil ? 0 : hearing.vad?.minSpeech ?? 0)
            screen.lines.append(mode.map { "звук: дуплекс · \($0)" } ?? "звук: полудуплекс (нет overlap)")
            return mode ?? "half"
        } catch {
            screen.lines.append("звук: полудуплекс — \(error)")
            return "half"
        }
    }

    /// Her «я всё» — the console's button, a tap on Elly while she listens: the shown session's utterance ends now.
    func done() {
        guard let talker = child ? childTalk : conversation else { return }
        Task { await talker.done() }
    }

    /// The parent's stop: silence now, no phrase.
    func stop() {
        guard let talker = child ? childTalk : conversation else { return }
        Task { await talker.stop() }
    }

    /// Her speech or tap over Elly — the ear's overlap, the child screen's tap while Elly speaks, the console's
    /// «Перебить» (D6.2): the shown session's Elly stops and listens at once.
    func bargeIn() {
        guard let talker = child ? childTalk : conversation else { return }
        Task { await talker.bargeIn() }
    }

    /// The audio session taken away or given back (a call, Siri, an alarm — D6.2): the shown session pauses and then
    /// listens again.
    private func interrupted(_ began: Bool) {
        if !began { music?.resume() }
        guard let talker = child ? childTalk : conversation else { return }
        Task { await talker.interruption(began: began) }
    }

    /// The session (D2.2): the router before the model and the encyclopedia after it (Э2, both sessions), the parent's
    /// limit key (`-session_limit_minutes 2` at launch), a wordless record a turn with the listening's stages into
    /// `Caches/turns.jsonl`; heard and said go to the screen.
    private func converse(_ model: LlamaModel, _ hearing: Hearing, _ voice: any HerVoice, _ silero: SileroActivity?,
                          _ decode: (@Sendable ([Float]) -> String)?) {
        let heard: @Sendable (String) -> Void = { text in Task { @MainActor in self.screen.heard = text } }
        let ear = PhoneListener(recognizer: recognizer, audio: audio, hearing: hearing,
                                resetSound: { voice.resetFirstSound() }, firstSound: { voice.firstSound }, heard: heard,
                                activity: silero, decode: decode)
        let echo = EchoVoice(voice) { sentence in Task { @MainActor in self.screen.said += sentence + " " } }
        let settings = SessionSettings(limitMinutes: UserDefaults.standard.object(forKey: SessionSettings.key)
            .map { "\($0)" })
        let versions = versions, journal = TraceFile(url: caches.appendingPathComponent("turns.jsonl")), audio = audio
        let memory = memory, console = UserDefaults.standard.bool(forKey: "memory_console")  // вопрос 3
        let tap = MemoryTap(audiences: console ? [.supervised, .parent] : [.supervised], take: { heard in
            try? memory?.enqueue(session: heard.session, started: Date(), turn: heard.turn, her: heard.her,
                                 elly: heard.elly)
        }, close: { _ in Task { @MainActor in
            self.refreshMemoryLines()
            self.parseMemory()
        } })
        let sink = TraceFanOut(memory == nil ? [journal] : [journal, tap])
        let encyclopedia = encyclopedia
        let stamp: @Sendable () -> TraceStamp = {
            let thermal = ["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue]
            let overlaps = audio.takeOverlaps().map { ["overlap": Double($0)] } ?? [:]  // D6.1: her speech over Elly
            return TraceStamp(versions: versions, memory: Self.memory(model), thermal: thermal,
                              stages: ear.takeStages().merging(voice.takeStages()) { $1 }.merging(overlaps) { $1 })
        }
        let parts = { (audience: Audience) in
            SessionParts(model: model, voice: echo, sink: sink, router: RouterRouting(), knowledge: encyclopedia,
                         audience: audience, stamp: stamp)
        }
        childMode = ChildMode(personaSHA256: versions["persona"] ?? "", model: versions["weights"] ?? "")
        refreshAccess()
        // The acceptance lies in the bundle and has no term (R2): `child` holds for the whole launch, so the child
        // session's audience is chosen once — the black box keeps only the supervised one.
        let conversation = Conversation(parts(.parent), settings: settings, listener: ear)
        let childTalk = Conversation(parts(access == .child ? .child : .supervised), settings: settings, listener: ear)
        (self.conversation, self.childTalk) = (conversation, childTalk)
        audio.whenOverlap { Task { @MainActor in self.bargeIn() } }  // D6.2: her speech over Elly cuts her
        audio.whenInterrupted { began in Task { @MainActor in self.interrupted(began) } }
        Task { for await state in childTalk.updates where child { show(state) } }
        screen.lines.append(settings.note ?? "лимит: \(Int(settings.limit / 60)) мин")
        if let note = nap.note { screen.lines.append(note) }
        if !RouterRouting.healthy { screen.lines.append("маршрутизатор: самопроверка не прошла") }
        Task { for await state in conversation.updates where !child { talk = state } }
    }

    /// The lock from the container, the bundle and the build (R): at launch, on the console, at the hand-over, at each
    /// wake on the child screen and when a child session ends.
    func refreshAccess() {
        guard let childMode else { return }
        (access, exception, acceptance) = (childMode.access(), childMode.present, childMode.acceptance)
    }

    /// «Дочке, при мне»: the parent's session stops; the child screen opens while the exception or the acceptance
    /// holds. The stop sign in its corner returns to this console in both modes (the console's own lock is not R2's).
    func handOver() {
        refreshAccess()
        guard access.open, let conversation else { return }
        Task { await conversation.stop() }
        child = true
        talk = childTalk?.state ?? TalkState()
    }

    /// A tap on the circle of the child screen: while Elly listens — «я всё» (D7), while she speaks — she is cut
    /// (D6.2); else she wakes, but past the exception's term she does not and the console returns, and during the break
    /// after the limit she only stirs.
    func childWake() {
        if talk.pose == .listens { return done() }
        if talk.pose == .speaks { return bargeIn() }
        refreshAccess()
        guard access.open else { return leaveChild() }
        guard !nap.holds(at: Date()) else { return }
        wake()
    }

    /// The console's line of the break while it holds: «перерыв до 18:40».
    var napLine: String? { nap.line(at: Date(), zone: .current) }

    /// The stop sign on the child screen: silence at once, no phrase, and the console — one action.
    func childStop() {
        stop()
        leaveChild()
    }

    /// «Закрыть детский режим»: the exception goes; a new one needs a new signature.
    func closeChildMode() {
        childMode?.close()
        refreshAccess()
        if child { childStop() }
    }

    /// A state of the child session; when one ends, the term is checked at this boundary, not in the middle of a talk.
    private func show(_ state: TalkState) {
        talk = state
        guard state.phase == .asleep, state.ended != nil else { return }
        nap.ended(state, at: Date())
        refreshAccess()
        if !access.open { leaveChild() }
    }

    private func leaveChild() {
        child = false
        talk = conversation?.state ?? TalkState()
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

    /// The app in front or behind (background-music): behind, the music goes.
    func front(_ shown: Bool) { music?.update { $0.front = shown } }

    private func line(_ stages: [String: Double]) -> String {
        stages.sorted { $0.key < $1.key }.map { "\($0.key) " + String(format: "%.2f с", $0.value) }
            .joined(separator: " · ")
    }
}

/// The memory in the conversation (memory-recall): the prefix with the block, the console's lines, the parent's erase.
extension VoiceLoop {
    /// The memory's one job at the model (M35): a wake waits for it, the background stops it; its end frees the slot
    /// unless a later job took it — an erase after the parse it stopped.
    private func occupy(_ work: @escaping @MainActor () async -> Void) {
        slot += 1
        let mine = slot
        parsing = Task {
            await work()
            if slot == mine { parsing = nil }
        }
    }

    /// The memory's block counted by `count`; empty without a memory (M36).
    nonisolated private static func block(_ memory: MemoryStore?, _ count: (String) -> Int) -> String {
        (try? memory?.block(count: count).text) ?? ""
    }

    /// The system turn with the block by the model's tokenizer (M36): rebuilt and written to its state file when it
    /// changed — the next session copies it.
    private func refreshPrefix(_ model: LlamaModel) async {
        let next = MemoryBlock.system(persona: persona, block: Self.block(memory, model.tokenCount))
        guard next != system else { return }
        do {
            try await model.rebuildPrefix(next, cache: caches)
            system = next
        } catch {
            screen.lines.append("память: префикс не собран — \(error)")
        }
    }

    /// The console's memory lines (M39): knows nothing, N facts, erased at …; waiting; a failed parse.
    func refreshMemoryLines() {
        memoryLines = memory.flatMap { try? MemoryConsole.lines($0, zone: .current) } ?? []
    }

    /// «Что помнит Элли»: the block as the model gets it.
    var memoryText: String { model.map { Self.block(memory, $0.tokenCount) } ?? "" }

    /// «Стереть всё, что помнит Элли? (N фактов)».
    var memoryConfirmation: String { MemoryConsole.confirmation(facts: (try? memory?.facts().count) ?? 0) }

    /// «Стереть память» (M39): the parse stops, the files go, the prefix is the persona again.
    func eraseMemory() {
        guard let memory, let model, talk.phase == .asleep else { return }
        let parse = pauseMemory()
        occupy { [self] in  // a wake waits for the erase as for a parse: one model, no reply while the prefix is built
            await parse?.value
            _ = try? memory.eraseAll(now: Date())
            await refreshPrefix(model)
            refreshMemoryLines()
        }
    }
}
