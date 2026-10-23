import AllyOnnx
import XCTest

/// The layer over the C API of the one ORT (V1 voice-onnx): the linked build, a session from a file, named tensors in
/// and out, errors with a reason. `add.onnx` (108 bytes, onnx 1.23.2 on the Mac): c = a + b, float32 [n, 3].
final class OnnxSessionTests: XCTestCase {
    private var addModel: URL {
        get throws {
            try XCTUnwrap(Bundle.module.url(forResource: "add", withExtension: "onnx"))
        }
    }

    func testLinkedRuntimeIsTheOfficial128() {
        XCTAssertEqual(OnnxRuntime.version, "1.28.0")
        XCTAssertEqual(OnnxRuntime.apiVersion, 28)
    }

    func testRunReturnsNamedOutputsWithShape() throws {
        let session = try OnnxSession(path: addModel)
        let a: [Float] = [1, 2, 3, 4, 5, 6], b: [Float] = [0.5, 0.5, 0.5, -1, -2, -3]
        let out = try session.run(["a": .float(a, shape: [2, 3]), "b": .float(b, shape: [2, 3])], outputs: ["c"])
        XCTAssertEqual(out["c"], .float([1.5, 2.5, 3.5, 3, 3, 3], shape: [2, 3]))
    }

    func testRunsAreRepeatableAndIndependent() throws {
        let session = try OnnxSession(path: addModel)
        let inputs: [String: OnnxTensor] = ["a": .float([1, 1, 1], shape: [1, 3]),
                                            "b": .float([2, 3, 4], shape: [1, 3])]
        let first = try session.run(inputs, outputs: ["c"]), second = try session.run(inputs, outputs: ["c"])
        XCTAssertEqual(first, second)
        XCTAssertEqual(first["c"]?.floats, [3, 4, 5])
    }

    func testMissingFileNamesThePath() {
        let path = URL(fileURLWithPath: "/nonexistent/vocoder.onnx")
        XCTAssertThrowsError(try OnnxSession(path: path)) { error in
            XCTAssertTrue("\(error)".contains("/nonexistent/vocoder.onnx"), "\(error)")
        }
    }

    func testShapeAndValuesMustAgree() throws {
        let session = try OnnxSession(path: addModel)
        let wrong: [String: OnnxTensor] = ["a": .float([1, 2], shape: [1, 3]), "b": .float([1, 2, 3], shape: [1, 3])]
        XCTAssertThrowsError(try session.run(wrong, outputs: ["c"])) { error in
            XCTAssertTrue("\(error)".contains("input a"), "\(error)")
        }
    }

    func testOrtErrorCarriesItsMessage() throws {
        let session = try OnnxSession(path: addModel)
        XCTAssertThrowsError(try session.run(["a": .float([1, 2, 3], shape: [1, 3])], outputs: ["c"])) { error in
            XCTAssertTrue("\(error)".hasPrefix("Run add.onnx: "), "\(error)")
        }
    }

    func testOptionsAreWhatTheVoiceAsks() {
        XCTAssertEqual(OnnxOptions().description, "threads=2 spin=0")
        XCTAssertEqual(OnnxOptions(intraOpThreads: 4, allowSpinning: true).description, "threads=4 spin=1")
    }
}
