import SwiftUI

/// Ally Demo (design-demo): the look of the app in the simulator on a made-up session — the child screen walks through
/// the session's phases by itself, the console is the app's own view. No model, no microphone, no voice, no memory;
/// none of it is in the app on the phone (`scripts/lint/check_demo_boundary.sh`).
@main
struct AllyDemoApp: App {
    var body: some Scene {
        WindowGroup { DemoRoot() }
    }
}
