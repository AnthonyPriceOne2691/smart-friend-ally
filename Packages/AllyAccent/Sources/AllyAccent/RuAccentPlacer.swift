import AllySpeechText
import Foundation

/// Расстановщик RUAccent 1.5.8.3 (tiny mode, омографы turbo3.1, «поняла») на Swift — логика Python как есть: фильтр,
/// предложения, «ё», омографы, ударения, склейка. Токенизаторы — V3a, модели — V3c; до V4 вызывающего нет (L50).
public struct RuAccentPlacer: StressPlacer {
    let yo: YoDecision
    let omographs: OmographDecision
    let stress: StressDecision

    public init(dictionaries: AccentDictionaries, tokenizers: any AccentTokenizers, models: any AccentModels) {
        yo = YoDecision(dictionaries: dictionaries, tokenizers: tokenizers, models: models)
        omographs = OmographDecision(dictionaries: dictionaries, tokenizers: tokenizers, models: models)
        stress = StressDecision(dictionaries: dictionaries, tokenizers: tokenizers, models: models)
    }

    /// Отказ модели (выход не той формы) пробрасывается: что звучит без ударений, решает приложение (V4).
    public func place(_ text: String) throws -> String {
        try AccentText.sentences(AccentText.normalize(text)).map(sentence).joined()
    }

    /// Предложение без слов — пустая строка, как у Python.
    private func sentence(_ text: String) throws -> String {
        let (words, gaps) = AccentText.words(text)
        guard !words.isEmpty else { return "" }
        return AccentText.join(try stress.apply(omographs.apply(yo.apply(words, sentence: text))), gaps)
    }
}
