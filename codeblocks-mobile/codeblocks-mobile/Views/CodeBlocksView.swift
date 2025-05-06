import SwiftUI

struct CodeBlocksView: View {
    @Binding var selectedBlocks: [BlockModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ваша программа")
                .font(.title)
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(selectedBlocks) { block in
                        BlockView(
                            block: block
                        )
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .frame(minHeight: 300)
            
            Spacer()
        }
        .navigationTitle("Программа")
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
