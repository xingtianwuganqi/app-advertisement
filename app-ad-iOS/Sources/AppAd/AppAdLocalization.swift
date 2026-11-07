import Foundation

/// Shared language matching for JSON content and the library string resources.
enum AppAdLocalization {
    static func normalize(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "_", with: "-")
            .split(separator: "@").first.map(String.init)?.lowercased() ?? ""
    }

    static func candidates(for locale: Locale) -> [String] {
        let tag = normalize(locale.identifier)
        let parts = tag.split(separator: "-").map(String.init)
        guard let language = parts.first else { return [] }
        var result = [tag]
        if language == "zh" {
            // A region-only Chinese locale still needs the correct script fallback.
            let traditional = parts.contains("hant") ||
                (!parts.contains("hans") && parts.contains(where: { ["tw", "hk", "mo"].contains($0) }))
            result.append(traditional ? "zh-hant" : "zh-hans")
        } else if parts.count > 1, parts[1].count == 4 {
            result.append("\(language)-\(parts[1])")
        }
        result.append(language)
        var seen = Set<String>()
        return result.filter { seen.insert($0).inserted }
    }

    /// Package languages must not expand the set of languages supported by the host app.
    static func contentLocale(for requested: Locale,
                              hostLocalizations: [String] = Bundle.main.localizations) -> Locale {
        let requestedTag = normalize(requested.identifier)
        let requestedLanguage = requestedTag.split(separator: "-").first.map(String.init)
        let requestedScript = script(for: requested)
        let supported = hostLocalizations.contains { identifier in
            let tag = normalize(identifier)
            guard tag != "base",
                  tag.split(separator: "-").first.map(String.init) == requestedLanguage else { return false }
            // A generic language declaration accepts its regional variants. Explicit
            // scripts (including Chinese region-derived scripts) must agree.
            guard let hostScript = script(for: Locale(identifier: identifier)) else { return true }
            return hostScript == requestedScript
        }
        return supported ? requested : Locale(identifier: "en")
    }

    private static func script(for locale: Locale) -> String? {
        let parts = normalize(locale.identifier).split(separator: "-").map(String.init)
        if let explicit = parts.dropFirst().first(where: { $0.count == 4 }) { return explicit }
        if parts.first == "zh", parts.count > 1 {
            return candidates(for: locale).contains("zh-hant") ? "hant" : "hans"
        }
        return nil
    }

    static func string(_ key: String, locale: Locale) -> String {
        let languages = ["en", "zh-Hans", "zh-Hant"]
        for candidate in candidates(for: locale) + ["en"] {
            guard let language = languages.first(where: { normalize($0) == candidate }),
                  let path = Bundle.module.path(forResource: language, ofType: "lproj"),
                  let bundle = Bundle(path: path) else { continue }
            let value = bundle.localizedString(forKey: key, value: key, table: nil)
            if value != key { return value }
        }
        return key
    }
}
