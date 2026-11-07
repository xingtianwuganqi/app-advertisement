import SwiftUI

/// Chooses an ad once per view identity. Change `id` to request a new selection.
/// Empty configurations render no content. No tracking or remote configuration is performed.
public struct AppAdView: View {
    private let configuration: AppAdConfiguration?
    private let currentAppID: String?
    private let title: String?
    private let actionTitle: String?
    private let localeOverride: Locale?
    @Environment(\.locale) private var environmentLocale
    private var locale: Locale { localeOverride ?? environmentLocale }
    private let onTap: ((AppAdItem) -> Void)?
    @State private var selectedApp: AppAdItem?

    public init(configuration: AppAdConfiguration? = nil,
                currentAppID: String? = Bundle.main.bundleIdentifier,
                title: String? = nil, actionTitle: String? = nil,
                locale: Locale? = nil,
                onTap: ((AppAdItem) -> Void)? = nil) {
        self.configuration = configuration ?? AppAdConfiguration.bundledDefault
        self.currentAppID = currentAppID
        self.title = title
        self.actionTitle = actionTitle
        self.localeOverride = locale
        self.onTap = onTap
    }

    public var body: some View {
        Group {
            if let app = selectedApp {
                AppAdCard(app: app,
                          title: title ?? AppAdLocalization.string("ad.title", locale: locale),
                          actionTitle: actionTitle, locale: locale, onTap: onTap)
            }
        }
        .onAppear(perform: selectApp)
        .onChange(of: configuration) { _ in selectApp() }
        .onChange(of: currentAppID) { _ in selectApp() }
    }

    private func selectApp() {
        if let selectedApp,
           configuration?.eligibleApps(excluding: currentAppID).contains(selectedApp) == true { return }
        selectedApp = configuration?.randomApp(excluding: currentAppID)
    }
}
