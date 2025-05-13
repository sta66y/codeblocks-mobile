import SwiftUI

struct CodeBlocksView: View {
    @Binding var selectedBlocks: [BlockModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ваша программа")
                .font(.title)
                .padding()
            
            List {
                ForEach(selectedBlocks) { block in
                    BlockView(block: block)
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            }
            .environment(\.editMode, .constant(.active))
        }
        .navigationTitle("Программа")
    }
    
    func move(from source: IndexSet, to destination: Int) {
        selectedBlocks.move(fromOffsets: source, toOffset: destination)
    }
    
    func delete(at offsets: IndexSet) {
        selectedBlocks.remove(atOffsets: offsets)
    }
}

struct CodeBlocksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CodeBlocksView(selectedBlocks: .constant([
                BlockModel(name: "while", type: .whileCase, color: .yellow),
                BlockModel(name: "for", type: .forCase, color: .yellow)
            ]))
        }
    }
}
