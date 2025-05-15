import SwiftUI

enum BlockRepository {
    static let variables: [BlockModel] = [
        BlockModel(name: "Объявить переменные", type: .declareVars, color: .blue),
        BlockModel(name: "Присвоить", type: .assign, color: .purple)
    ]
    
    static let arithmetic: [BlockModel] = [
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
