@testable import AllyCore
import Foundation
import XCTest

final class VoiceSettingsTests: XCTestCase {
    private let line = #"{"style": "F2", "speed": 0.9, "steps": 8, "pitch": 9, "formant": 5, "eq": "#
        + #"[["lowshelf", 250, -3, 0.7], ["peak", 4000, 2.5, 0.9]]}"#

    private func settings(preset: String? = nil, files: String = "[]") throws -> VoiceSettings {
        let json = #"{"preset": "# + (preset ?? line) + #", "folder": "Voice", "files": "# + files + "}"
        return try VoiceSettings.decode(Data(json.utf8))
    }

    /// The parent's choice of 2026-10-23 (round 3, p9f5): style, speed, steps.
    private static let chosen = ["F2", "0.9", "8"]

    private var shipped: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../../App/Resources")
            .appendingPathComponent("voice.json").standardizedFileURL
    }

    func testTheShippedLineIsTheParentsChoice() throws {
        // Z19: voice.json carries «Совсем малышка» — F2, 0.9, 8 steps, +9 / +5, the «light» bands
        let voice = try VoiceSettings.decode(Data(contentsOf: shipped))
        let preset = voice.preset
        XCTAssertEqual([preset.style, "\(preset.speed)", "\(preset.steps)"], Self.chosen)
        XCTAssertEqual([preset.pitch, preset.formant], [9, 5])
        XCTAssertEqual(preset.eq.map(\.kind), ["lowshelf", "peak"])
        XCTAssertEqual(preset.eq.map { [$0.frequency, $0.gainDB, $0.q] }, [[250, -3, 0.7], [4000, 2.5, 0.9]])
        XCTAssertNil(voice.note)
        XCTAssertEqual(voice.folder, "Voice")
        XCTAssertEqual(Set(voice.files.map(\.group)), ["voice", "accent"])
    }

    func testEditingTheLineChangesThePresetWithoutCode() throws {
        // Z19: the same line with the pitch at +8 — the preset follows the data
        let edited = try settings(preset: line.replacingOccurrences(of: #""pitch": 9"#, with: #""pitch": 8"#))
        XCTAssertEqual(edited.preset.pitch, 8)
        XCTAssertEqual(try settings().preset.pitch, 9)
    }

    func testSpeedBelowTheFloorIsTakenAtTheFloorWithAConsoleLine() throws {
        // Z19: speed 0.80 — the console line and 0.85
        let slow = try settings(preset: line.replacingOccurrences(of: #""speed": 0.9"#, with: #""speed": 0.8"#))
        XCTAssertEqual(slow.note, "скорость 0,80 ниже 0,85 — взято 0,85")
        XCTAssertEqual(slow.preset.speed, 0.85)
        let floor = try settings(preset: line.replacingOccurrences(of: #""speed": 0.9"#, with: #""speed": 0.85"#))
        XCTAssertNil(floor.note)
        XCTAssertEqual(floor.preset.speed, 0.85)
    }

    func testAnUnknownBandIsRefused() throws {
        // Z19: a band the stand does not have is an error of the line, not a silent default
        XCTAssertThrowsError(try settings(preset: line.replacingOccurrences(of: "lowshelf", with: "notch")))
    }

    func testTheCheckSaysWhatIsMissingOrWrongInWords() throws {
        // Z20: no file, the wrong size, all there — the accent group is not the app's yet
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("onnx"),
                                                withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let files = #"[{"to": "onnx/a.onnx", "bytes": 4, "group": "voice"}, "#
            + #"{"to": "dict/b.json", "bytes": 9, "group": "accent"}]"#
        let voice = try settings(files: files)
        XCTAssertEqual(VoiceCheck.check(voice, in: folder).message, "голоса нет: скопируй с Mac")
        try Data("abc".utf8).write(to: folder.appendingPathComponent("onnx/a.onnx"))
        XCTAssertEqual(VoiceCheck.check(voice, in: folder).message, "голос не тот: 3 байт вместо 4")
        try Data("abcd".utf8).write(to: folder.appendingPathComponent("onnx/a.onnx"))
        XCTAssertEqual(VoiceCheck.check(voice, in: folder), .ready)
        XCTAssertNil(VoiceCheck.check(voice, in: folder).message)
    }
}
