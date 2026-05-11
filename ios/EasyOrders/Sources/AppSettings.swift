import Foundation

struct AppSettings: Sendable {
    static let defaults = AppSettings(
        baseURLString: "https://notfi.wa-otp.com",
        appToken: "-QEoF0_MrdU9N1Aa3XSzKr6wBeG5ZUzU",
        notificationCount: 3,
        intervalSeconds: 10
    )

    enum Keys {
        static let baseURLString = "baseURLString"
        static let appToken = "appToken"
        static let notificationCount = "notificationCount"
        static let intervalSeconds = "intervalSeconds"
    }

    let baseURLString: String
    let appToken: String
    let notificationCount: Int
    let intervalSeconds: Int

    var normalizedBaseURL: URL? {
        let trimmed = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    func save() {
        let defaultsStore = UserDefaults.standard
        defaultsStore.set(baseURLString, forKey: Keys.baseURLString)
        defaultsStore.set(appToken, forKey: Keys.appToken)
        defaultsStore.set(notificationCount, forKey: Keys.notificationCount)
        defaultsStore.set(intervalSeconds, forKey: Keys.intervalSeconds)
    }

    static func load() -> AppSettings {
        let defaultsStore = UserDefaults.standard
        let storedBaseURL = (defaultsStore.string(forKey: Keys.baseURLString) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let storedToken = (defaultsStore.string(forKey: Keys.appToken) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let storedCount = defaultsStore.object(forKey: Keys.notificationCount) as? Int ?? defaults.notificationCount
        let storedInterval = defaultsStore.object(forKey: Keys.intervalSeconds) as? Int ?? defaults.intervalSeconds

        return AppSettings(
            baseURLString: storedBaseURL.isEmpty ? defaults.baseURLString : storedBaseURL,
            appToken: storedToken.isEmpty ? defaults.appToken : storedToken,
            notificationCount: min(max(storedCount, 1), 50),
            intervalSeconds: min(max(storedInterval, 1), 3600)
        )
    }
}
