import SwiftUI

struct BlocksSelectionView: View {
    @Binding var selectedBlocks: [BlockModel]
    private let repository = BlockRepository()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Выберите блоки")
                .font(.title)
                .padding()
            
            List {
                Section(header: Text("Условия").font(.headline)) {
                    ForEach(repository.getConditions()) { block in
                        HStack {
                            Text(block.name)
                                .foregroundColor(block.color)
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBlocks.append(block)
                        }
                    }
                }
                
                Section(header: Text("Циклы").font(.headline)) {
                    ForEach(repository.getCycles()) { block in
                        HStack {
                            Text(block.name)
                                .foregroundColor(block.color)
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBlocks.append(block)
                        }
                    }
                }
                
                Section(header: Text("Взаимодействия").font(.headline)) {
                    ForEach(repository.getInteractions()) { block in
                        HStack {
                            Text(block.name)
                                .foregroundColor(block.color)
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBlocks.append(block)
                        }
                    }
                }
            }
        }
        .navigationTitle("Блоки")
    }
}

struct BlocksSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BlocksSelectionView(selectedBlocks: .constant([]))
        }
    }
}
