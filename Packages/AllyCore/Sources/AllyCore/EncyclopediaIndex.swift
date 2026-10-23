import AllySQLite

/// The cards as an FTS5 table in memory — no file anywhere: stems of the first phrasing, of the other phrasings and of
/// the answer. A query is OR of stems ranked by `bm25` with the config's field weights; the boost of the first phrasing
/// is ours: score × (1 + boost × share of its stems in the query). Ties go by card order. One connection, one caller
/// at a time — the owner holds it under a lock.
final class EncyclopediaIndex {
    struct Document { let title: [String], alias: [String], body: [String] }

    private let connection: SQLiteConnection, titles: [Set<String>], config: EncyclopediaConfig

    init(_ documents: [Document], config: EncyclopediaConfig) throws {
        connection = try SQLiteConnection(path: ":memory:")
        titles = documents.map { Set($0.title) }
        self.config = config
        try connection.exec("CREATE VIRTUAL TABLE cards USING fts5(title, alias, body, tokenize='\(config.tokenizer)', "
                            + "content='', detail=full)")
        try connection.transaction {
            for (index, document) in documents.enumerated() {
                try connection.run("INSERT INTO cards(rowid, title, alias, body) VALUES (?, ?, ?, ?)", [
                    .int(Int64(index + 1)), .text(document.title.joined(separator: " ")),
                    .text(document.alias.joined(separator: " ")), .text(document.body.joined(separator: " "))
                ])
            }
        }
    }

    /// The best cards for the stems, by boosted score; nothing for no stems.
    func ranked(_ terms: [String]) throws -> [(index: Int, score: Double)] {
        guard !terms.isEmpty else { return [] }
        let match = terms.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
            .joined(separator: " OR ")
        let weights = config.fieldWeights.map { String($0) }.joined(separator: ", ")
        let rows = try connection.rows("SELECT rowid, bm25(cards, \(weights)) FROM cards WHERE cards MATCH ? "
                                       + "ORDER BY 2 LIMIT \(config.limit)", [.text(match)])
        let query = Set(terms)
        return rows.compactMap { row -> (index: Int, score: Double)? in
            guard row.count == 2, let rowid = row[0].int, let score = row[1].real else { return nil }
            let title = titles[Int(rowid) - 1]
            let share = Double(title.intersection(query).count) / Double(max(1, title.count))
            return (Int(rowid) - 1, -score * (1 + config.boost * share))
        }
        .sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
    }
}
