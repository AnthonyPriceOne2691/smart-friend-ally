/// Вход модели RUAccent — то, что отдаёт токенизатор HF: id (в ONNX — int64), строки токенов (как
/// `convert_ids_to_tokens`), type ids, маска служебных и смещения в скалярах Unicode исходной строки — как индексы
/// `str` в Python (`sentence[start:end]`); у служебных — `0..<0`, у BPE смещений нет: логика омографов их не просит.
/// Одно `Encoding` — один вход без паддинга, поэтому маска внимания — единицы.
public struct Encoding: Equatable, Sendable {
    public var ids: [Int]
    public var tokens: [String]
    public var typeIds: [Int]
    public var specialTokensMask: [Bool]
    public var offsets: [Range<Int>]

    public var attentionMask: [Int] { Array(repeating: 1, count: ids.count) }

    public init(ids: [Int] = [], tokens: [String] = [], typeIds: [Int] = [], specialTokensMask: [Bool] = [],
                offsets: [Range<Int>] = []) {
        (self.ids, self.tokens, self.typeIds) = (ids, tokens, typeIds)
        (self.specialTokensMask, self.offsets) = (specialTokensMask, offsets)
    }

    /// Токен в конец; `offset` — `nil` у токенизатора без смещений (BPE).
    mutating func append(_ token: String, id: Int, offset: Range<Int>? = 0..<0, special: Bool = false, type: Int = 0) {
        ids.append(id)
        tokens.append(token)
        typeIds.append(type)
        specialTokensMask.append(special)
        if let offset { offsets.append(offset) }
    }
}
