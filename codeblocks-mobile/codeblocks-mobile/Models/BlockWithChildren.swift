import SwiftUI

struct BlockWithChildren: View {
    @Binding var block: BlockModel
    @State private var showingBlockSelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BlockView(block: block)
                Button(action: {
                    showingBlockSelection = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.green)
                }
            }
            .sheet(isPresented: $showingBlockSelection) {
                BlockSelectionSheet(onSelect: { selectedBlock in
                    if !selectedBlock.name.isEmpty {
                        block.children.append(selectedBlock)
                        print("Добавлен блок: \(selectedBlock.name) в children блока: \(block.name)")
                    }
                    showingBlockSelection = false
                })
            }
            
            if !block.children.isEmpty {
                ForEach($block.children, id: \.id) { $child in
                    BlockWithChildren(block: $child)
                        .padding(.leading, 20)
                }
            }
        }
    }
}
