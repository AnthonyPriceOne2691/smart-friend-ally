@testable import AllyCore
import XCTest

/// P1: the Swift port of Snowball's Russian stemmer gives the reference's stems — the spec's words, a sample of 100
/// pairs of Snowball's own vocabulary (BSD) in CI, the whole vocabulary on the Mac.
final class StemmerTests: XCTestCase {
    private let repo = URL(fileURLWithPath: #filePath).appendingPathComponent("../../../../..").standardized

    /// `local/` of the main clone: a worktree's `.git` is a file naming `<main>/.git/worktrees/<name>`.
    private var local: URL {
        let gitFile = (try? String(contentsOf: repo.appendingPathComponent(".git"), encoding: .utf8)) ?? ""
        guard let range = gitFile.range(of: "/.git/worktrees/"), gitFile.hasPrefix("gitdir: ") else {
            return repo.appendingPathComponent("local")
        }
        return URL(fileURLWithPath: String(gitFile[gitFile.index(gitFile.startIndex, offsetBy: 8)..<range.lowerBound]))
            .appendingPathComponent("local")
    }

    func testSpecWords() { // P1
        let words = ["облака", "зеркало", "зеркале", "лисичка", "бежали", "потеем", "ржавеет", "колючий", "мурлычет",
                     "мурлычут"]
        let stems = ["облак", "зерка", "зеркал", "лисичк", "бежа", "поте", "ржавеет", "колюч", "мурлычет", "мурлычут"]
        XCTAssertEqual(words.map(RussianStemmer.stem), stems)
    }

    func testSnowballSample() { // P1
        let pairs = sample.split(whereSeparator: \.isWhitespace).map { $0.split(separator: ">").map(String.init) }
        XCTAssertEqual(pairs.count, 100)
        for pair in pairs { XCTAssertEqual(RussianStemmer.stem(pair[0]), pair[1], pair[0]) }
    }

    func testWholeVocabulary() throws { // P1
        let folder = local.appendingPathComponent("spike/erudition/snowball")
        guard let voc = try? String(contentsOf: folder.appendingPathComponent("voc.txt"), encoding: .utf8),
              let out = try? String(contentsOf: folder.appendingPathComponent("output.txt"), encoding: .utf8) else {
            throw XCTSkip("P1 весь словарь пропущен: нет local/spike/erudition/snowball — проверена выборка из 100 пар")
        }
        let words = voc.split(separator: "\n"), stems = out.split(separator: "\n")
        XCTAssertEqual(words.count, 49_785)
        let wrong = zip(words, stems).filter { word, stem in
            RussianStemmer.stem(word.replacingOccurrences(of: "ё", with: "е")) != stem
        }
        XCTAssertEqual(wrong.count, 0, "\(wrong.prefix(5))")
    }

    /// Every 497th pair of Snowball's russian/voc.txt → output.txt (snowballstem/snowball-data, BSD), «ё» as «е».
    private let sample = """
        а>а аханья>ахан безрассудным>безрассудн благодари>благодар большинством>большинств бушующих>буш
        венецейской>венецейск взор>взор внушения>внушен воплями>вопл всеобщее>всеобщ выгнать>выгна
        высвободив>высвобод германские>германск гордый>горд грохнулся>грохнул дворян>дворя дичи>дич доносилась>донос
        дрянцо>дрянц жалок>жалок заблестят>заблест задумавшись>задума замерзнуть>замерзнут заработал>заработа
        зачислен>зачисл зноем>зно изломан>излома искусственной>искусствен камином>камин клен>клен контролем>контрол
        кренделями>крендел кухарками>кухарк ливингстона>ливингстон любезные>любезн машу>маш милость>милост
        морщась>морщ наверчено>наверч наливала>налива настаивала>настаива невозвратимый>невозвратим
        немедленным>немедлен нервной>нервн ниточке>ниточк обеспокоенная>обеспокоен образцовая>образцов огорчен>огорч
        ольхи>ольх ослепления>ослеплен отговорил>отговор отправишь>отправ очистительных>очистительн
        первоначальное>первоначальн переходит>переход пленительные>пленительн поглотила>поглот подобрался>подобра
        позднейшее>поздн полицейскому>полицейск помрачен>помрач посекут>посекут потрафил>потраф праздничный>праздничн
        препятствовала>препятствова прижалась>прижа приподняться>приподня проводим>провод пронзительных>пронзительн
        прохладный>прохладн пучат>пучат разгадка>разгадк разузнать>разузна рассуждение>рассужден рисуюсь>рис
        рыжие>рыж свету>свет сенным>сен скверное>скверн слетит>слет смутился>смут созданием>создан
        сохранившихся>сохран ссориться>ссор стоят>сто суматохой>суматох тактом>такт тишь>тиш трезво>трезв
        тянулось>тянул удержали>удержа умеешь>умееш ускользнуть>ускользнут ученику>ученик харламова>харламов
        царский>царск честное>честн шевелиться>шевел электрическую>электрическ
        """
}
