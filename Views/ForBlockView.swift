import SwiftUI
struct ForBlockView: View {
    @Binding var content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Формат: i in 0..<10")
                .font(.caption)
                .foregroundColor(.gray)

            TextField("Переменная и диапазон", text: $content)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
