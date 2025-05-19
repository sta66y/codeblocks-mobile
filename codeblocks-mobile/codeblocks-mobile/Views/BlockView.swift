import SwiftUI

struct Expression {
    var operand: String
    var operatorType: String
    var isNumber: Bool
}

struct BlockView: View {
    @Binding var block: BlockModel
    @State private var variableInput: String = ""
    @State private var conditionInput: String = ""
    @State private var inputError: String?
    @Binding var allBlocks: [BlockModel]
    @State private var updateTask: DispatchWorkItem?
    @State private var expressions: [Expression] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(block.name)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(block.color)
                .cornerRadius(6)

            switch block.type {
            case .declareVars:
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Переменные (через запятую)", text: $variableInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: variableInput) {
                            updateVariableNames(from: variableInput)
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

            case .operatorCase:
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        let availableVariables = block.variableNames

                        ForEach(expressions.indices, id: \.self) { index in
                            HStack {
                                Picker("", selection: Binding(
                                    get: { expressions[index].operand },
                                    set: { newValue in
                                        expressions[index].operand = newValue
                                        expressions[index].isNumber = newValue == "number"
                                        if expressions[index].isNumber {
                                            if index < block.operands.count {
                                                block.operands[index].content = ""
                                            } else {
                                                block.operands.append(BlockModel(name: "var \(index + 1)", type: .operatorCase, color: block.color, content: ""))
                                            }
                                        }
                                    }
                                )) {
                                    Text("var \(index + 1)").tag("")
                                    ForEach(availableVariables, id: \.self) { variable in
                                        Text(variable).tag(variable)
                                    }
                                    Text("Число").tag("number")
                                }
                                .pickerStyle(MenuPickerStyle())

                                if expressions[index].isNumber {
                                    TextField("Число", text: Binding(
                                        get: { index < block.operands.count ? block.operands[index].content : "" },
                                        set: { newValue in
                                            if index < block.operands.count {
                                                block.operands[index].content = newValue
                                            } else {
                                                block.operands.append(BlockModel(name: "var \(index + 1)", type: .operatorCase, color: block.color, content: newValue))
                                            }
                                        }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                } else {
                                    Text(expressions[index].operand.isEmpty ? "" : expressions[index].operand)
                                }

                                if index < expressions.count - 1 {
                                    Picker("", selection: Binding(
                                        get: { expressions[index].operatorType },
                                        set: { newValue in
                                            expressions[index].operatorType = newValue
                                        }
                                    )) {
                                        Text("=").tag("=")
                                        Text("+").tag("+")
                                        Text("-").tag("-")
                                        Text("*").tag("*")
                                        Text("/").tag("/")
                                        Text("%").tag("%")
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                            }
                        }

                        Button(action: {
                            expressions.append(Expression(operand: "", operatorType: "+", isNumber: false))
                        }) {
                            Text("Добавить операнд")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(height: 50)
                .onAppear {
                    if expressions.isEmpty {
                        expressions = block.operands.enumerated().map { index, operand in
                            Expression(
                                operand: operand.content.isEmpty ? "" : operand.content,
                                operatorType: index < block.operands.count - 1 ? block.operands[index].content : "+",
                                isNumber: Double(operand.content) != nil
                            )
                        }
                        if expressions.isEmpty {
                            expressions.append(Expression(operand: "", operatorType: "+", isNumber: false))
                        }
                    }
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
