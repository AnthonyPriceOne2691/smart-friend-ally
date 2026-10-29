import ShellUI
import SwiftUI

/// The loading screen (child-open, J1; the parent 2026-10-29: «экран загрузки, красивый такой какой-нибудь штучкой,
/// написать загрузка, и все. А потом раз и появляется Элли»): the pink sky, Ellie's empty bubble floating with little
/// bubbles rising in it, and «Загрузка» in plum on a white plate inside glass — the word is his, for the grown-up who
/// holds the phone. A real loading, not a splash (screen rule 14): its length goes to the console. No buttons.
struct LoadingScreen: View {
    var body: some View {
        AdultSky {
            VStack(spacing: Look.loadingGap) {
                LoadingBubble().frame(width: Look.loadingBubble, height: Look.loadingBubble)
                Text("Загрузка").font(Look.loadingFont)
                    .padding(.horizontal, Look.loadingPadding).frame(height: Look.loadingHeight)
                    .background(Capsule().fill(Look.plate))  // the word on an opaque plate, the glass round it (L137)
                    .padding(Look.ring)
                    .background { Capsule().fill(.clear).glassEffect(.regular.tint(Look.zoneTint), in: .capsule) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityIdentifier("loading")
    }
}
