import SwiftUI

struct BlockWithChildren: View {
    @Binding var block: BlockModel
    @Binding var allBlocks: [BlockModel]
    let index: Int
    @State private var showingBlockSelection = false
    @State private var blockToAddTo: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerView
            childBlocksView
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
                
                if let blockId = blockToAddTo {
                    if block.id == blockId && block.id == allBlocks.first(where: { $0.id == blockId })?.id {
                        if let blockIndex = allBlocks.firstIndex(where: { $0.id == blockId }) {
                            allBlocks[blockIndex].children.append(newBlock)
                        }
                    } else {
                        updateChildBlock(blockId: blockId, in: &allBlocks, with: newBlock)
                    }
                }
                
                blockToAddTo = nil
                showingBlockSelection = false
            })
        }
        .onChange(of: block.variableNames) { oldValue, newValue in
            if block.type == .declareVars {
                block.variableNames = newValue
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            BlockView(block: $block, allBlocks: $allBlocks, index: index)
            if canHaveChildren(block: block) {
                Button(action: {
                    blockToAddTo = block.id
                    showingBlockSelection = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var childBlocksView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !block.children.isEmpty {
                    ForEach(Array(block.children.enumerated()), id: \.element.id) { index, _ in
                        childBlockRow(childIndex: index)
                            .id(block.children[index].id)
                    }
                }
            }
        }
    }
    
    private func childBlockRow(childIndex: Int) -> some View {
        HStack(alignment: .top) {
            Button(action: {
                withAnimation {
                    deleteChild(at: childIndex)
                }
            }) {
                Text("−")
                    .foregroundColor(.red)
                    .font(.system(size: 20, weight: .bold))
            }
            .padding(.trailing, 5)

            BlockWithChildren(
                block: $block.children[childIndex],
                allBlocks: $allBlocks,
                index: index
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .transition(.asymmetric(insertion: .identity, removal: .move(edge: .trailing)))
    }
    
    func canHaveChildren(block: BlockModel) -> Bool {
        return Set([BlockModel.BlockType.ifCase, .elseIfCase, .elseCase, .whileCase, .forCase]).contains(block.type)
    }
    
    func deleteChild(at index: Int) {
        block.children.remove(at: index)
    }
    
    func updateChildBlock(blockId: UUID, in blocks: inout [BlockModel], with newBlock: BlockModel) {
        for i in blocks.indices {
            if blocks[i].id == blockId {
                blocks[i].children.append(newBlock)
                return
            }
            updateChildBlock(blockId: blockId, in: &blocks[i].children, with: newBlock)
        }
    }
}
