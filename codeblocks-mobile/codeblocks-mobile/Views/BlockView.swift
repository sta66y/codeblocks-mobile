import SwiftUI
struct BlockView: View {
    @Binding var block: BlockModel

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
            case .ifCase, .whileCase, .elseCase:
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
