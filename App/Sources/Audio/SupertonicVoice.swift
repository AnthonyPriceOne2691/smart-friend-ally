import AllyCore
import AllyOnnx
import AllySpeechText
import AllyVoice
import AllyVoiceFX
import AVFoundation

/// Her voice (voice series V4b2): Supertonic by the preset line, then PSOLA and the EQ — «Совсем малышка» by default —
/// with «Э́льли» and the reading rules of speech-text.json. The engine is the session's: D6.1 holds one AVAudioEngine
/// for the microphone and the voice, and the voice attaches its player node to the one it is given.
final class SupertonicVoice: HerVoice, VoiceLookahead, @unchecked Sendable {
    let note: String, label: String
    let ready = true
    private let spoken: SpokenVoice

    init(engine: AVAudioEngine, settings: VoiceSettings, folder: URL) throws {
        let synth = try SupertonicEngine(folder: folder.appendingPathComponent("supertonic"))
        let preset = settings.preset
        let renderer = SupertonicRenderer(text: SpeechTextPipeline(placer: PlainPlacer(), table: try .bundled()),
                                          synth: synth, preset: preset, fx: try VoiceFX(preset))
        spoken = SpokenVoice(renderer: renderer, player: EnginePlayer(engine: engine, rate: synth.sampleRate),
                             gap: 0.45 / preset.speed)
        let shifts = "\(Int(preset.pitch))/\(Int(preset.formant))"
        note = "голос: " + "Supertonic \(preset.style) · \(shifts) · ORT \(OnnxRuntime.version)"
        label = "supertonic-3 \(preset.style) \(preset.speed) \(preset.firstSteps)/\(preset.steps) \(shifts) "
            + "eq\(preset.eq.count) ort\(OnnxRuntime.version)"
    }

    var firstSound: Double? { spoken.firstSound }
    func resetFirstSound() { spoken.resetFirstSound() }
    func takeStages() -> [String: Double] { spoken.takeStages() }
    func speak(_ sentence: String) async throws { try await spoken.speak(sentence) }
    func stop() { spoken.stop() }
    func upcoming(_ sentences: [String]) { spoken.upcoming(sentences) }
}

/// One sentence made sound: the engine's text, the synthesis trimmed to its predicted length, the processing.
struct SupertonicRenderer: SentenceRenderer {
    let text: SpeechTextPipeline, synth: SupertonicEngine, preset: VoicePresetLine, fx: VoiceFX

    func render(_ sentence: String, first: Bool) throws -> RenderedSentence {
        let start = uptime
        let line = try text.prepare(sentence).engine
        let prepared = uptime
        let steps = first ? preset.firstSteps : preset.steps
        let audio = try synth.synthesize(line, voice: VoicePreset(style: preset.style, speed: preset.speed,
                                                                  steps: steps))
        let samples = Array(audio.samples.prefix(Int(audio.duration * Double(audio.rate))))
        let synthesized = uptime
        let processed = try fx.process(samples, rate: audio.rate)
        return RenderedSentence(samples: processed, rate: audio.rate,
                                stages: ["voice_text": prepared - start, "voice_synth": synthesized - prepared,
                                         "voice_fx": uptime - synthesized])
    }

    private var uptime: Double { ProcessInfo.processInfo.systemUptime }
}

/// Until RUAccent lands (V3c): the phrase as written — pinned words, names and reading rules still apply.
struct PlainPlacer: StressPlacer {
    func place(_ text: String) throws -> String { text }
}

/// A band kind the line wrote but the processing does not have.
struct UnknownBand: Error, CustomStringConvertible {
    let kind: String
    var description: String { "band \(kind)" }
}

extension VoiceFX {
    /// The processing of the preset line: shifts in semitones and the EQ bands.
    init(_ preset: VoicePresetLine) throws {
        let kinds: [String: EQBand.Kind] = ["lowshelf": .lowShelf, "peak": .peak, "highshelf": .highShelf]
        let bands = try preset.eq.map { band -> EQBand in
            guard let kind = kinds[band.kind] else { throw UnknownBand(kind: band.kind) }
            return EQBand(kind, frequency: band.frequency, gainDB: band.gainDB, q: band.q)
        }
        self.init(pitch: preset.pitch, formant: preset.formant, eq: VoiceEQ(bands: bands))
    }
}
