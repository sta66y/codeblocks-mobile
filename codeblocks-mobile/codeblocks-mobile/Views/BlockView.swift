import SwiftUI

struct BlockView: View {
    let block: BlockModel
    
    var body: some View {
        Text(block.name)
            .padding()
            .background(block.color)
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.headline)
    }
}


