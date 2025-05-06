import SwiftUI

class BlockRepository {
    private let conditions: [BlockModel] = [
        BlockModel(name: "if", type: .ifCase, color: .red),
        BlockModel(name: "else", type: .elseCase, color: .red)
    ]
    private let cycles: [BlockModel] = [
        BlockModel(name: "while", type: .whileCase, color: .yellow),
        BlockModel(name: "for", type: .forCase, color: .yellow)
    ]
    private let interactions: [BlockModel] = [
        BlockModel(name: "print", type: .printCase, color: .green)
    ]

    func getConditions() -> [BlockModel] {
        return conditions
    }
    
    func getCycles() -> [BlockModel] {
        return cycles
    }
    
    func getInteractions() -> [BlockModel] {
        return interactions
    }
}
