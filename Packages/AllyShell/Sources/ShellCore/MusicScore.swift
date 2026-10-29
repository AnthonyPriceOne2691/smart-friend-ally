import Foundation

/// The score of «Шкатулка Элли» (`MusicBox`): marimba arpeggios in eighths, a soft bass on the bar and the music box's
/// tune, 16 bars of F – Dm – Bb – C – F – Am – Bb·C – F twice. The order of the notes is the generator's: the sum
/// is made in it, and floats keep the order.
enum MusicScore {
    /// A note: when it starts, its instrument (0 marimba, 1 bass, 2 box), its MIDI pitch, gain and pan.
    struct Note {
        let start: Double, voice: Int, midi: Int, gain: Double, pan: Double
    }

    static let chords = [
        "F": "F3 C4 F4 A4 C5 A4 F4 C4", "Dm": "D3 A3 D4 F4 A4 F4 D4 A3", "Bb": "Bb2 F3 Bb3 D4 F4 D4 Bb3 F3",
        "C": "C3 G3 C4 E4 G4 E4 C4 G3", "Am": "A2 E3 A3 C4 E4 C4 A3 E3", "BbC": "Bb2 F3 Bb3 D4 C3 G3 C4 E4"
    ]
    static let roots = ["F": "F2", "Dm": "D2", "Bb": "Bb1", "C": "C2", "Am": "A1", "BbC": "Bb1 C2"]
    static let harmony = Array(repeating: ["F", "Dm", "Bb", "C", "F", "Am", "BbC", "F"], count: 2).flatMap { $0 }
    /// The tune, a bar a line: note and beats; `-` is a rest.
    static let tune = [
        "A5:1 C6:1 F6:1.5 E6:0.5", "D6:2 A5:1 F5:1", "G5:1 Bb5:1 D6:1.5 C6:0.5", "C6:2 G5:1 E5:1",
        "F5:1 A5:1 C6:1 F6:1", "E6:2 C6:1 A5:1", "Bb5:1 D6:1 C6:1 E6:1", "F6:3 -:1",
        "C6:1 A5:1 C6:1 F6:1", "F6:1.5 E6:0.5 D6:2", "D6:1 F6:1 D6:1 Bb5:1", "C6:1 E6:1 G6:2",
        "A6:1.5 G6:0.5 F6:1 C6:1", "E6:1 C6:1 A5:2", "D6:1 Bb5:1 G5:1 E6:1", "F6:2 C6:1 -:1"
    ]

    /// Every note of one pass, bar by bar: the marimba, the bass, the tune.
    static func notes() -> [Note] {
        let beat = MusicBox.beat
        var out: [Note] = []
        for (bar, chord) in harmony.enumerated() {
            let start = Double(bar * 4) * beat
            for (index, name) in words(chords[chord]).enumerated() {
                let accent = index % 2 == 0 ? 1.0 : 0.78
                out.append(Note(start: start + Double(index) * beat / 2, voice: 0, midi: midi(name),
                                gain: 0.20 * accent, pan: 0.40))
            }
            for (index, name) in words(roots[chord]).enumerated() {
                out.append(Note(start: start + Double(index * 2) * beat, voice: 1, midi: midi(name), gain: 0.22,
                                pan: 0.5))
            }
            var at = start
            for item in words(tune[bar]) {
                let parts = item.split(separator: ":").map(String.init)
                if parts[0] != "-" {
                    out.append(Note(start: at, voice: 2, midi: midi(parts[0]), gain: 0.30, pan: 0.58))
                }
                at += (Double(parts[1]) ?? 0) * beat
            }
        }
        return out
    }

    /// «Bb5» → 82.
    static func midi(_ name: String) -> Int {
        let steps: [Character: Int] = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]
        let flat = name.dropFirst().first == "b", octave = Int(name.dropFirst(flat ? 2 : 1)) ?? 0
        return 12 * (octave + 1) + (steps[name.first ?? "C"] ?? 0) - (flat ? 1 : 0)
    }

    private static func words(_ line: String?) -> [String] { (line ?? "").split(separator: " ").map(String.init) }
}
