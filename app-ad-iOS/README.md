# AppAd iOS

用于自有应用交叉推广的 Swift Package，支持 iOS 15+、SwiftUI 和 UIKit，无第三方依赖。

## 统一维护应用列表与图标

所有接入方默认使用库中的同一份应用列表和本地图标，不需要在主 App 中复制 JSON 或图片：

- `Sources/AppAd/Resources/app-ads.json`：维护应用列表。
- `Sources/AppAd/Resources/Icons/`：维护 PNG/JPEG 图标。

```json
{
  "apps": [
    {
      "id": "com.yourcompany.yourapp",
      "name": "你的应用",
      "description": "一句话介绍应用的核心价值",
      "iconName": "your-app.png",
      "appStoreURL": "https://apps.apple.com/app/id123456789",
      "isEnabled": true
    }
  ]
}
```

将 `your-app.png` 放入库的 `Resources/Icons/`，`iconName` 填完整文件名（区分大小写，不含路径）。图片随 Swift Package 打包，从库自己的 Bundle 加载，无需网络。

`id` 必须填写应用的真实 Bundle Identifier，展示时用主 App 的 `Bundle.main.bundleIdentifier` 自动排除自身。`isEnabled` 默认为 `true`，设为 `false` 可禁用某条记录。图标字段可省略，文件不存在或无法解码时显示默认图标。保留可选 `iconURL` 兼容按需使用远程图标，本地图标优先。

当前列表已收录 Text Wall，包含英文、简体中文、繁体中文、日文及韩文的名称与推广介绍，以及项目正式 App Icon。默认英文文案作为未配置语言的回退。

修改库中的配置或图标后，接入方需更新库版本并重新构建、发布 App，已安装版本不会自动获取新配置。

## SwiftUI 接入

Xcode → File → Add Package Dependencies → Add Local，选择 `app-ad-iOS` 文件夹，给业务 Target 添加 AppAd 产品。

```swift
import AppAd

// 直接使用库中的配置和图标，随机展示一个其他应用。
AppAdView()
```

可传入 `title` 自定义标题，通过 `.tint(...)` 设置主题颜色。`actionTitle` 用于自定义点击操作的无障碍提示，卡片右侧始终显示箭头：

```swift
AppAdView(title: "我的其他应用") { app in
    print("点击了：\(app.name)")
}
```

回调执行后会打开 App Store HTTPS 链接。链接由系统处理，具体打开 App Store 还是浏览器取决于运行环境。

每个 View 身份存续期间保持同一个随机结果，普通重绘不会切换。需要重新随机时使用 `.id(refreshID)`，并改变 `refreshID`；随机结果可能与上次相同。无可展示应用时不占位。默认配置加载失败时不展示，并输出日志；可用 `try AppAdConfiguration.bundled()` 显式检查错误。

如需覆盖配置，仍可使用 `AppAdView(configuration: config)`，通过 `AppAdConfiguration.load(data:)`、`load(named:bundle:)` 或初始化模型创建配置。`load(named:bundle:)` 默认查找主 App Bundle，仅用于显式覆盖；默认 View 使用库的 `bundled()` 配置。

## UIKit 接入

```swift
let adController = AppAdViewController()
addChild(adController)
containerView.addSubview(adController.view)
adController.view.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    adController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
    adController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
    adController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
    adController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
])
adController.didMove(toParent: self)
```

在主线程中创建和嵌入控制器，由宿主给 `containerView` 提供合适的尺寸约束。

## 演示与验证

打开 `Examples/AppAdDemo/AppAdDemo.xcodeproj`，选择 AppAdDemo 和 iPhone 模拟器运行。演示项目直接调用 `AppAdView()`，没有单独的 JSON 或图标副本。真机运行需设置签名团队和 Bundle Identifier。

