import Foundation

/// The repository of the tests and its `local/` with the data outside git: a worktree's `.git` is a file naming a
/// gitdir inside the main clone's `.git/worktrees`, and the main clone keeps `local/`.
let repo = URL(fileURLWithPath: #filePath).appendingPathComponent("../../../../..").standardized
let localData: URL = {
    let git = (try? String(contentsOf: repo.appendingPathComponent(".git"), encoding: .utf8)) ?? ""
    guard git.hasPrefix("gitdir: ") else { return repo.appendingPathComponent("local") }
    let gitdir = URL(fileURLWithPath: git.dropFirst(8).trimmingCharacters(in: .whitespacesAndNewlines))
    return gitdir.appendingPathComponent("../../../local").standardized
}()
