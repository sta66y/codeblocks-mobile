import SwiftUI

struct BlockView: View {
    @Binding var block: BlockModel
    @State private var variableInput: String = ""
    @State private var conditionInput: String = ""
    @State private var inputError: String?
    @Binding var allBlocks: [BlockModel]
    @State private var updateTask: DispatchWorkItem?

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
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Переменные (через запятую)", text: $variableInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: variableInput) { newValue in
                            updateVariableNames(from: newValue)
                        }
                        .onAppear {
                            variableInput = block.variableNames.joined(separator: ", ")
                        }

                    if let error = inputError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

            case .assign:
                HStack {
                    let assignedVariables = allBlocks
                        .filter { $0.type == .assign && $0.id != block.id && !$0.variable.isEmpty }
                        .map { $0.variable }
                    let availableVariables = block.variableNames.filter { !assignedVariables.contains($0) }

                    if block.variableNames.isEmpty {
                        Text("Нет доступных переменных")
                            .foregroundColor(.gray)
                    } else {
                        Picker("", selection: $block.variable) {
                            Text("Выберите переменную").tag("")
                            ForEach(availableVariables, id: \.self) { variable in
                                Text(variable).tag(variable)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    Text("=")
                    TextField("Выражение", text: $block.content)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(block.variableNames.isEmpty || availableVariables.isEmpty)
                }

            case .add, .subtract, .multiply, .divide, .modulo:
                HStack {
                    TextField("Операнд 1", text: Binding(
                        get: { block.operands.first?.content ?? "" },
                        set: { newValue in
                            if block.operands.isEmpty {
                                block.operands.append(BlockModel(name: "Операнд 1", type: block.type, color: block.color, content: newValue))
                            } else {
                                block.operands[0].content = newValue
                            }
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text(block.name)
                    TextField("Операнд 2", text: Binding(
                        get: { block.operands.dropFirst().first?.content ?? "" },
                        set: { newValue in
                            if block.operands.count < 2 {
                                block.operands.append(BlockModel(name: "Операнд 2", type: block.type, color: block.color, content: newValue))
                            } else {
                                block.operands[1].content = newValue
                            }
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }

            case .ifCase, .whileCase:
                TextField("Условие", text: $conditionInput, onEditingChanged: { isEditing in
                    if !isEditing {
                        debounceConditionUpdate()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onAppear {
                    conditionInput = block.content
                }

            case .forCase:
                ForBlockView(content: $conditionInput)
                    .onAppear {
                        conditionInput = block.content
                    }
                    .onChange(of: conditionInput) { oldValue, newValue in
                        debounceConditionUpdate()
                    }

            case .printCase:
                TextField("Что вывести", text: $block.content)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.vertical, 4)
    }

    private func updateVariableNames(from input: String) {
        let newVars = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if newVars.isEmpty {
            inputError = "Введите хотя бы одну переменную"
        } else if Set(newVars).count != newVars.count {
            inputError = "Переменные не должны повторяться"
        } else {
            inputError = nil
            if newVars != block.variableNames {
                block.variableNames = newVars
            }
        }
    }

    private func debounceConditionUpdate() {
        updateTask?.cancel()

        let task = DispatchWorkItem {
            if conditionInput != block.content {
                block.content = conditionInput
            }
        }
        updateTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }
}
