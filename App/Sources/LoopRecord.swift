import AllyLlama
import Foundation
import os

/// The record's and the console's small helpers, out of the loop's file (its limit is 500 lines).
extension VoiceLoop {
    /// What the iOS memory limit counts (L22): footprint now and its lifetime peak, headroom left; conversation tokens.
    nonisolated static func memory(_ model: LlamaModel) -> [String: Int] {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        let base = ["available_mb": os_proc_available_memory() >> 20, "context_tokens": model.promptTokens]
        guard status == KERN_SUCCESS else { return base }
        return base.merging(["footprint_mb": Int(info.phys_footprint >> 20),
                             "footprint_peak_mb": Int(info.ledger_phys_footprint_peak >> 20)]) { $1 }
    }

    var uptime: Double { ProcessInfo.processInfo.systemUptime }

    func line(_ stages: [String: Double]) -> String {
        stages.sorted { $0.key < $1.key }.map { "\($0.key) " + String(format: "%.2f с", $0.value) }
            .joined(separator: " · ")
    }
}
