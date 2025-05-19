import SwiftUI

struct BlockWithChildren: View {
    @Binding var block: BlockModel
    @State private var showingBlockSelection = false
    @Binding var allBlocks: [BlockModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                BlockView(block: $block, allBlocks: $allBlocks)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(block.color.opacity(0.2))
                            .shadow(radius: 2)
                    )
                if Set([BlockModel.BlockType.ifCase, .whileCase, .forCase]).contains(block.type) {
                    Button(action: {
                        showingBlockSelection = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.green)
                            .padding(6)
                            .background(Circle().fill(Color.white).shadow(radius: 1))
                    }
                }
            }
            .padding(.horizontal, 8)
            
            if !block.children.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach($block.children, id: \.id) { $child in
                        BlockWithChildren(block: $child, allBlocks: $allBlocks)
                            .padding(.leading, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                                    .padding(.vertical, 2)
                            )
                    }
                }
                .padding(.top, 4)
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
                
                BlockRepository.addBlock(newBlock, toChildrenOf: &block)
                
                updateAllBlocks()
                
                if newBlock.type == .declareVars {
                    let assignedVariables = allBlocks
                        .filter { $0.type == .assign && !$0.variable.isEmpty }
                        .map { $0.variable }
                    let availableVariables = newBlock.variableNames.filter { !assignedVariables.contains($0) }
                    
                    for variable in availableVariables {
                        let assignBlock = BlockModel(
                            name: "Присвоить",
                            type: .assign,
                            color: .purple,
                            content: "",
                            variableNames: newBlock.variableNames,
                            variable: variable
                        )
                        BlockRepository.addBlock(assignBlock, toChildrenOf: &newBlock)
                    }
                    
                    if let childIndex = block.children.firstIndex(where: { $0.id == newBlock.id }) {
                        block.children[childIndex] = newBlock
                        updateAllBlocks()
                    }
                }
                
                showingBlockSelection = false
            })
        }
        .onChange(of: block.variableNames) { oldValue, newValue in
            if block.type == .declareVars {
                var existingAssignBlocks = block.children.filter { $0.type == .assign }
                var newAssignBlocks: [BlockModel] = []
                let assignedVariables = allBlocks
                    .filter { $0.type == .assign && !$0.variable.isEmpty && $0.id != block.id }
                    .map { $0.variable }
                
                for variable in newValue {
                    if !assignedVariables.contains(variable) {
                        if let existingIndex = existingAssignBlocks.firstIndex(where: { $0.variable == variable }) {
                            var updatedBlock = existingAssignBlocks[existingIndex]
                            updatedBlock.variableNames = newValue
                            newAssignBlocks.append(updatedBlock)
                            existingAssignBlocks.remove(at: existingIndex)
                        } else {
                            let assignBlock = BlockModel(
                                name: "Присвоить",
                                type: .assign,
                                color: .purple,
                                content: "",
                                variableNames: newValue,
                                variable: variable
                            )
                            newAssignBlocks.append(assignBlock)
                        }
                    }
                }
                
                block.children = block.children.filter { $0.type != .assign } + newAssignBlocks
                updateAllBlocks()
            }
        }
    }

    private func updateAllBlocks() {
        func updateBlockHierarchy(_ blocks: inout [BlockModel], targetId: UUID, updatedBlock: BlockModel) -> Bool {
            for i in 0..<blocks.count {
                if blocks[i].id == targetId {
                    blocks[i] = updatedBlock
                    return true
                }
                if updateBlockHierarchy(&blocks[i].children, targetId: targetId, updatedBlock: updatedBlock) {
                    return true
                }
            }
            return false
        }
        
        var updatedBlocks = allBlocks
        _ = updateBlockHierarchy(&updatedBlocks, targetId: block.id, updatedBlock: block)
        allBlocks = updatedBlocks
    }
}
