import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            BookshelfView()
                .tabItem {
                    Label("书架", systemImage: "books.vertical")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
    }
}
