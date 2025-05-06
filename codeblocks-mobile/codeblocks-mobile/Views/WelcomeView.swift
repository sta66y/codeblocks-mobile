import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Добро пожаловать в CodeBlocks!")
                    .font(.largeTitle)
                    .padding()
                NavigationLink(destination: MainTabView()) {
                    Text("Начать")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("CodeBlocks")
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
