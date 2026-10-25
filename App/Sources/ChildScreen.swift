import AllyCore
import ShellUI
import SwiftUI

/// The child screen: the shell (Ш3) on the interface R gave it — Ellie in her bubble with the crown. A tap on the
/// bubble wakes her or ends her utterance (`onWake`: the lock, the break and «я всё» are R's and D7's), the parent's
/// stop sign and the label of the term sit in the corner. No words for the girl (screen rule 1).
struct ChildScreen: View {
    let talk: TalkState, until: Date?, onWake: () -> Void, onStop: () -> Void

    var body: some View {
        ChildShell(talk: talk, until: until, onTap: onWake, onStop: onStop)
    }
}
