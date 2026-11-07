import Foundation

/// Optional per-language overrides; missing fields fall back to the base record.
public struct AppAdTranslation: Codable, Equatable, Sendable {
    public let name: String?
    public let description: String?

    public init(name: String? = nil, description: String? = nil) {
        self.name = name
        self.description = description
    }
}

/// A promoted app. Use its bundle identifier as a stable, unique ID.
public struct AppAdItem: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    /// Filename of a PNG/JPEG in the library Resources/Icons directory.
    public let iconName: String?
    public let iconURL: URL?
    public let appStoreURL: URL
    public let isEnabled: Bool
    public let localizations: [String: AppAdTranslation]

    public init(id: String, name: String, description: String, iconName: String? = nil, iconURL: URL? = nil,
                appStoreURL: URL, isEnabled: Bool = true,
                localizations: [String: AppAdTranslation] = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.iconURL = iconURL
        self.appStoreURL = appStoreURL
        self.isEnabled = isEnabled
        self.localizations = localizations
    }

    public func localizedName(locale: Locale = .current) -> String {
        localizedValue(locale: locale, keyPath: \.name) ?? name
    }

    public func localizedDescription(locale: Locale = .current) -> String {
        localizedValue(locale: locale, keyPath: \.description) ?? description
    }

    private func localizedValue(locale: Locale, keyPath: KeyPath<AppAdTranslation, String?>) -> String? {
        for candidate in AppAdLocalization.candidates(for: locale) {
            // Sorting makes equivalent language tags deterministic.
            for key in localizations.keys.sorted() where AppAdLocalization.normalize(key) == candidate {
                if let value = localizations[key]?[keyPath: keyPath],
                   !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return value }
            }
        }
        return nil
    }

    /// Resolves only resources shipped with AppAd, independently of the host bundle.
    public var bundledIconURL: URL? {
        guard let iconName, !iconName.isEmpty,
              (iconName as NSString).lastPathComponent == iconName else { return nil }
        return Bundle.module.url(forResource: iconName, withExtension: nil, subdirectory: "Icons")
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, iconName, iconURL, appStoreURL, isEnabled, localizations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        iconURL = try container.decodeIfPresent(URL.self, forKey: .iconURL)
        appStoreURL = try container.decode(URL.self, forKey: .appStoreURL)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        localizations = try container.decodeIfPresent([String: AppAdTranslation].self, forKey: .localizations) ?? [:]
    }
}

public enum AppAdConfigurationError: LocalizedError {
    case resourceNotFound(String)
    case invalidItem(String)
    case duplicateID(String)

    public var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name): return String(format: AppAdLocalization.string("error.resource", locale: .current), name)
        case .invalidItem(let id): return String(format: AppAdLocalization.string("error.invalid", locale: .current), id)
        case .duplicateID(let id): return String(format: AppAdLocalization.string("error.duplicate", locale: .current), id)
        }
    }
}

public struct AppAdConfiguration: Codable, Equatable, Sendable {
    public let apps: [AppAdItem]

    public init(apps: [AppAdItem]) throws {
        self.apps = apps
        try validate()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apps = try container.decode([AppAdItem].self, forKey: .apps)
        try validate()
    }

    public static func load(data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }

    public static func load(named name: String = "app-ads", bundle: Bundle = .main) throws -> Self {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw AppAdConfigurationError.resourceNotFound(name)
        }
        return try load(data: Data(contentsOf: url))
    }

    /// The shared app catalog maintained inside this library.
    public static func bundled() throws -> Self {
        try load(named: "app-ads", bundle: .module)
    }

    @available(*, deprecated, renamed: "bundled()")
    public static func sample() throws -> Self { try bundled() }

    // Cache default loading; malformed bundled JSON hides the ad and logs the error.
    static let bundledDefault: Self? = {
        do { return try bundled() }
        catch {
            NSLog("AppAd: failed to load bundled catalog: %@", error.localizedDescription)
            return nil
        }
    }()

    public func eligibleApps(excluding currentAppID: String? = Bundle.main.bundleIdentifier) -> [AppAdItem] {
        apps.filter { $0.isEnabled && $0.id != currentAppID }
    }

    public func randomApp(excluding currentAppID: String? = Bundle.main.bundleIdentifier) -> AppAdItem? {
        eligibleApps(excluding: currentAppID).randomElement()
    }

    private func validate() throws {
        var ids = Set<String>()
        for app in apps {
            guard !app.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !app.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  app.appStoreURL.scheme?.lowercased() == "https",
                  app.appStoreURL.host?.lowercased() == "apps.apple.com",
                  app.appStoreURL.path.split(separator: "/").contains(where: {
                      $0.hasPrefix("id") && $0.dropFirst(2).allSatisfy(\.isNumber) && $0.count > 2
                  }),
                  app.iconURL == nil || (app.iconURL?.scheme?.lowercased() == "https" && app.iconURL?.host != nil)
            else { throw AppAdConfigurationError.invalidItem(app.id) }
            guard ids.insert(app.id).inserted else { throw AppAdConfigurationError.duplicateID(app.id) }
        }
    }
}
