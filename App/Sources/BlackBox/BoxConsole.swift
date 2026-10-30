import AllyCore
import os

/// The black box on the console (D3.2): its line and, when the line changes, the journal — counts only, words never
/// (B13, L46): the child screen covers the console while the box writes, so `devicectl … --console` is where it shows.
extension VoiceLoop {
    private static let boxLog = Logger(subsystem: "com.anthonypriceone.ally", category: "blackbox")

    /// The folder's mark and class as read back, once at the warm-up (B13): the console's line, the journal's too.
    func noteBox(_ disk: PhoneDisk) -> String {
        Self.boxLog.info("ящик: \(disk.note, privacy: .public)")
        refreshBox()
        return "ящик: " + disk.note
    }

    /// The child session's states: the child screen shows them while it is up, the box's line follows them past it —
    /// the stop sign leaves the screen before she sleeps. One reader: `updates` is a single stream.
    func follow(_ talker: Conversation) {
        Task {
            for await state in talker.updates {
                if child { show(state) }
                refreshBox()
            }
        }
    }

    func refreshBox() {
        guard let line = box?.status, line != boxLine else { return }
        boxLine = line
        Self.boxLog.info("blackbox: \(line, privacy: .public)")
    }

    /// What the box holds, for the console's question before «erase all».
    func boxHeld() -> (sessions: Int, bytes: Int)? { try? box?.held() }

    /// «Стереть чёрный ящик» after the parent's yes — only while she sleeps; the line then says what went (B17).
    func eraseBox() {
        guard let box, talk.phase == .asleep else { return }
        do {
            _ = try box.eraseAll()
            refreshBox()
        } catch {
            boxLine = "ящик не стёрт: \(error)"
        }
    }
}
