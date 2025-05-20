import SwiftUI

struct MainTabView: View {
    @StateObject private var programState = ProgramState()
    
    var body: some View {
        TabView {
            CodeBlocksView(selectedBlocks: $programState.selectedBlocks)
                .tabItem {
                    Label("Программа", systemImage: "list.bullet")
                }
            
            ResultView()
                .tabItem {
                    Label("Результат", systemImage: "play.circle")
                }
        }
        .environmentObject(programState)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainTabView()
        }
    }
}
