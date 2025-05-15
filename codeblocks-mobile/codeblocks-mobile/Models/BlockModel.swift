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

    enum BlockType {
        case declareVars
        case assign
        case add
        case subtract
        case multiply
        case divide
        case modulo
        case ifCase
        case whileCase
        case forCase
        case printCase
    }
}
