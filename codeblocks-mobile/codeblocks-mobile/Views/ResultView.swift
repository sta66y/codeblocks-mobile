import SwiftUI

struct ResultView: View {
    var body: some View {
        VStack {
            Text("Результат программы")
                .font(.title)
                .padding()
        }
        .navigationTitle("Результат")
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResultView()
        }
    }
}
