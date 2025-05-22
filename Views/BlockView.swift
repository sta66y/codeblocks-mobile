import SwiftUI

struct Expression: Equatable {
    var operand: String
    var operatorType: String
    var isNumber: Bool
    
    static func == (lhs: Expression, rhs: Expression) -> Bool {
        return lhs.operand == rhs.operand &&
               lhs.operatorType == rhs.operatorType &&
               lhs.isNumber == rhs.isNumber
    }
}

struct BlockView: View {
    @Binding var block: BlockModel
    @State private var variableInput: String = ""
    @State private var conditionInput: String = ""
    @State private var inputError: String?
    @Binding var allBlocks: [BlockModel]
    let index: Int
    @State private var updateTask: DispatchWorkItem?
    @State private var variableUpdateTask: DispatchWorkItem?
    @State private var expressions: [Expression] = []

    private var availableVariables: [String] {
        Array(Set(allBlocks.prefix(upTo: index)
            .filter { $0.type == .declareVars }
            .flatMap { $0.variableNames }))
    }

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
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: variableInput) {
                            debounceVariableUpdate()
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
                    if availableVariables.isEmpty {
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
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(availableVariables.isEmpty)
                }

            case .operatorCase:
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        if !availableVariables.isEmpty {
                            Picker("", selection: $block.variable) {
                                Text("Выберите переменную").tag("")
                                ForEach(availableVariables, id: \.self) { variable in
                                    Text(variable).tag(variable)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            Text("=")
                        } else {
                            Text("Нет доступных переменных").foregroundColor(.gray)
                        }

                        ForEach(expressions.indices, id: \.self) { index in
                            HStack {
                                Picker("", selection: Binding(
                                    get: { expressions[index].operand },
                                    set: { newValue in
                                        expressions[index].operand = newValue
                                        expressions[index].isNumber = newValue == "number"

                                        if index < block.operands.count {
                                            block.operands[index].content = newValue == "number" ? "" : newValue
                                        } else {
                                            block.operands.append(BlockModel(
                                                name: "",
                                                type: .operatorCase,
                                                color: block.color,
                                                content: newValue == "number" ? "" : newValue
                                            ))
                                        }
                                    }
                                )) {
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
                                            }
                                        }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                }

                                if index < expressions.count - 1 {
                                    Picker("", selection: Binding(
                                        get: { expressions[index].operatorType },
                                        set: { expressions[index].operatorType = $0 }
                                    )) {
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
                            expressions.append(Expression(
                                operand: availableVariables.first ?? "",
                                operatorType: "+",
                                isNumber: false
                            ))
                            block.operands.append(BlockModel(name: "", type: .operatorCase, color: block.color, content: availableVariables.first ?? ""))
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
                                operand: operand.content,
                                operatorType: index < block.operators.count ? block.operators[index] : "+",
                                isNumber: Double(operand.content) != nil
                            )
                        }

                        if expressions.isEmpty {
                            let defaultOperand = availableVariables.first ?? ""
                            expressions.append(Expression(operand: defaultOperand, operatorType: "+", isNumber: false))
                            block.operands.append(BlockModel(name: "", type: .operatorCase, color: block.color, content: defaultOperand))
                        }
                    }
                }
                .onChange(of: expressions) { _, newExpressions in
                    // Синхронизируем operators и operands с expressions
                    block.operators = newExpressions.dropLast().map { $0.operatorType }
                    block.operands = newExpressions.enumerated().map { index, expr in
                        BlockModel(
                            name: "",
                            type: .operatorCase,
                            color: block.color,
                            content: expr.isNumber ? (expr.operand == "number" ? "" : expr.operand) : expr.operand
                        )
                    }
                }


            case .ifCase, .whileCase:
                TextField("Условие", text: $conditionInput, onEditingChanged: { isEditing in
                    if !isEditing {
                        debounceConditionUpdate()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onAppear {
                    conditionInput = block.content
                }

            case .forCase:
                ForBlockView(content: $conditionInput)
                    .onAppear {
                        conditionInput = block.content
                    }
                    .onChange(of: conditionInput) { _, newValue in
                        debounceConditionUpdate()
                    }

            case .printCase:
                TextField("Что вывести", text: $block.content)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(.vertical, 4)
    }

    private func updateVariableNames(from input: String) {
        let newVars = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
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

    private func debounceVariableUpdate() {
        variableUpdateTask?.cancel()
        let task = DispatchWorkItem {
            self.updateVariableNames(from: self.variableInput)
        }
        variableUpdateTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
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
