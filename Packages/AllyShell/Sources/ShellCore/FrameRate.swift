import AllyCore
import Foundation

/// How hot the phone is (the platform's thermal state; `ProcessInfo.thermalState` is not on Linux, so the core keeps
/// its own four steps and `ShellUI` translates).
public enum Heat: Sendable {
    case nominal, fair, serious, critical
}

/// Frames per second by pose (the parent's answer 5, 2026-10-22): listening — up to 120, speaking — 60, thinking — 30
/// (the model holds the GPU then), asleep — 30; a serious heat caps it at 30, a critical one at 15. Reduce Motion
/// changes the swing, not the rate.
public enum FrameRate {
    public static func perSecond(_ pose: TalkState.Pose, heat: Heat) -> Double {
        let rate: Double = switch pose {
        case .sleeps, .thinks: 30
        case .listens: 120
        case .speaks: 60
        }
        switch heat {
        case .nominal, .fair: return rate
        case .serious: return min(rate, 30)
        case .critical: return 15
        }
    }
}
