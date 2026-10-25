import AllyCore
import AllyOnnx
import AllySpeechText
import AllyVoice
import AllyVoiceFX
import Foundation

/// Her voice (voice series V4b2): Supertonic by the preset line, then PSOLA and the EQ — «Совсем малышка» by default —
/// with «Э́льли» and the reading rules of speech-text.json. The app assembles the `SpokenVoice` itself — the renderer
/// and the player on the session's engine — so D6.1 can wrap the player (its `SoundingPlayer`) and hold one
/// AVAudioEngine for the microphone and the voice; this class adds the console line and the version.
final class SupertonicVoice: HerVoice, VoiceLookahead, @unchecked Sendable {
    let note: String, label: String
    let ready = true
    private let spoken: SpokenVoice

    init(_ spoken: SpokenVoice, preset: VoicePresetLine) {
        self.spoken = spoken
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
    var rate: Int { synth.sampleRate }

    /// The voice folder's Supertonic, the bundled speech-text table and the processing of the preset line.
    init(settings: VoiceSettings, folder: URL) throws {
        synth = try SupertonicEngine(folder: folder.appendingPathComponent("supertonic"))
        text = SpeechTextPipeline(placer: PlainPlacer(), table: try .bundled())
        preset = settings.preset
        fx = try VoiceFX(settings.preset)
    }

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
