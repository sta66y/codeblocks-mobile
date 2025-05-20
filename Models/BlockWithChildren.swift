import SwiftUI

struct BlockWithChildren: View {
    @Binding var block: BlockModel
    @State private var showingBlockSelection = false
    @Binding var allBlocks: [BlockModel]
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BlockView(block: $block, allBlocks: $allBlocks, index: index)
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
                BlockSelectionSheet(parentBlockId: block.id, onSelect: { selectedBlock in
                    var newBlock = BlockModel(
                        name: selectedBlock.name,
                        type: selectedBlock.type,
                        color: selectedBlock.color,
                        content: selectedBlock.content,
                        variableNames: selectedBlock.variableNames,
                        variable: selectedBlock.variable,
                        operands: selectedBlock.operands
                    )
                    
                    if let index = allBlocks.firstIndex(where: { $0.id == block.id }) {
                        var updatedBlock = deepCopyBlock(allBlocks[index])
                        BlockRepository.addBlock(newBlock, toChildrenOf: &updatedBlock)
                        allBlocks[index] = updatedBlock
                    }
                    showingBlockSelection = false
                })
            }
            
            if !block.children.isEmpty {
                ForEach($block.children, id: \.id) { $child in
                    BlockWithChildren(block: $child, allBlocks: $allBlocks, index: index)
                        .padding(.leading, 20)
                }
            }
        }
        .onChange(of: block.variableNames) { oldValue, newValue in
            if block.type == .declareVars {
                block.variableNames = newValue
            }
        }
    }
    
    private func deepCopyBlock(_ block: BlockModel) -> BlockModel {
        return BlockModel(
            name: block.name,
            type: block.type,
            color: block.color,
            content: block.content,
            children: block.children.map { deepCopyBlock($0) },
            variableNames: block.variableNames,
            variable: block.variable,
            operands: block.operands.map { deepCopyBlock($0) }
        )
    }
}