```sh
swift test
xcodebuild -project Examples/AppAdDemo/AppAdDemo.xcodeproj \
  -scheme AppAdDemo -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

JSON 加载时会校验重复 ID、空 ID、空名称和 HTTPS 链接结构，不验证应用是否实际上架。库不会采集数据、请求远程配置或自动轮播。

本仓库的 Package.swift 位于子目录。如需通过 Git URL 分发，请将 `app-ad-iOS` 内容发布为独立仓库根目录。

## 国际化

默认读取 SwiftUI 的 `locale` 环境（通常为 App / 系统语言），内置英文、简体中文和繁体中文的标题、按钮、无障碍提示及错误提示。默认调用仍是 `AppAdView()` / `AppAdViewController()`。

应用名称和描述统一在库的 `app-ads.json` 中维护翻译，原来的 `name`、`description` 是缺失翻译时的默认值，旧 JSON 无需修改也能加载：

```json
{
  "apps": [
    {
      "id": "com.yourcompany.yourapp",
      "name": "默认应用名称",
      "description": "默认应用描述",
      "iconName": "your-app.png",
      "appStoreURL": "https://apps.apple.com/app/id123456789",
      "localizations": {
        "en": { "name": "My App", "description": "An introduction to my app." },
        "zh-Hans": { "name": "我的应用", "description": "应用介绍。" },
        "zh-Hant": { "name": "我的應用程式", "description": "應用程式介紹。" }
      }
    }
  ]
}
```

语言键使用 BCP 47 风格，如 `en`、`en-GB`、`zh-Hans`、`zh-Hant`，同时兼容下划线和大小写差异。按完整语言标签 → 文字系统 → 基础语言依次查找，每个字段独立回退到原始 `name` / `description`，空白翻译也视为缺失。中文地区会映射文字系统：台湾、香港、澳门默认繁体，其余默认简体；显式的 Hans / Hant 优先。

组件文案不支持某语言时回退到英文。要扩展组件语言，请在库资源中增加对应 `.lproj/Localizable.strings`，同步添加 `Package.swift` 的资源声明及 `AppAdLocalization.swift` 的 `languages` 列表。接入方主 App 也应在 Xcode 的 Localizations 中声明支持的语言，才能在系统的 App 语言设置中提供对应选项。

手动指定语言：

```swift
AppAdView(locale: Locale(identifier: "en"))
AppAdViewController(locale: Locale(identifier: "zh-Hant"))

// SwiftUI 也可以继承宿主动态设置的语言环境。
AppAdView().environment(\.locale, Locale(identifier: "zh-Hans"))
```

显式 `locale` 优先于环境语言，但广告名称与描述仍受主 App 支持的语言范围限制。传入自定义 `title` / `actionTitle` 时按原文展示，由宿主负责翻译。语言变化只更新文案，不重新随机选择广告。图标和 App Store 链接各语言共用。

如需在点击回调中获得展示语言的文案，可调用 `app.localizedName(locale:)` 和 `app.localizedDescription(locale:)`。原始 `app.name` / `app.description` 保持为默认值。


## Text Wall 资料来源

- 来源项目：`/Users/jingjun/Desktop/Githup/Wallpaper/Wallpaper`
- 名称与推广介绍：`AppStore_Matedata.md` 的五语言 App 名称和推广文本字段。
- Bundle Identifier：`Wallpaper.xcodeproj/project.pbxproj` 的主应用 Target，`com.jingjun.plan`。
- 图标：`Wallpaper/Assets.xcassets/AppIcon.appiconset/icon-1024.png`，原样复制为库中的 `Icons/text-wall.png`。
- App Store：从 `TextWall-3.3.0-AppStore-QR.png` 解码得到应用 ID `6448674789`，使用无地区前缀的 `https://apps.apple.com/app/id6448674789`。

当前列表包含 Text Wall、TextReel 与 VeloPure。每个主 App 会排除自己的 Bundle Identifier，再从其他启用的应用中随机展示一条。


## TextReel 资料来源

- 来源项目：`/Users/jingjun/Desktop/Githup/MotionText`。
- 名称与推广介绍：`TextReel_App_Store_Metadata_v1-3.md` 的 App 名称及推广文本，包含英文、简体中文、繁体中文、日文、韩文、法文、德文、泰文、西班牙文和越南文。该文档含待发布商店文案，列表使用其名称和推广文本，未使用版本更新说明。
- Bundle Identifier：主应用 Target 的 `com.junjing.motiontext`。
- 图标：`MotionText/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`，原样复制为 `Icons/textreel.png`。
- App Store：已核对官方商店页面，应用 ID 为 `6797247354`，配置链接为 `https://apps.apple.com/app/id6797247354`。来源项目设置页内的推荐链接指向 Text Wall，未用作 TextReel 自身链接。
- 法文、德文、西班牙文等使用基础语言键，支持对应语言的不同地区回退；组件标题和按钮目前仍内置英、简中、繁中，其余语言组件文案回退英文。


## VeloPure 资料来源

