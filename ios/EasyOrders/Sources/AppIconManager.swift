import UIKit

@MainActor
final class AppIconManager {
    static let shared = AppIconManager()

    private let preferredAlternateIconName = "AppIconAlternate"

    private init() {}

    func applyPreferredIconIfNeeded() async {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        guard UIApplication.shared.alternateIconName != preferredAlternateIconName else { return }

        do {
            try await UIApplication.shared.setAlternateIconName(preferredAlternateIconName)
        } catch {
            #if DEBUG
            print("Failed to apply alternate app icon: \(error.localizedDescription)")
            #endif
        }
    }
}
