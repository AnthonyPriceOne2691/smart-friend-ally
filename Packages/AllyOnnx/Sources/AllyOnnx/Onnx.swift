import COnnxRuntime
import Foundation

/// A failed call into ONNX Runtime: ORT's own message and what was being done.
public struct OnnxError: Error, CustomStringConvertible, Sendable {
    public let message: String
    public var description: String { message }
    init(_ message: String) { self.message = message }
}

/// The runtime build linked into the app — one per process (`Packages/AllyOnnx`).
public enum OnnxRuntime {
    /// The version string of the linked build, e.g. "1.28.0".
    public static var version: String {
        OrtGetApiBase().pointee.GetVersionString().map { String(cString: $0) } ?? ""
    }
    /// The C API version this layer asks for: `ORT_API_VERSION` of the headers.
    public static let apiVersion = Int(ORT_API_VERSION)

    /// Whether the linked build serves this C API version (sherpa-onnx 1.13.8 asks for 28; D7.2).
    public static func serves(api: Int) -> Bool { OrtGetApiBase().pointee.GetApi(UInt32(api)) != nil }
}

/// A tensor into or out of a session: float32 or int64 values, row-major, with their shape.
public enum OnnxTensor: Sendable, Equatable {
    case float([Float], shape: [Int])
    case int64([Int64], shape: [Int])

    public var shape: [Int] {
        switch self {
        case .float(_, let shape), .int64(_, let shape): shape
        }
    }

    /// The float values, empty for an int64 tensor.
    public var floats: [Float] {
        if case .float(let values, _) = self { return values }
        return []
    }

    var count: Int {
        switch self {
        case .float(let values, _): values.count
        case .int64(let values, _): values.count
        }
    }

    var elementType: ONNXTensorElementDataType {
        switch self {
        case .float: ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT
        case .int64: ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64
        }
    }

    func copy(into data: UnsafeMutableRawPointer) {
        let write = { (bytes: UnsafeRawBufferPointer) in
            if let base = bytes.baseAddress { data.copyMemory(from: base, byteCount: bytes.count) }
        }
        switch self {
        case .float(let values, _): values.withUnsafeBytes(write)
        case .int64(let values, _): values.withUnsafeBytes(write)
        }
    }
}

/// Session options the voice needs and writes into its journal line: intra-op threads and spin-wait. Graph
/// optimizations are always on (`ORT_ENABLE_ALL`). The model and the hearing share the CPU, so threads sleep between
/// runs instead of spinning (the bench saw 21 s instead of 4 s with spinning under load).
public struct OnnxOptions: Sendable, CustomStringConvertible {
    public var intraOpThreads: Int
    public var allowSpinning: Bool

    public init(intraOpThreads: Int = 2, allowSpinning: Bool = false) {
        (self.intraOpThreads, self.allowSpinning) = (intraOpThreads, allowSpinning)
    }

    public var description: String { "threads=\(intraOpThreads) spin=\(allowSpinning ? 1 : 0)" }
}

/// One model: named inputs in, named outputs out as copies. A model in external-data format is read next to its graph
/// and mapped from the file by ORT. Runs of one session may come from different threads (ORT allows it).
public final class OnnxSession: @unchecked Sendable {
    public let path: URL, options: OnnxOptions
    private let handle: OpaquePointer, api: OrtApi

    public init(path: URL, options: OnnxOptions = OnnxOptions()) throws {
        guard FileManager.default.fileExists(atPath: path.path) else { throw OnnxError("no model file: \(path.path)") }
        let api = try Ort.table(), env = try Ort.env.get()
        var made: OpaquePointer?
        try Ort.check(api.CreateSessionOptions(&made), "CreateSessionOptions")
        guard let settings = made else { throw OnnxError("CreateSessionOptions gave nothing") }
        defer { api.ReleaseSessionOptions(settings) }
        try Ort.check(api.SetIntraOpNumThreads(settings, Int32(options.intraOpThreads)), "SetIntraOpNumThreads")
        try Ort.check(api.AddSessionConfigEntry(settings, "session.intra_op.allow_spinning",
                                                options.allowSpinning ? "1" : "0"), "allow_spinning")
        try Ort.check(api.SetSessionGraphOptimizationLevel(settings, ORT_ENABLE_ALL), "graph optimization")
        var session: OpaquePointer?
        try Ort.check(api.CreateSession(env, path.path, settings, &session), "CreateSession \(path.lastPathComponent)")
        guard let session else { throw OnnxError("CreateSession gave nothing: \(path.path)") }
        (self.path, self.options, handle, self.api) = (path, options, session, api)
    }

    deinit { api.ReleaseSession(handle) }

