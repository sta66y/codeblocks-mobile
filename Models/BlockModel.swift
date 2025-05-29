import Foundation
import SwiftUI

struct BlockModel: Identifiable {
    let id = UUID()
    let name: String
    let type: BlockType
    let color: Color
    var content: String = ""
    var children: [BlockModel] = []
    var variableNames: [String] = []
    var variable: String = ""
    var operands: [BlockModel] = []
    var operators: [String] = []
    
    enum BlockType {
        case declareVars
        case assign
        case ifCase
        case elseIfCase
        case elseCase
        case printCase
        case operatorCase
    }
}
