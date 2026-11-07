#if canImport(UIKit)
import SwiftUI
import UIKit

/// A scrollable app list that can be pushed, presented, or embedded using containment.
@MainActor
public final class AppAdListViewController: UIHostingController<ScrollView<AppAdListView>> {
    public init(configuration: AppAdConfiguration? = nil,
                currentAppID: String? = Bundle.main.bundleIdentifier,
                title: String? = nil, actionTitle: String? = nil,
                locale: Locale? = nil,
                onTap: ((AppAdItem) -> Void)? = nil) {
        let list = AppAdListView(configuration: configuration, currentAppID: currentAppID,
                                 title: title, actionTitle: actionTitle, locale: locale, onTap: onTap)
        super.init(rootView: ScrollView { list })
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("Use init(configuration:)") }
}
#endif
