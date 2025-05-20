import SwiftUI

struct ResultView: View {
    @EnvironmentObject var programState: ProgramState
    
    var body: some View {
        VStack {
            Text("Результат программы")
                .font(.title)
                .padding()
            
            if programState.selectedBlocks.isEmpty {
                Text("Программа пуста")
                    .foregroundColor(.gray)
            } else {
                let result = runInterpreter()
                if result.isEmpty {
                    Text("Нет вывода")
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(result, id: \.self) { line in
                                Text(line)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Результат")
    }
    
    func runInterpreter() -> [String] {
        var context: Context = [:]
        return interpret(blocks: programState.selectedBlocks, context: &context)
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResultView()
                .environmentObject(ProgramState())
        }
    }
}

class ProgramState: ObservableObject {
    @Published var selectedBlocks: [BlockModel] = []
}
