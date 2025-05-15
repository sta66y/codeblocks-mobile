import SwiftUI

struct BlockWithChildren: View {
    @Binding var block: BlockModel
    @State private var showingBlockSelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BlockView(block: $block)
                if Set([BlockModel.BlockType.ifCase, .whileCase, .forCase]).contains(block.type) {
                    Button(action: {
                        showingBlockSelection = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showingBlockSelection) {
                BlockSelectionSheet(onSelect: { selectedBlock in
                    BlockRepository.addBlock(selectedBlock, toChildrenOf: &block)
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
