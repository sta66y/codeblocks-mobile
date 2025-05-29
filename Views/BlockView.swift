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

struct ConditionExpression: Equatable {
    var leftOperand: String
    var operatorType: String
    var rightOperand: String
    var leftIsNumber: Bool
    var rightIsNumber: Bool
    
    static func == (lhs: ConditionExpression, rhs: ConditionExpression) -> Bool {
        return lhs.leftOperand == rhs.leftOperand &&
               lhs.operatorType == rhs.operatorType &&
               lhs.rightOperand == rhs.rightOperand &&
               lhs.leftIsNumber == rhs.leftIsNumber &&
               lhs.rightIsNumber == rhs.rightIsNumber
    }
}

struct BlockView: View {
    @Binding var block: BlockModel
    @State private var variableInput: String = ""
    @State private var conditionInput: String = ""
    @State private var leftNumberInputIf: String = ""
    @State private var rightNumberInputIf: String = ""
    @State private var inputError: String?
    @Binding var allBlocks: [BlockModel]
    let index: Int
    @State private var updateTask: DispatchWorkItem?
    @State private var variableUpdateTask: DispatchWorkItem?
    @State private var expressions: [Expression] = []
    @State private var conditionIf: ConditionExpression = ConditionExpression(
        leftOperand: "",
        operatorType: ">",
        rightOperand: "",
        leftIsNumber: false,
        rightIsNumber: false
    )

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

            case .ifCase, .elseIfCase:
                HStack(spacing: 10) {
                    Picker("", selection: Binding(
                        get: { conditionIf.leftOperand },
                        set: { conditionIf.leftOperand = $0; conditionIf.leftIsNumber = $0 == "number" }
                    )) {
                        ForEach(availableVariables, id: \.self) { variable in
                            Text(variable).tag(variable)
                        }
                        Text("Число").tag("number")
                    }
                    .pickerStyle(MenuPickerStyle())

                    if conditionIf.leftIsNumber {
                        TextField("Число", text: $leftNumberInputIf)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Picker("", selection: $conditionIf.operatorType) {
                        Text(">").tag(">")
                        Text("<").tag("<")
                        Text("==").tag("==")
                        Text("!=").tag("!=")
                        Text(">=").tag(">=")
                        Text("<=").tag("<=")
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("", selection: Binding(
                        get: { conditionIf.rightOperand },
                        set: { conditionIf.rightOperand = $0; conditionIf.rightIsNumber = $0 == "number" }
                    )) {
                        ForEach(availableVariables, id: \.self) { variable in
                            Text(variable).tag(variable)
                        }
                        Text("Число").tag("number")
                    }
                    .pickerStyle(MenuPickerStyle())

                    if conditionIf.rightIsNumber {
                        TextField("Число", text: $rightNumberInputIf)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .onChange(of: conditionIf) { _, newCondition in
                    let left = newCondition.leftIsNumber ? (leftNumberInputIf.isEmpty ? "0" : leftNumberInputIf) : newCondition.leftOperand
                    let right = newCondition.rightIsNumber ? (rightNumberInputIf.isEmpty ? "0" : rightNumberInputIf) : newCondition.rightOperand
                    block.content = "\(left) \(newCondition.operatorType) \(right)"
                }
                .onChange(of: leftNumberInputIf) { _, _ in
                    let left = conditionIf.leftIsNumber ? (leftNumberInputIf.isEmpty ? "0" : leftNumberInputIf) : conditionIf.leftOperand
                    let right = conditionIf.rightIsNumber ? (rightNumberInputIf.isEmpty ? "0" : rightNumberInputIf) : conditionIf.rightOperand
                    block.content = "\(left) \(conditionIf.operatorType) \(right)"
                }
                .onChange(of: rightNumberInputIf) { _, _ in
                    let left = conditionIf.leftIsNumber ? (leftNumberInputIf.isEmpty ? "0" : leftNumberInputIf) : conditionIf.leftOperand
                    let right = conditionIf.rightIsNumber ? (rightNumberInputIf.isEmpty ? "0" : rightNumberInputIf) : conditionIf.rightOperand
                    block.content = "\(left) \(conditionIf.operatorType) \(right)"
                }
                .onAppear {
                    let components = block.content.split(separator: " ").map { String($0) }
                    if components.count == 3 {
                        conditionIf = ConditionExpression(
                            leftOperand: components[0],
                            operatorType: components[1],
                            rightOperand: components[2],
                            leftIsNumber: Int(components[0]) != nil,
                            rightIsNumber: Int(components[2]) != nil
                        )
                        leftNumberInputIf = conditionIf.leftIsNumber ? components[0] : ""
                        rightNumberInputIf = conditionIf.rightIsNumber ? components[2] : ""
                    }
                }

            case .elseCase:
                EmptyView()

            case .whileCase:
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
            return
        }
        
        if Set(newVars).count != newVars.count {
            inputError = "Переменные не должны повторяться"
            return
        }
        
        for varName in newVars {
            if let firstChar = varName.first, !firstChar.isLetter {
                inputError = "Имя переменной должно начинаться с буквы"
                return
            }
        }
        
        inputError = nil
        if newVars != block.variableNames {
            block.variableNames = newVars
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
            if variableInput != block.content {
                block.content = variableInput
            }
        }
        updateTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }
}
