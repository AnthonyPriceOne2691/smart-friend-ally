import AllyCore

/// Her voice as the loop uses it (V4b2): Supertonic, or Milena when the voice files are not there — the first sound
/// for the listener, the stages for the record, the console line, the version, whether it can speak, and the wait for a
/// quiet room before the ear opens.
protocol HerVoice: VoiceOutput {
    var firstSound: Double? { get }
    func resetFirstSound()
    func takeStages() -> [String: Double]
    var note: String { get }
    var label: String { get }
    var ready: Bool { get }
    func settle(_ seconds: Double) async throws
}

extension SystemVoice: HerVoice {
    func takeStages() -> [String: Double] { [:] }
    var label: String { voice?.identifier ?? "" }
    var ready: Bool { voice != nil }
    func settle(_ seconds: Double) async throws {}  // Milena has none of the synthesis's silence and never had a wait
}
