#if canImport(UIKit)
import SwiftUI
import UIKit

/// Embed using normal UIViewController containment, then constrain `view` to your layout.
@MainActor
public final class AppAdViewController: UIHostingController<AppAdView> {
    public init(configuration: AppAdConfiguration? = nil,
                currentAppID: String? = Bundle.main.bundleIdentifier,
                title: String? = nil, actionTitle: String? = nil,
                locale: Locale? = nil,
                onTap: ((AppAdItem) -> Void)? = nil) {
        super.init(rootView: AppAdView(configuration: configuration, currentAppID: currentAppID,
                                      title: title, actionTitle: actionTitle, locale: locale, onTap: onTap))
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("Use init(configuration:)") }
}
#endif
