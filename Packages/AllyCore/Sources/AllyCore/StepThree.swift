import Foundation

/// Step 3 of the recognizer choice (D7.4): dictation's live text against GigaAM on her recordings, judged by the
/// parent's references. GigaAM becomes the main recognizer if it is better by ≥ 10 p.p. in WER or in exact one-word
/// answers. Only sums leave it — no reference and no hypothesis is ever in its lines.
public enum StepThree {
    /// One utterance: the parent's reference, dictation's live `heard`, GigaAM's text of the same sound.
    public struct Pair: Sendable {
        public let ref: String, dictation: String, gigaam: String

        public init(ref: String, dictation: String, gigaam: String) {
            (self.ref, self.dictation, self.gigaam) = (ref, dictation, gigaam)
        }
    }

    /// Utterances left out, by reason: no reference, no sound, heard by the live GigaAM.
    public struct Skipped: Equatable, Sendable {
        public let noRef: Int, noAudio: Int, live: Int

        public init(noRef: Int = 0, noAudio: Int = 0, live: Int = 0) {
            (self.noRef, self.noAudio, self.live) = (noRef, noAudio, live)
        }
    }

    /// The sums: WER in percent; gains are dictation's minus GigaAM's errors in p.p. — positive is GigaAM better.
    public struct Summary: Equatable, Sendable {
        public let count: Int, werDictation: Double, werGigaAM: Double, gain: Double, low: Double, high: Double
        public let oneWord: Int, exactDictation: Int, exactGigaAM: Int, emptyDictation: Int, emptyGigaAM: Int

        /// Exact one-word answers, GigaAM's share minus dictation's, p.p.; 0 without one-word references.
        public var oneWordGain: Double {
            oneWord == 0 ? 0 : Double(exactGigaAM - exactDictation) * 100 / Double(oneWord)
        }

        /// Either part of the rule: ≥ 10 p.p. in WER or in exact one-word answers.
        public var gigaamWins: Bool { gain >= 10 - 1e-9 || oneWordGain >= 10 - 1e-9 }
    }

    /// Lower case, «ё» as «е», every sign a space, numbers 0–100 as words — the reference and both hypotheses alike.
    public static func normalize(_ text: String) -> [String] {
        let spaced = String(text.lowercased().replacingOccurrences(of: "ё", with: "е").map {
            $0.isLetter || $0.isNumber ? $0 : " "
        })
        return spaced.split(separator: " ").flatMap { word -> [String] in
            guard let number = Int(word), (0...100).contains(number), word.allSatisfy(\.isASCII) else {
                return [String(word)]
            }
            return Texts.shared.words(number)
        }
    }

    /// Word edits from the reference to the hypothesis: substitutions, insertions, deletions.
    static func errors(_ ref: [String], _ hyp: [String]) -> Int {
        var row = Array(0...hyp.count)
        for (index, word) in ref.enumerated() {
            var next = [index + 1]
            for (column, other) in hyp.enumerated() {
                next.append(min(row[column] + (word == other ? 0 : 1), row[column + 1] + 1, next[column] + 1))
            }
            row = next
        }
        return row[hyp.count]
    }

    /// The sums of the pairs; the interval of the WER gain is a paired bootstrap over utterances with a fixed seed.
    public static func summary(_ pairs: [Pair], rounds: Int = 2000, seed: UInt64 = 2026) -> Summary {
        let refs = pairs.map { normalize($0.ref) }, dictation = pairs.map { normalize($0.dictation) }
        let gigaam = pairs.map { normalize($0.gigaam) }
        let words = refs.map(\.count), wrongD = zip(refs, dictation).map { errors($0, $1) }
        let wrongG = zip(refs, gigaam).map { errors($0, $1) }
        let wer = { (wrong: [Int], picks: [Int]) -> Double in
            let total = picks.reduce(0) { $0 + words[$1] }
            return total == 0 ? 0 : Double(picks.reduce(0) { $0 + wrong[$1] }) * 100 / Double(total)
        }
        let all = Array(pairs.indices)
        var random = SplitMix(state: seed)
        let gains = (0..<(pairs.isEmpty ? 0 : rounds)).map { _ -> Double in
            let picks = all.map { _ in Int(random.next() % UInt64(all.count)) }
            return wer(wrongD, picks) - wer(wrongG, picks)
        }.sorted()
        let single = refs.indices.filter { refs[$0].count == 1 }
        return Summary(count: pairs.count, werDictation: wer(wrongD, all), werGigaAM: wer(wrongG, all),
                       gain: wer(wrongD, all) - wer(wrongG, all), low: gains.isEmpty ? 0 : gains[rounds * 25 / 1000],
                       high: gains.isEmpty ? 0 : gains[max(0, rounds * 975 / 1000 - 1)], oneWord: single.count,
                       exactDictation: single.filter { dictation[$0] == refs[$0] }.count,
                       exactGigaAM: single.filter { gigaam[$0] == refs[$0] }.count,
                       emptyDictation: dictation.filter(\.isEmpty).count, emptyGigaAM: gigaam.filter(\.isEmpty).count)
    }

    /// The console lines: counts, WER with the interval, one-word answers, empty answers, the models, the verdict.
    public static func lines(_ summary: Summary, skipped: Skipped, models: [String]) -> [String] {
        let texts = Texts.shared, number = { (value: Double) in String(format: "%.1f", value) }
        return [
            fill(texts.count, ["n": "\(summary.count)", "no_ref": "\(skipped.noRef)",
                               "no_audio": "\(skipped.noAudio)", "live": "\(skipped.live)"]),
            fill(texts.wer, ["dictation": number(summary.werDictation), "gigaam": number(summary.werGigaAM),
                             "gain": number(summary.gain), "low": number(summary.low), "high": number(summary.high)]),
            fill(texts.oneWord, ["k": "\(summary.oneWord)", "dictation": "\(summary.exactDictation)",
                                 "gigaam": "\(summary.exactGigaAM)", "gain": number(summary.oneWordGain)]),
            fill(texts.empty, ["dictation": "\(summary.emptyDictation)", "gigaam": "\(summary.emptyGigaAM)"]),
            fill(texts.models, ["models": models.joined(separator: "; ")]),
            fill(texts.verdict, ["verdict": summary.gigaamWins ? texts.gigaam : texts.dictation])
        ]
    }

    private static func fill(_ template: String, _ values: [String: String]) -> String {
        values.reduce(template) { $0.replacingOccurrences(of: "{\($1.key)}", with: $1.value) }
    }

    /// `step3.json`: numbers as words and the console lines.
    struct Texts: Decodable, Sendable {
        let units: [String], tens: [String], count, wer, oneWord, empty, models, verdict, gigaam, dictation: String

        static let shared: Texts = {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let url = Bundle.module.url(forResource: "step3", withExtension: "json"),
                  let bytes = try? Data(contentsOf: url), let texts = try? decoder.decode(Texts.self, from: bytes)
            else { fatalError("AllyCore: step3.json is unreadable") }
            return texts
        }()

        /// 0–100 in words: «двадцать один» is two words, as a recognizer writes it.
        func words(_ number: Int) -> [String] {
            if number < 20 { return [units[number]] }
            return [tens[number / 10]] + (number % 10 == 0 ? [] : [units[number % 10]])
        }
    }

    /// SplitMix64: the same pairs give the same interval on every run.
    struct SplitMix {
        var state: UInt64

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var mixed = (state ^ (state >> 30)) &* 0xBF58_476D_1CE4_E5B9
            mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
            return mixed ^ (mixed >> 31)
        }
    }
}
