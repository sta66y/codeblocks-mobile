import SwiftUI

struct MainTabView: View {
    @State private var selectedBlocks: [BlockModel] = []
    
    var body: some View {
        TabView {
            CodeBlocksView(selectedBlocks: $selectedBlocks)
                .tabItem {
                    Label("Программа", systemImage: "list.bullet")
                }
            
            ResultView()
                .tabItem {
                    Label("Результат", systemImage: "play.circle")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainTabView()
        }
    }
}
