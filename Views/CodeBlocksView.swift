import SwiftUI

struct CodeBlocksView: View {
    @Binding var selectedBlocks: [BlockModel]
    @State private var showingBlockSelection = false
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Ваша программа")
                    .font(.title)
                    .padding()
                
                List {
                    ForEach(Array($selectedBlocks.enumerated()), id: \.element.id) { index, $block in
                        BlockWithChildren(block: $block, allBlocks: $selectedBlocks, index: index)
                    }
                    .onMove(perform: move)
                    .onDelete(perform: delete)
                }
                .environment(\.editMode, .constant(.active))
            }
            .navigationTitle("Программа")
            
            // плюсик
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingBlockSelection = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingBlockSelection) {
            BlockSelectionSheet(parentBlockId: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(), onSelect: { selectedBlock in
                let newBlock = BlockModel(
                    name: selectedBlock.name,
                    type: selectedBlock.type,
                    color: selectedBlock.color,
                    content: selectedBlock.content,
                    variableNames: selectedBlock.variableNames,
                    variable: selectedBlock.variable,
                    operands: selectedBlock.operands
                )
                BlockRepository.addBlock(newBlock, to: &selectedBlocks)
                showingBlockSelection = false
            })
        }
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
            CodeBlocksView(selectedBlocks: .constant([]))
        }
    }
}
