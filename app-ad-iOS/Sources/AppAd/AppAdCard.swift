import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Shared presentation and link behavior for random and list advertisements.
struct AppAdCard: View {
    let app: AppAdItem
    let title: String?
    let actionTitle: String?
    let locale: Locale
    let onTap: ((AppAdItem) -> Void)?
    @Environment(\.openURL) private var openURL
    private var contentLocale: Locale { AppAdLocalization.contentLocale(for: locale) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Button {
                onTap?(app)
                openURL(app.appStoreURL)
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    AppAdIcon(app: app)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(app.localizedName(locale: contentLocale)).font(.headline).foregroundStyle(.primary)
                        Text(app.localizedDescription(locale: contentLocale)).font(.subheadline).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Text(actionTitle ?? AppAdLocalization.string("ad.action", locale: locale)).font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(AppAdLocalization.string("ad.hint", locale: locale)))
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct AppAdIcon: View {
    let app: AppAdItem

    var body: some View {
        if let image = localImage {
            image.resizable().scaledToFill()
        } else if let url = app.iconURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else { placeholder }
            }
        } else { placeholder }
    }

    private var localImage: Image? {
        guard let url = app.bundledIconURL else { return nil }
        #if canImport(UIKit)
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }

    private var placeholder: some View {
        ZStack {
            Color.accentColor.opacity(0.12)
            Image(systemName: "app.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.accentColor)
        }
    }
}