    public func run(_ inputs: [String: OnnxTensor], outputs: [String]) throws -> [String: OnnxTensor] {
        let names = Array(inputs.keys)
        var values: [OpaquePointer?] = []
        defer { values.forEach { $0.map { api.ReleaseValue($0) } } }
        for name in names { values.append(try value(of: inputs[name] ?? .float([], shape: [0]), name: name)) }
        var results = [OpaquePointer?](repeating: nil, count: outputs.count)
        defer { results.forEach { $0.map { api.ReleaseValue($0) } } }
        try Ort.withCStrings(names) { inputNames in
            try Ort.withCStrings(outputs) { outputNames in
                try Ort.check(api.Run(handle, nil, inputNames, values, names.count, outputNames, outputs.count,
                                      &results), "Run \(path.lastPathComponent)")
            }
        }
        var out: [String: OnnxTensor] = [:]
        for (name, result) in zip(outputs, results) {
            guard let result else { throw OnnxError("no output \(name) of \(path.lastPathComponent)") }
            out[name] = try tensor(of: result, name: name)
        }
        return out
    }

    private func value(of tensor: OnnxTensor, name: String) throws -> OpaquePointer {
        guard tensor.count == tensor.shape.reduce(1, *) else {
            throw OnnxError("input \(name): \(tensor.count) values for shape \(tensor.shape)")
        }
        var allocator: UnsafeMutablePointer<OrtAllocator>?
        try Ort.check(api.GetAllocatorWithDefaultOptions(&allocator), "allocator")
        var made: OpaquePointer?
        let shape = tensor.shape.map(Int64.init)
        try Ort.check(api.CreateTensorAsOrtValue(allocator, shape, shape.count, tensor.elementType, &made),
                      "tensor \(name)")
        guard let value = made else { throw OnnxError("tensor \(name) gave nothing") }
        do {
            var data: UnsafeMutableRawPointer?
            try Ort.check(api.GetTensorMutableData(value, &data), "data of \(name)")
            if let data { tensor.copy(into: data) }
            return value
        } catch {
            api.ReleaseValue(value)
            throw error
        }
    }

    private func tensor(of value: OpaquePointer, name: String) throws -> OnnxTensor {
        var made: OpaquePointer?
        try Ort.check(api.GetTensorTypeAndShape(value, &made), "shape of \(name)")
        guard let info = made else { throw OnnxError("shape of \(name) gave nothing") }
        defer { api.ReleaseTensorTypeAndShapeInfo(info) }
        var rank = 0, count = 0, type = ONNX_TENSOR_ELEMENT_DATA_TYPE_UNDEFINED
        try Ort.check(api.GetDimensionsCount(info, &rank), "rank of \(name)")
        var dims = [Int64](repeating: 0, count: rank)
        try Ort.check(api.GetDimensions(info, &dims, rank), "dims of \(name)")
        try Ort.check(api.GetTensorElementType(info, &type), "type of \(name)")
        try Ort.check(api.GetTensorShapeElementCount(info, &count), "size of \(name)")
        var data: UnsafeMutableRawPointer?
        try Ort.check(api.GetTensorMutableData(value, &data), "data of \(name)")
        let shape = dims.map { Int($0) }
        switch type {
        case ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT:
            let start = data?.assumingMemoryBound(to: Float.self)
            return .float(Array(UnsafeBufferPointer(start: start, count: start == nil ? 0 : count)), shape: shape)
        case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64:
            let start = data?.assumingMemoryBound(to: Int64.self)
            return .int64(Array(UnsafeBufferPointer(start: start, count: start == nil ? 0 : count)), shape: shape)
        default:
            throw OnnxError("output \(name): element type \(type.rawValue) is not float32 or int64")
        }
    }
}

/// The C API table, the process environment and the status check.
enum Ort {
    static let api: OrtApi? = OrtGetApiBase().pointee.GetApi(UInt32(ORT_API_VERSION))?.pointee

    /// One environment per process; ORT keeps it a singleton anyway, so the hearing's sherpa-onnx shares it.
    static let env: Result<OpaquePointer, OnnxError> = {
        do {
            let api = try table()
            var env: OpaquePointer?
            try check(api.CreateEnv(ORT_LOGGING_LEVEL_WARNING, "ally", &env), "CreateEnv")
            guard let env else { throw OnnxError("CreateEnv gave nothing") }
            return .success(env)
        } catch {
            return .failure(error as? OnnxError ?? OnnxError("\(error)"))
        }
    }()

    static func table() throws -> OrtApi {
        guard let api else {
            throw OnnxError("ONNX Runtime \(OnnxRuntime.version) has no API \(OnnxRuntime.apiVersion)")
        }
        return api
    }

    static func check(_ status: OpaquePointer?, _ what: @autoclosure () -> String) throws {
        guard let status else { return }
        let api = try table()
        let message = api.GetErrorMessage(status).map { String(cString: $0) } ?? "no message"
        api.ReleaseStatus(status)
        throw OnnxError("\(what()): \(message)")
    }

    static func withCStrings<T>(_ strings: [String], _ body: ([UnsafePointer<CChar>?]) throws -> T) rethrows -> T {
        let copies = strings.map { strdup($0) }
        defer { copies.forEach { free($0) } }
        return try body(copies.map { $0.map { UnsafePointer($0) } })
    }
}
