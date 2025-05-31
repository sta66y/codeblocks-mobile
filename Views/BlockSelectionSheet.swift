import SwiftUI

struct BlockSelectionSheet: View {
    let onSelect: (BlockModel) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Переменные").font(.headline)) {
                    ForEach(BlockRepository.variables) { block in
                        Button(action: {
                            onSelect(block)
                            dismiss()
                        }) {
                            Text(block.name)
                                .foregroundColor(block.color)
                        }
                    }
                }
                
                Section(header: Text("Арифметика").font(.headline)) {
                    ForEach(BlockRepository.arithmetic) { block in
                        Button(action: {
                            onSelect(block)
                            dismiss()
                        }) {
                            Text(block.name)
                                .foregroundColor(block.color)
                        }
                    }
                }
                
                Section(header: Text("Условия").font(.headline)) {
                    ForEach(BlockRepository.conditions) { block in
                        Button(action: {
                            onSelect(block)
                            dismiss()
                        }) {
                            Text(block.name)
                                .foregroundColor(block.color)
                        }
                    }
                }
                
                Section(header: Text("Взаимодействия").font(.headline)) {
                    ForEach(BlockRepository.interactions) { block in
                        Button(action: {
                            onSelect(block)
                            dismiss()
                        }) {
                            Text(block.name)
                                .foregroundColor(block.color)
                        }
                    }
                }
            }
            .navigationTitle("Выберите блок")
            .navigationBarItems(trailing: Button("Отмена") {
                dismiss()
            })
        }
    }
}
