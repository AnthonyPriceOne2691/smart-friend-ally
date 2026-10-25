@testable import AllyCore
import XCTest

/// Pairs of one-word references: dictation misses `missed` of `count`, GigaAM none.
private func oneWord(_ count: Int, missed: Int) -> [StepThree.Pair] {
    (0..<count).map { StepThree.Pair(ref: "кот", dictation: $0 < missed ? "кит" : "кот", gigaam: "кот") }
}

/// A reference of `words` words where GigaAM misses `missed` and dictation none.
private func long(_ words: Int, gigaamMissed missed: Int) -> StepThree.Pair {
    let ref = Array(repeating: "мурка", count: words)
    let heard = ref.enumerated().map { $0.offset < missed ? "тёма" : $0.element }
    return StepThree.Pair(ref: ref.joined(separator: " "), dictation: ref.joined(separator: " "),
                          gigaam: heard.joined(separator: " "))
}

/// References of two words but the last of `last` words; dictation misses `dictation` words, GigaAM `gigaam`.
private func wer(_ count: Int, last: Int, dictation: Int, gigaam: Int) -> [StepThree.Pair] {
    let sizes = Array(repeating: 2, count: count - 1) + [last]
    let refs = sizes.map { Array(repeating: "соня", count: $0) }
    let miss = { (text: [String], count: Int, from: Int) -> String in
        text.enumerated().map { $0.offset >= from && $0.offset < from + count ? "тёма" : $0.element }
            .joined(separator: " ")
    }
    return refs.enumerated().map { index, words in
        StepThree.Pair(ref: words.joined(separator: " "),
                       dictation: miss(words, max(0, min(2, dictation - index * 2)), 0),
                       gigaam: miss(words, max(0, min(2, gigaam - index * 2)), 0))
    }
}

final class StepThreeTests: XCTestCase {
    func testTheReferenceAndBothHypothesesAreNormalizedAlike() {  // U27
        XCTAssertEqual(StepThree.normalize("Ёжик, 5 котят! 21 и 101-й; 100%"),
                       ["ежик", "пять", "котят", "двадцать", "один", "и", "101", "й", "сто"])
        XCTAssertEqual(StepThree.normalize("Мурка  спит."), StepThree.normalize("мурка спит"))
        XCTAssertEqual([StepThree.normalize("0"), StepThree.normalize("40"), StepThree.normalize("99")],
                       [["ноль"], ["сорок"], ["девяносто", "девять"]])
    }

    func testWerOneWordAndEmptyAnswersOfBoth() {  // U27
        let summary = StepThree.summary([
            .init(ref: "Мурка спит", dictation: "мурка не спит", gigaam: "мурка спит"),
            .init(ref: "Тёма", dictation: "тема", gigaam: ""),
            .init(ref: "да", dictation: "два", gigaam: "да"),
            .init(ref: "Соня рисует 3 кошки", dictation: "соня рисует три кошки", gigaam: "соня рисует кошки")
        ])
        XCTAssertEqual([summary.count, summary.oneWord, summary.exactDictation, summary.exactGigaAM], [4, 2, 1, 1])
        XCTAssertEqual([summary.emptyDictation, summary.emptyGigaAM], [0, 1])
        XCTAssertEqual([summary.werDictation, summary.werGigaAM, summary.gain], [25, 25, 0])
        XCTAssertFalse(summary.gigaamWins)
    }

    func testTheBootstrapIntervalIsRepeatableAndHoldsTheGain() {  // U27
        let pairs = oneWord(20, missed: 6) + [long(10, gigaamMissed: 1)]
        let summary = StepThree.summary(pairs)
        XCTAssertEqual(summary, StepThree.summary(pairs))
        XCTAssertLessThanOrEqual(summary.low, summary.gain)
        XCTAssertGreaterThanOrEqual(summary.high, summary.gain)
        XCTAssertLessThan(summary.low, summary.high)
        let bounds = StepThree.interval((0..<2000).map(Double.init))
        XCTAssertEqual([bounds.low, bounds.high], [50, 1949])
        let same = StepThree.summary(oneWord(10, missed: 0))
        XCTAssertEqual([same.low, same.gain, same.high], [0, 0, 0])
    }

    func testEitherPartOfTheRuleAtThreePoints() {  // U27
        let atWer = StepThree.summary(wer(5, last: 2, dictation: 2, gigaam: 1))
        XCTAssertEqual(atWer.gain, 10, accuracy: 1e-9)
        XCTAssertTrue(atWer.gigaamWins)
        let belowWer = StepThree.summary(wer(5, last: 3, dictation: 2, gigaam: 1))
        XCTAssertEqual(belowWer.gain, 100.0 / 11, accuracy: 1e-9)
        XCTAssertFalse(belowWer.gigaamWins)
        XCTAssertTrue(StepThree.summary(wer(5, last: 2, dictation: 3, gigaam: 1)).gigaamWins)
        let atWord = StepThree.summary(oneWord(20, missed: 2) + [long(20, gigaamMissed: 2)])
        XCTAssertEqual([atWord.gain, atWord.oneWordGain], [0, 10])
        XCTAssertTrue(atWord.gigaamWins)
        let belowWord = StepThree.summary(oneWord(20, missed: 1) + [long(20, gigaamMissed: 1)])
        XCTAssertEqual([belowWord.gain, belowWord.oneWordGain], [0, 5])
        XCTAssertFalse(belowWord.gigaamWins)
        XCTAssertTrue(StepThree.summary(oneWord(20, missed: 3) + [long(20, gigaamMissed: 3)]).gigaamWins)
    }

    func testTheLinesAreSumsOnly() {  // U27
        let pairs: [StepThree.Pair] = [
            .init(ref: "Мурка гуляет возле улицы Морковной", dictation: "мурка гуляла",
                  gigaam: "мурка гуляет возле улицы"),
            .init(ref: "Тёма", dictation: "", gigaam: "тёма")
        ]
        let lines = StepThree.lines(StepThree.summary(pairs), skipped: .init(noRef: 3, noAudio: 1, live: 2),
                                    models: ["GigaAM gigaam-v3-ctc:224757733", "диктовка iOS 27.0"])
        XCTAssertEqual(lines.count, 6)
        XCTAssertEqual(lines.first, "шаг 3: реплик 2; пропущено — без эталона 3, без звука 1, с живым GigaAM 2")
        XCTAssertEqual(lines.last, "вердикт: GigaAM основным (≥ 10 п.п. по WER или по однословным)")
        let words = pairs.flatMap { StepThree.normalize($0.ref + " " + $0.dictation + " " + $0.gigaam) }
        XCTAssertEqual(words.filter { word in lines.contains { $0.lowercased().contains(word) } }, [])
    }
}
