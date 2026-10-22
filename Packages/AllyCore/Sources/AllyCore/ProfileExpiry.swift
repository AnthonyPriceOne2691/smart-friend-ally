import Foundation

/// How long the app still runs (E4: the free Personal Team signs for 7 days): `ExpirationDate` of the plist inside the
/// CMS-signed `embedded.mobileprovision`.
public enum ProfileExpiry {
    public static func expiration(_ profile: Data) -> Date? {
        guard let open = profile.range(of: Data("<?xml".utf8)),
              let close = profile.range(of: Data("</plist>".utf8), in: open.lowerBound..<profile.endIndex),
              let plist = try? PropertyListSerialization.propertyList(
                from: profile.subdata(in: open.lowerBound..<close.upperBound), options: [], format: nil)
        else { return nil }
        return (plist as? [String: Any])?["ExpirationDate"] as? Date
    }

    /// Whole days left, rounded down; nil when the profile or its date is unknown.
    public static func daysLeft(_ profile: Data?, now: Date) -> Int? {
        guard let profile, let end = expiration(profile) else { return nil }
        return Int((end.timeIntervalSince(now) / 86_400).rounded(.down))
    }

    /// The console line.
    public static func line(daysLeft: Int?) -> String {
        daysLeft.map { "подпись: осталось \(max($0, 0)) дн." } ?? "срок подписи неизвестен"
    }
}
