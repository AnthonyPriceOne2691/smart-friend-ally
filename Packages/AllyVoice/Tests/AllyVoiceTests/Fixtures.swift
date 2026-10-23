import AllyVoice
import Darwin
import XCTest

/// Where the Mac keeps what git does not: the Supertonic weights in external-data format and the Python references of
/// the stand (supertonic-py 1.3.1, onnxruntime 1.31, the SDK's own noise). Missing → a visible skip, not a pass (П34);
/// the test names the folder it read (L47).
enum Fixtures {
    static let home = FileManager.default.homeDirectoryForCurrentUser
    static let model = home.appendingPathComponent("models/tts/supertonic-3-ext")
    static let parity = home.appendingPathComponent("models/tts/supertonic-parity")

    /// One engine for the whole test run: loading is ≈ 0.3 s, and the tests measure the engine, not its loading twice.
    nonisolated(unsafe) static var shared: SupertonicEngine?

    static func engine() throws -> SupertonicEngine {
        if let shared { return shared }
        guard FileManager.default.fileExists(atPath: model.appendingPathComponent("onnx/tts.json").path) else {
            throw XCTSkip("нет весов Supertonic в \(model.path) — проверка не выполнена")
        }
        let made = try SupertonicEngine(folder: model)
        shared = made
        log("модель: \(model.path), \(made.options)")
        return made
    }

    static func references(_ set: String) throws -> URL {
        let folder = parity.appendingPathComponent(set)
        guard FileManager.default.fileExists(atPath: folder.appendingPathComponent("manifest.jsonl").path) else {
            throw XCTSkip("нет эталонов Python в \(folder.path) — паритет не проверен")
        }
        log("эталоны: \(folder.path)")
        return folder
    }

    /// Lines of a JSONL file as dictionaries.
    static func jsonLines(_ url: URL) throws -> [[String: Any]] {
        try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
            .compactMap { try JSONSerialization.jsonObject(with: Data($0.utf8)) as? [String: Any] }
    }

    /// A raw little-endian float32 file, as numpy's `astype('<f4').tofile`.
    static func floats(_ url: URL) throws -> [Float] {
        try Data(contentsOf: url).withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }

    /// 10·log10(Σ ref² / Σ (ref − out)²); +∞ when equal.
    static func snr(_ out: [Float], _ ref: [Float]) -> Double {
        let signal = ref.reduce(0) { $0 + Double($1) * Double($1) }
        let noise = zip(out, ref).reduce(0) { $0 + pow(Double($1.0) - Double($1.1), 2) }
        return noise == 0 ? .infinity : 10 * log10(signal / noise)
    }

    static func log(_ line: String) { FileHandle.standardError.write(Data((line + "\n").utf8)) }
}

/// What iOS counts against the memory limit (phys_footprint), now and its lifetime peak, in MB (L22).
struct Footprint {
    let now: Double, peak: Double

    static func read() -> Footprint {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return Footprint(now: -1, peak: -1) }
        return Footprint(now: Double(info.phys_footprint) / 1_048_576,
                         peak: Double(info.ledger_phys_footprint_peak) / 1_048_576)
    }
}
