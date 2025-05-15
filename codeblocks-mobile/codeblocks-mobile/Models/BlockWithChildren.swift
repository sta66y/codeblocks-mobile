import SwiftUI

struct BlockWithChildren: View {
    @Binding var block: BlockModel
    @State private var showingBlockSelection = false
    @Binding var allBlocks: [BlockModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BlockView(block: $block, allBlocks: $allBlocks)
                Button(action: {
                    showingBlockSelection = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.green)
                }
            }
            .sheet(isPresented: $showingBlockSelection) {
                BlockSelectionSheet(onSelect: { selectedBlock in
                    if selectedBlock.type == .declareVars {
                        var newBlock = selectedBlock
                        BlockRepository.addBlock(newBlock, toChildrenOf: &block)
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
                        BlockRepository.addBlock(selectedBlock, toChildrenOf: &block)
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
}
