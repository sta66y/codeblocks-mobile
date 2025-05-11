import SwiftUI

enum BlockRepository {
    static let conditions: [BlockModel] = [
        BlockModel(name: "if", type: .ifCase, color: .red),
        BlockModel(name: "else", type: .elseCase, color: .red)
    ]
    static let cycles: [BlockModel] = [
        BlockModel(name: "while", type: .whileCase, color: .yellow),
        BlockModel(name: "for", type: .forCase, color: .yellow)
    ]
    static let interactions: [BlockModel] = [
        BlockModel(name: "print", type: .printCase, color: .green)
    ]
}
