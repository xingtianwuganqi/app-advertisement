import SwiftUI

/// Displays all enabled apps except the host, in JSON order.
/// Embed in a ScrollView for scrolling, or directly in an existing scrolling container.
/// No eligible apps means no content, including no section title.
public struct AppAdListView: View {
    private let configuration: AppAdConfiguration?
    private let currentAppID: String?
    private let title: String?
    private let actionTitle: String?
    private let localeOverride: Locale?
    private let onTap: ((AppAdItem) -> Void)?
    @Environment(\.locale) private var environmentLocale
    private var locale: Locale { localeOverride ?? environmentLocale }
    private var apps: [AppAdItem] {
        configuration?.eligibleApps(excluding: currentAppID) ?? []
    }

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
        let eligibleApps = apps
        if !eligibleApps.isEmpty {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text(title ?? AppAdLocalization.string("ad.title", locale: locale))
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                ForEach(eligibleApps) { app in
                    AppAdCard(app: app, title: nil, actionTitle: actionTitle,
                              locale: locale, onTap: onTap)
                }
            }
        }
    }
}
