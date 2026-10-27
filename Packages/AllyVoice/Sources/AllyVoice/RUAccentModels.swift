import AllyAccent
import AllyOnnx
import Foundation

/// Три модели RUAccent на общем ONNX Runtime (V3c): омографы turbo3.1 int8 с весами в external data, «ё» (distilbert) и
/// модель слов (roformer). Контракт стыка V3b: одно `Encoding` — один вызов без паддинга; омографы — логиты `[2]`
/// (индекс 1 — «гипотеза верна»), «ё» и модель слов — строка логитов `[3]` на каждый токен, включая служебные.
public final class RUAccentModels: Sendable {
    let omographs: OnnxSession
    let yoModel: OnnxSession
    let words: OnnxSession

    public init(omograph: URL, yo: URL, accent: URL, options: OnnxOptions = OnnxOptions()) throws {
        omographs = try OnnxSession(path: omograph, options: options)
        yoModel = try OnnxSession(path: yo, options: options)
        words = try OnnxSession(path: accent, options: options)
    }

    public func omograph(_ pair: Encoding) throws -> [Float] {
        try logits(omographs, pair, typeIds: false).floats
    }

    public func yo(_ sentence: Encoding) throws -> [[Float]] {
        try rows(logits(yoModel, sentence, typeIds: false))
    }

    public func accent(_ word: Encoding) throws -> [[Float]] {
        try rows(logits(words, word, typeIds: true))
    }

    private func logits(_ session: OnnxSession, _ input: Encoding, typeIds: Bool) throws -> OnnxTensor {
        let shape = [1, input.ids.count]
        var feeds: [String: OnnxTensor] = [
            "input_ids": .int64(input.ids.map(Int64.init), shape: shape),
            "attention_mask": .int64(input.attentionMask.map(Int64.init), shape: shape)
        ]
        if typeIds { feeds["token_type_ids"] = .int64(input.typeIds.map(Int64.init), shape: shape) }
        // Нет выхода — пустой тензор: форму судит логика (`AccentError.shape`), как договорено в стыке.
        return try session.run(feeds, outputs: ["logits"])["logits"] ?? .float([], shape: [0])
    }

    /// `[1, n, k]` → n строк по k.
    private func rows(_ tensor: OnnxTensor) -> [[Float]] {
        let width = tensor.shape.last ?? 1
        return stride(from: 0, to: tensor.floats.count, by: max(width, 1)).map {
            Array(tensor.floats[$0..<min($0 + width, tensor.floats.count)])
        }
    }
}
