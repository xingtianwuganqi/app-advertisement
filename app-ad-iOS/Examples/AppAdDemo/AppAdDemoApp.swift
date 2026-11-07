import SwiftUI
import AppAd

@main
struct AppAdDemoApp: App {
    var body: some Scene {
        WindowGroup { DemoView() }
    }
}

private struct DemoView: View {
    @State private var refreshID = UUID()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("在你的应用中，发现更多好用的应用。")
                        .font(.title2.bold())
                    Text("应用信息和图标由 AppAd 库统一维护。")
                        .foregroundStyle(.secondary)
                    AppAdView().id(refreshID)
                    Button("随机换一个") { refreshID = UUID() }
                    Divider()
                    AppAdListView()
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("AppAd 演示")
        }
    }
}
