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
                    ForEach($selectedBlocks) { $block in
                        BlockWithChildren(block: $block, allBlocks: $selectedBlocks)
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
            BlockSelectionSheet(onSelect: { selectedBlock in
                BlockRepository.addBlock(selectedBlock, to: &selectedBlocks)
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
