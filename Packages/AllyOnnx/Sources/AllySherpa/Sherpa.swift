import AllyOnnx
@_exported import SherpaOnnxC

/// sherpa-onnx linked into the app (D7.2): its version, and the C API of ONNX Runtime it was built with — the pair
/// holds when the linked runtime serves that API.
public enum Sherpa {
    /// The version string of the linked build, e.g. "1.13.8".
    public static var version: String { String(cString: SherpaOnnxGetVersionStr()) }

    /// `ORT_API_VERSION` of the headers sherpa-onnx 1.13.8 was compiled against.
    public static let api = 28

    /// Whether the linked runtime serves sherpa's API.
    public static var paired: Bool { OnnxRuntime.serves(api: api) }
}
