import Foundation

enum AppConfig {
    static func value(for key: String) -> String? {
        if let fromEnvironment = ProcessInfo.processInfo.environment[key] {
            let sanitized = sanitize(fromEnvironment)
            if !sanitized.isEmpty {
                return sanitized
            }
        }

        guard let fromInfo = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let sanitized = sanitize(fromInfo)
        return sanitized.isEmpty ? nil : sanitized
    }

    static func isUnresolvedBuildSetting(_ value: String) -> Bool {
        value.contains("$(") || value.contains("${")
    }

    private static func sanitize(_ rawValue: String) -> String {
        rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
