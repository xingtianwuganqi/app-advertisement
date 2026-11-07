import XCTest
#if canImport(AppKit)
import AppKit
#endif
@testable import AppAd

final class AppAdTests: XCTestCase {
    private func item(_ id: String, enabled: Bool = true, url: String = "https://apps.apple.com/app/id123456") -> AppAdItem {
        AppAdItem(id: id, name: "Test", description: "Description", appStoreURL: URL(string: url)!, isEnabled: enabled)
    }

    func testDecodeDefaultsAndRoundTrip() throws {
        let data = Data(#"{"apps":[{"id":"other","name":"App","description":"Hello","appStoreURL":"https://apps.apple.com/app/id123"}]}"#.utf8)
        let config = try AppAdConfiguration.load(data: data)
        XCTAssertTrue(config.apps[0].isEnabled)
        XCTAssertNil(config.apps[0].iconURL)
        XCTAssertEqual(try AppAdConfiguration.load(data: JSONEncoder().encode(config)), config)
    }

    func testSelectionExcludesHostAndDisabledApps() throws {
        let config = try AppAdConfiguration(apps: [item("host"), item("disabled", enabled: false), item("other")])
        XCTAssertEqual(config.eligibleApps(excluding: "host").map(\.id), ["other"])
        XCTAssertEqual(config.randomApp(excluding: "host")?.id, "other")
    }

    func testMissingIconUsesNoLocalResource() {
        let missing = AppAdItem(id: "missing", name: "Missing", description: "", iconName: "missing.png",
                                appStoreURL: URL(string: "https://apps.apple.com/app/id123")!)
        XCTAssertNil(missing.bundledIconURL)
        let traversal = AppAdItem(id: "bad", name: "Bad", description: "", iconName: "../app-ads.json",
                                  appStoreURL: URL(string: "https://apps.apple.com/app/id123")!)
        XCTAssertNil(traversal.bundledIconURL)
    }

    func testEmptyAndFullyExcludedConfigurations() throws {
        XCTAssertNil(try AppAdConfiguration(apps: []).randomApp())
        XCTAssertNil(try AppAdConfiguration(apps: [item("host")]).randomApp(excluding: "host"))
    }

    func testInvalidURLsAndDuplicatesAreRejected() throws {
        for url in ["http://apps.apple.com/app/id123", "https://example.com/app/id123", "https://apps.apple.com/"] {
            XCTAssertThrowsError(try AppAdConfiguration(apps: [item("app", url: url)]))
        }
        XCTAssertThrowsError(try AppAdConfiguration(apps: [item("same"), item("same")]))
        let malformed = Data(#"{"apps":[{"id":"a","name":"a","description":"a","appStoreURL":"https://example.com"}]}"#.utf8)
        XCTAssertThrowsError(try AppAdConfiguration.load(data: malformed))
        XCTAssertThrowsError(try AppAdConfiguration.load(data: Data("bad json".utf8)))
    }

    func testLocalizedContentMatchesRegionAndFallsBackPerField() throws {
        let app = AppAdItem(id: "test", name: "Base name", description: "Base description",
                            appStoreURL: URL(string: "https://apps.apple.com/app/id123")!,
                            localizations: [
                                "en": .init(name: "English", description: "English description"),
                                "en-GB": .init(name: "British"),
                                "zh-Hans": .init(name: "简体", description: "简体描述"),
                                "zh-Hant": .init(name: "繁體"),
                                "fr": .init(name: "   ")
                            ])
        XCTAssertEqual(app.localizedName(locale: Locale(identifier: "en_GB")), "British")
        XCTAssertEqual(app.localizedDescription(locale: Locale(identifier: "en_GB")), "English description")
        XCTAssertEqual(app.localizedName(locale: Locale(identifier: "zh_CN")), "简体")
        XCTAssertEqual(app.localizedName(locale: Locale(identifier: "zh_Hant_TW")), "繁體")
        XCTAssertEqual(app.localizedName(locale: Locale(identifier: "zh_HK")), "繁體")
        XCTAssertEqual(app.localizedName(locale: Locale(identifier: "zh_Hans_HK")), "简体")
        XCTAssertEqual(app.localizedDescription(locale: Locale(identifier: "zh_TW")), "Base description")
        XCTAssertEqual(app.localizedName(locale: Locale(identifier: "de_DE")), "Base name")
        XCTAssertEqual(app.localizedName(locale: Locale(identifier: "fr_FR")), "Base name")
        let config = try AppAdConfiguration(apps: [app])
        XCTAssertEqual(try AppAdConfiguration.load(data: JSONEncoder().encode(config)), config)
    }

    func testLibraryStringResourcesAndLanguageFallback() {
        XCTAssertEqual(AppAdLocalization.string("ad.title", locale: Locale(identifier: "en_US")), "More apps")
        XCTAssertEqual(AppAdLocalization.string("ad.action", locale: Locale(identifier: "zh_CN")), "查看")
        XCTAssertEqual(AppAdLocalization.string("ad.title", locale: Locale(identifier: "zh_HK")), "探索更多應用程式")
        XCTAssertEqual(AppAdLocalization.string("ad.title", locale: Locale(identifier: "de_DE")), "More apps")
        XCTAssertEqual(AppAdLocalization.string("ad.hint", locale: Locale(identifier: "zh_Hant")), "在 App Store 中查看此應用程式")
        XCTAssertEqual(String(format: AppAdLocalization.string("error.duplicate", locale: Locale(identifier: "en")), "test"), "Duplicate ad ID: test")
    }

    func testUnsupportedHostLanguageUsesEnglishAdContent() throws {
        let config = try AppAdConfiguration.bundled()
        let app = try XCTUnwrap(config.apps.first { $0.id == "com.junjing.pureride" })
        let requested = Locale(identifier: "ja_JP")
        let english = AppAdLocalization.contentLocale(for: requested, hostLocalizations: ["en", "zh-Hans"])
        XCTAssertEqual(app.localizedName(locale: english), app.localizations["en"]?.name)
        XCTAssertEqual(app.localizedDescription(locale: english), app.localizations["en"]?.description)
        let japanese = AppAdLocalization.contentLocale(for: requested, hostLocalizations: ["en", "ja"])
        XCTAssertEqual(app.localizedName(locale: japanese), app.localizations["ja"]?.name)
        XCTAssertEqual(app.localizedDescription(locale: japanese), app.localizations["ja"]?.description)
    }

    func testHostLanguageMatchingRespectsScriptsAndRegions() {
        func resolved(_ requested: String, _ supported: [String]) -> String {
            AppAdLocalization.contentLocale(for: Locale(identifier: requested), hostLocalizations: supported).identifier
        }
        XCTAssertEqual(resolved("en_GB", ["en-US"]), "en_GB")
        XCTAssertEqual(resolved("fr_CA", ["fr"]), "fr_CA")
        XCTAssertEqual(resolved("zh_HK", ["zh-Hant"]), "zh_HK")
        XCTAssertEqual(resolved("zh_TW", ["zh-Hans"]), "en")
        XCTAssertEqual(resolved("zh_CN", ["zh-Hant"]), "en")
        XCTAssertEqual(resolved("ja_JP", ["Base"]), "en")
        XCTAssertEqual(resolved("ja_JP", []), "en")
        XCTAssertEqual(resolved("ja_JP", ["JA"]), "ja_JP")
    }

    func testBundledCatalogAndLocalIconsLoad() throws {
        let config = try AppAdConfiguration.bundled()
        XCTAssertFalse(config.apps.isEmpty)
        XCTAssertNotNil(AppAdConfiguration.bundledDefault)
        for app in config.apps {
            let url = try XCTUnwrap(app.bundledIconURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            #if canImport(AppKit)
            XCTAssertNotNil(NSImage(contentsOf: url))
            #endif
            XCTAssertNil(app.iconURL)
        }
        XCTAssertEqual(try AppAdConfiguration.load(data: JSONEncoder().encode(config)), config)
        let hostID = config.apps[0].id
        XCTAssertFalse(config.eligibleApps(excluding: hostID).contains { $0.id == hostID })
    }
}
