import AllyCore
import XCTest

final class TurnKindTests: XCTestCase {
    func testTheKindOfHerTurnIsReadFromEllysLastTurn() {  // U1
        let cases: [([String], TurnKind)] = [
            (["Привет!", "Это я, Элли.", "Что у тебя нового?"], .open),
            (["Ух ты, в зоопарке!", "А кого ты там видела?"], .open),
            (["Почему небо голубое, как ты думаешь?"], .open),
            (["Расскажи, что было дальше!"], .open),
            (["Ух ты, в зоопарке!"], .open),
            (["Хочешь, расскажу про жирафа?"], .closed),
            (["Ты любишь мороженое?"], .closed),
            (["Я люблю клубнику.", "А ты?"], .closed),
            (["Сказку или загадку?"], .closed),
            (["Кто это — кошка или собака?"], .closed),
            (["Сколько лапок у кошки?"], .closed),
            (["Давай посчитаем до пяти!"], .counting),
            (["Посчитай, сколько у тебя пальчиков."], .counting),
            (["Здорово!", "Давай посчитаем вместе.", "Начинай!"], .counting),
            (["О ЧЁМ ТЫ ДУМАЕШЬ?"], .open)
        ]
        for (sentences, kind) in cases {
            XCTAssertEqual(TurnKinds.shared.kind(after: sentences), kind, sentences.joined(separator: " "))
        }
    }
}
