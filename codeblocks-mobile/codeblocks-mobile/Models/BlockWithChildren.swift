import SwiftUI

struct BlockWithChildren: View {
    @Binding var block: BlockModel
    @State private var showingBlockSelection = false
    @Binding var allBlocks: [BlockModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BlockView(block: $block, allBlocks: $allBlocks)
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
                        
                        if newBlock.type == .declareVars {
                            BlockRepository.addBlock(newBlock, toChildrenOf: &updatedBlock)
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
                        } else {
                            BlockRepository.addBlock(newBlock, toChildrenOf: &updatedBlock)
                        }
                        allBlocks[index] = updatedBlock
                    }
                    showingBlockSelection = false
                })
            }
            
            if !block.children.isEmpty {
                ForEach($block.children, id: \.id) { $child in
                    BlockWithChildren(block: $child, allBlocks: $allBlocks)
                        .padding(.leading, 20)
                }
            }
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