- 来源项目：`/Users/jingjun/Desktop/Githup/pureride-ios/pure-ride-iOS`。
- 名称：仓库根目录 `VeloPure_App_Store_Metadata_v3.md` 的 16 语言名称表，简中“极简骑行”、繁中“極簡騎行”，其余使用 VeloPure 品牌。
- 推广介绍：`VeloPure_App_Store_Metadata_v2.md` 的 16 语言推广文本，覆盖英、简中、繁中、日、韩、法、德、泰、西、越、荷兰、挪威 Bokmål、葡萄牙、冰岛、丹麦及意大利语。
- Bundle Identifier：iPhone 主应用 Target 的 `com.junjing.pureride`，不使用 Watch 或 Live Activity 扩展标识。
- 图标：`PureRide/PureRide/Assets.xcassets/AppIcon.appiconset/icon-1024.png`，原样复制为 `Icons/velopure.png`。
- App Store：依据来源仓库 `output/wechat/velopure-wechat-article.md` 的商店链接，应用 ID `6799878817`；配置使用无地区前缀的 `https://apps.apple.com/app/id6799878817`。
- 默认英文名称与介绍用于缺失翻译的回退；组件标题和按钮的语言资源独立于应用介绍。


## 主 App 语言范围与英文回退

广告名称和描述展示前会读取 `Bundle.main.localizations`，只使用主 App 明确支持的语言，库自身支持更多语言不会扩大该范围。

例如 VeloPure 有日文介绍，但主 App 仅支持英文和简体中文：即使系统或传入的 `locale` 为日文，广告仍显示英文名称和介绍；主 App 也支持日文时才显示日文广告。该规则同样适用于 UIKit 包装及手动传入 `locale` 的情况。

地区变体按语言匹配（如 `fr-CA` 可使用主 App 声明的 `fr`），中文区分简繁（`zh-Hans` 不会视为支持 `zh-Hant`）。`Base` 不算具体语言；没有具体语言声明时使用英文广告。请在主 App 的 Xcode Localizations / `CFBundleLocalizations` 中声明实际支持的语言。

此限制作用于 View 展示的应用名称和描述。显式调用模型的 `localizedName(locale:)` / `localizedDescription(locale:)` 仍按传入语言查询，便于宿主自行处理文案。组件标题和按钮沿用自身语言资源及回退规则。若 JSON 中某字段缺少英文翻译，最终使用其顶层默认值；请保持顶层 `name` / `description` 为英文，或为所有广告提供完整的 `en` 翻译。目前库内三款应用均已配置英文。

## 展示全部其他应用的列表

使用 `AppAdListView()` 展示所有启用的应用，按 JSON 顺序排列，自动排除主 App 的 Bundle Identifier；没有可展示应用时，整个列表及标题都隐藏。

```swift
import SwiftUI
import AppAd

struct OtherAppsPage: View {
    var body: some View {
        ScrollView {
            AppAdListView()
                .padding()
        }
    }
}
```

列表使用 `LazyVStack`，本身不创建滚动容器，可直接放入宿主已有的 ScrollView。它和随机广告共用卡片组件，支持本地图标、点击回调、跳转 App Store，以及主 App 不支持当前语言时广告名称与介绍回退英文。

```swift
AppAdListView(
    currentAppID: "com.junjing.pureride",
    title: "我的其他应用",
    actionTitle: "在 App Store 中查看"
) { app in
    print("点击了：\(app.id)")
}
```

通常不需要传入 `currentAppID`，默认自动读取主 App Bundle Identifier；示例中手动指定仅用于演示排除规则。也可传入自定义 `configuration` 或 `locale`，含义与 `AppAdView` 一致。

UIKit 可使用自带滚动容器的控制器，或按标准控制器包含关系嵌入：

```swift
let controller = AppAdListViewController()
navigationController?.pushViewController(controller, animated: true)
```

演示工程同时展示随机单条广告和完整列表。


## 广告卡片样式

随机广告和列表共用相同的卡片样式。先按主 App 语言范围选择本地化名称，再用第一个 `-` 拆分：前半部分显示为应用名称，后半部分显示为简短介绍，并去掉两端空格。例如：

- `Text Wall - 文字壁纸与小组件` → 标题 `Text Wall`，介绍 `文字壁纸与小组件`。
- `TextReel-Text Video Maker` → 标题 `TextReel`，介绍 `Text Video Maker`。

简短介绍直接取自 JSON 中各语言的 `localizations.<语言>.name` 后半部分，因此翻译仍统一在库中维护。主 App 不支持当前语言时，使用英文名称拆分后的标题和介绍。后半部分中的其他连字符会保留；名称没有有效分隔符时，显示完整名称并使用原有本地化 `description`。

右侧使用 `chevron.right` 图标，不显示“查看／前往 App”等文字。名称和介绍各显示一行，超出部分以省略号截断。整张卡片（包含标题、内边距留白、图标和箭头）均可点击跳转 App Store；默认无障碍提示继续按语言显示，传入 `actionTitle` 可覆盖该提示。
