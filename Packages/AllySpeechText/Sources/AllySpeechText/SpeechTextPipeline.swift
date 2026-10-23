/// Фраза для голоса. `shown` — фраза как есть: экран, `said` чёрного ящика, журнал; `engine` — только вход движка;
/// `trace` — след шага для журнала хода, без слов (Z13).
public struct SpeechText: Sendable, Equatable {
    public let shown: String
    public let engine: String
    public let trace: SpeechTextTrace
}

/// След шага текста: только счётчики — ни одного слова фразы.
public struct SpeechTextTrace: Sendable, Equatable, Codable {
    /// Слов со знаком ударения.
    public var marks = 0
    /// Слов из закреплённого словаря и записей имён.
    public var pinned = 0
    /// Слов, переписанных правилами чтения.
    public var respelled = 0
}

/// Текст для синтеза: (1) ударения по исходному написанию, (2) закреплённое и имена поверх, (3) правила чтения с
/// переносом ударения по номеру гласной, (4) знак U+0301 на словах от двух слогов, кроме слов с «ё». До V4 вызывающего
/// в приложении нет (L50).
public struct SpeechTextPipeline: Sendable {
    let placer: any StressPlacer
    let table: SpeechTextTable

    public init(placer: any StressPlacer, table: SpeechTextTable) {
        self.placer = placer
        self.table = table
    }

    /// Отказ расстановщика пробрасывается: что звучит без ударений, решает приложение (V4).
    public func prepare(_ phrase: String) throws -> SpeechText {
        let placed = try placer.place(phrase)
        var trace = SpeechTextTrace()
        // Слово ответа — серия кириллических букв, перед буквой может стоять «+»; остальное идёт в движок как есть.
        let engine = placed.replacing(#/(?:\+?[а-яА-ЯёЁ])+/#) { match -> String in
            let step = table.respell(SpokenWord(plus: String(match.output)))
            let marked = step.word.marked
            trace.marks += marked == step.word.letters ? 0 : 1
            trace.pinned += step.pinned ? 1 : 0
            trace.respelled += step.respelled ? 1 : 0
            return marked
        }
        return SpeechText(shown: phrase, engine: engine, trace: trace)
    }
}
