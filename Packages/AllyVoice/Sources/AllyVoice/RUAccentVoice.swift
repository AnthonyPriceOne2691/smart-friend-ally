import AllyAccent
import AllyOnnx
import Foundation

extension RUAccentModels: AccentModels {}

/// Настоящий расстановщик ударений из файлов RUAccent (V3c): токенизаторы V3a, логика V3b, модели V3c. Раскладка —
/// как в `~/models/tts/ruaccent`: `nn/` (модели и токенизаторы) и каталог словарей в простом JSON (`.gz` распаковывает
/// команда копирования V4). До V4 вызывающего в приложении нет (L50).
public enum RUAccentVoice {
    public static func placer(nn: URL, dictionaries: URL,
                              options: OnnxOptions = OnnxOptions()) throws -> RuAccentPlacer {
        let file = { (path: String) in nn.appendingPathComponent(path) }
        // Словари — первыми: временная память разбора JSON переиспользуется дальше (замер: +160 МБ против +175 при
        // словарях последними; Z17).
        let tables = try AccentDictionaries(directory: dictionaries)
        let tokenizers = RuAccentTokenizers(
            wordPiece: try WordPieceTokenizer(tokenizerJSON: file("nn_yo_homograph_resolver/tokenizer.json")),
            bpe: try ByteLevelBPETokenizer(tokenizerJSON: file("nn_omograph/turbo3.1/tokenizer.json")),
            char: try CharTokenizer(vocab: file("nn_accent/vocab.txt")))
        let models = try RUAccentModels(omograph: file("nn_omograph/turbo3.1-int8/turbo31_int8.onnx"),
                                        yo: file("nn_yo_homograph_resolver/model.onnx"),
                                        accent: file("nn_accent/model.onnx"), options: options)
        return RuAccentPlacer(dictionaries: tables, tokenizers: tokenizers, models: models)
    }
}
