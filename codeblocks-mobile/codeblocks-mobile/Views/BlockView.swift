import SwiftUI
struct BlockView: View {
    @Binding var block: BlockModel
    @State private var selectedVariable: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(block.name)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(block.color)
                .cornerRadius(6)

            // Рендерим контент в зависимости от типа
            switch block.type {
            case .declareVars:
                TextField("Переменные (через запятую)", text: Binding(
                    get: { block.variableNames.joined(separator: ", ") },
                    set: { block.variableNames = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
            case .assign:
                HStack {
                    TextField("Имя переменной", text: $block.variable)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("=")
                    TextField("Выражение", text: $block.content)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
            case .add, .subtract, .multiply, .divide, .modulo:
                HStack {
                    if block.operands.count < 2 {
                        TextField("Операнд 1", text: $block.content)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text(block.name)
                        TextField("Операнд 2", text: Binding(
                            get: { "" },
                            set: { _ in }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
            case .ifCase, .whileCase:
                TextField("Условие", text: $block.content)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
            case .forCase:
                ForBlockView(content: $block.content)
                
            case .printCase:
                TextField("Что вывести", text: $block.content)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.vertical, 4)
    }
}
