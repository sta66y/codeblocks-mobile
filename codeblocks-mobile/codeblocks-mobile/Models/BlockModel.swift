import Foundation
import SwiftUI

struct BlockModel: Identifiable {
    let id = UUID()
    let name: String
    let type: BlockType
    let color: Color
    
    enum BlockType {
        case ifCase
        case elseCase
        case whileCase
        case forCase
        case printCase
    }
}
