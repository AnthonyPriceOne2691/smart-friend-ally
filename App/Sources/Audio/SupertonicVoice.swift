import AllyAccent
import AllyCore
import AllyOnnx
import AllySpeechText
import AllyVoice
import AllyVoiceFX
import Foundation
import os

/// Her voice (voice series V4b2): Supertonic by the preset line, then PSOLA and the EQ — the parent's choice in
/// voice.json — with «Э́льли» and the reading rules of speech-text.json. The app assembles the `SpokenVoice` itself —
/// the renderer and the player on the session's engine — so D6.1 can wrap the player (its `SoundingPlayer`) and hold
/// one AVAudioEngine for the microphone and the voice; this class adds the console line and the version.
final class SupertonicVoice: HerVoice, VoiceLookahead, @unchecked Sendable {
    let note: String, label: String
    let ready = true
    private let spoken: SpokenVoice

    init(_ spoken: SpokenVoice, preset: VoicePresetLine) {
        self.spoken = spoken
        let shifts = "\(Int(preset.pitch))/\(Int(preset.formant))"
        note = "голос: " + "Supertonic \(preset.style) · \(shifts) · ORT \(OnnxRuntime.version)"
        label = "supertonic-3 \(preset.style) \(preset.speed) \(preset.firstSteps)/\(preset.steps) \(shifts) "
            + "x\(preset.stretch) r\(preset.range) eq\(preset.eq.count) ort\(OnnxRuntime.version)"
    }

    var firstSound: Double? { spoken.firstSound }
    func resetFirstSound() { spoken.resetFirstSound() }
    func takeStages() -> [String: Double] { spoken.takeStages() }
    func speak(_ sentence: String) async throws { try await spoken.speak(sentence) }
    func stop() { spoken.stop() }
    func upcoming(_ sentences: [String]) { spoken.upcoming(sentences) }
    func settle(_ seconds: Double) async throws { try await spoken.settle(seconds) }
}

/// One sentence made sound: the engine's text, the synthesis trimmed to its predicted length and to its speech, the
/// processing.
struct SupertonicRenderer: SentenceRenderer {
    let text: SpeechTextPipeline, synth: SupertonicEngine, preset: VoicePresetLine, fx: VoiceFX
    var rate: Int { synth.sampleRate }

    /// The voice folder's Supertonic, the bundled speech-text table over the placer, the processing of the preset line.
    init(settings: VoiceSettings, folder: URL, placer: any StressPlacer) throws {
        synth = try SupertonicEngine(folder: folder.appendingPathComponent("supertonic"))
        text = SpeechTextPipeline(placer: placer, table: try .bundled())
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
        let predicted = Array(audio.samples.prefix(Int(audio.duration * Double(audio.rate))))
        let samples = try SilenceTrim.standard.apply(predicted, rate: audio.rate)
        let synthesized = uptime
        let processed = try fx.process(samples, rate: audio.rate)
        return RenderedSentence(samples: processed, rate: audio.rate,
                                stages: ["voice_text": prepared - start, "voice_synth": synthesized - prepared,
                                         "voice_fx": uptime - synthesized])
    }

    private var uptime: Double { ProcessInfo.processInfo.systemUptime }
}

/// Without RUAccent: the phrase as written — pinned words, names and reading rules still apply.
struct PlainPlacer: StressPlacer {
    func place(_ text: String) throws -> String { text }
}

/// The placer of the voice (voice-accent-wire): RUAccent when the accent files of voice.json are there, else the plain
/// phrase; the console line says which and how long the loading took.
enum AccentPlacer {
    static func load(_ settings: VoiceSettings, folder: URL) -> (placer: any StressPlacer, line: String) {
        guard VoiceCheck.check(settings, in: folder, group: "accent") == .ready else {
            return (PlainPlacer(), "ударения: " + "нет файлов RUAccent" + " — без расстановщика")
        }
        let start = ProcessInfo.processInfo.systemUptime, base = folder.appendingPathComponent("ruaccent")
        do {
            let real = try RUAccentVoice.placer(nn: base.appendingPathComponent("nn"),
                                                dictionaries: base.appendingPathComponent("dictionary"))
            let seconds = String(format: "%.2f", ProcessInfo.processInfo.systemUptime - start)
            return (SafePlacer(real: real), "ударения: " + "RUAccent · \(seconds) с")
        } catch {
            return (PlainPlacer(), "ударения: " + "не загрузились — \(error)")
        }
    }
}

/// A refusal of the placer on one phrase leaves the phrase without its stresses — pinned words, names and reading
/// rules still apply — instead of failing the turn (V3b leaves it to the app). The log keeps the error's type only.
struct SafePlacer: StressPlacer {
    let real: any StressPlacer
    private static let log = Logger(subsystem: "com.anthonypriceone.ally", category: "voice")

    func place(_ text: String) throws -> String {
        do {
            return try real.place(text)
        } catch {
            Self.log.error("placer refused: \(String(describing: type(of: error)), privacy: .public)")
            return text
        }
    }
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
        self.init(pitch: preset.pitch, formant: preset.formant, stretch: preset.stretch, range: preset.range,
                  eq: VoiceEQ(bands: bands))
    }
}
