import SwiftUI

struct BlockWithChildrenView: View {
    var block: BlockModel
    
    @Binding var selectedBlock: [BlockModel]
    
    var body: some View {
        BlockView(block: block)
        if !block.children.isEmpty {
            List {
                ForEach(block.children, id: \.id) { child in
                    BlockWithChildrenView(block: child, selectedBlock: $selectedBlock)
                }
                
                //frame(minHeight: 0, maxHeight: 200)
            }
        }
    }

}

