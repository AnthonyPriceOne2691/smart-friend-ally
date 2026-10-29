import AllyCore
import ShellUI
import SwiftUI

/// The child screen: the shell (Ш3) — Ellie in her bubble with the crown, open always (child-open, the parent
/// 2026-10-29: «Детский экран открыт всегда»). A tap on the bubble wakes her or ends her utterance (`onWake`: the break
/// and «я всё» are Ш3's and D7's); the parent's stop sign sits in the corner, no label. No words for the girl (screen
/// rule 1).
struct ChildScreen: View {
    let talk: TalkState, onWake: () -> Void, onStop: () -> Void

    var body: some View {
        ChildShell(talk: talk, until: nil, onTap: onWake, onStop: onStop)
    }
}
