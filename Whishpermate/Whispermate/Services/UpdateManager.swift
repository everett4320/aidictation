import AppKit
import Foundation
internal import Combine

#if canImport(Sparkle)
import Sparkle
#endif

/// Handles in-app update checks via Sparkle and falls back to the release page when Sparkle is unavailable.
@MainActor
final class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()

    @Published private(set) var versionDisplay: String = AppVersion.current.displayString
    @Published private(set) var isInAppUpdatesEnabled = false

    #if canImport(Sparkle)
    private var updaterController: SPUStandardUpdaterController?
    #endif

    private enum Constants {
        static let feedURLInfoKey = "SUFeedURL"
        static let latestReleaseURL = "https://github.com/writingmate/aidictation/releases/latest"
    }

    private override init() {
        super.init()
        configureSparkle()
    }

    func checkForUpdates() {
        #if canImport(Sparkle)
        if let updaterController {
            updaterController.checkForUpdates(nil)
            return
        }
        #endif
        openLatestReleasePage()
    }

    private func configureSparkle() {
        #if canImport(Sparkle)
        guard let feedURL = Bundle.main.object(forInfoDictionaryKey: Constants.feedURLInfoKey) as? String,
              !feedURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DebugLog.info("Sparkle disabled: missing SUFeedURL. Falling back to release page.", context: "UpdateManager")
            isInAppUpdatesEnabled = false
            return
        }

        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        isInAppUpdatesEnabled = true
        DebugLog.info("Sparkle updater initialized with feed URL: \(feedURL)", context: "UpdateManager")
        #else
        DebugLog.info("Sparkle framework is not linked. Falling back to release page.", context: "UpdateManager")
        isInAppUpdatesEnabled = false
        #endif
    }

    private func openLatestReleasePage() {
        guard let url = URL(string: Constants.latestReleaseURL) else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct AppVersion {
    let shortVersion: String
    let buildNumber: String

    var displayString: String {
        "\(shortVersion) (\(buildNumber))"
    }

    static var current: AppVersion {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return AppVersion(shortVersion: shortVersion, buildNumber: buildNumber)
    }
}
