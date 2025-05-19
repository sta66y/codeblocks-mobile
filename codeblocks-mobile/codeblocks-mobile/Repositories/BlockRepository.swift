import SwiftUI

enum BlockRepository {
    static func addBlock(_ block: BlockModel, to blocks: inout [BlockModel]) {
            if !block.name.isEmpty {
                blocks.append(block)
                print("Добавлен блок: \(block.name) с ID \(block.id) в род блок")
            }
    }
        
    static func addBlock(_ block: BlockModel, toChildrenOf parentBlock: inout BlockModel) {
        if !block.name.isEmpty {
            parentBlock.children.append(block)
            print("Добавлени блок: \(block.name) с ID \(block.id) в children блок: \(parentBlock.name) с ID \(parentBlock.id) \(parentBlock.children.count) \(parentBlock.children.map { $0.name })")
        }
    }
    
    static let variables: [BlockModel] = [
        BlockModel(name: "Объявить переменные", type: .declareVars, color: .blue),
        BlockModel(name: "Присвоить", type: .assign, color: .purple)
    ]
    
    static let arithmetic: [BlockModel] = [
        BlockModel(name: "Арифметическое выражение", type: .operatorCase, color: .orange),
        BlockModel(name: "+", type: .add, color: .orange),
        BlockModel(name: "-", type: .subtract, color: .orange),
        BlockModel(name: "*", type: .multiply, color: .orange),
        BlockModel(name: "/", type: .divide, color: .orange),
        BlockModel(name: "%", type: .modulo, color: .orange)
    ]
    
    static let conditions: [BlockModel] = [
        BlockModel(name: "if", type: .ifCase, color: .red),
    ]
    
    static let cycles: [BlockModel] = [
        BlockModel(name: "while", type: .whileCase, color: .yellow),
        BlockModel(name: "for", type: .forCase, color: .yellow)
    ]
    
    static let interactions: [BlockModel] = [
        BlockModel(name: "print", type: .printCase, color: .green)
    ]
}
