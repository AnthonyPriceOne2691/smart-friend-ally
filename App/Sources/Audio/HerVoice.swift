import AllyCore

/// Her voice as the loop uses it (V4b2): Supertonic, or Milena when the voice files are not there — the first sound
/// for the listener, the stages for the record, the console line, the version, whether it can speak.
protocol HerVoice: VoiceOutput {
    var firstSound: Double? { get }
    func resetFirstSound()
    func takeStages() -> [String: Double]
    var note: String { get }
    var label: String { get }
    var ready: Bool { get }
}

extension SystemVoice: HerVoice {
    func takeStages() -> [String: Double] { [:] }
    var label: String { voice?.identifier ?? "" }
    var ready: Bool { voice != nil }
}
