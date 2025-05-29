import SwiftUI

struct Expression: Equatable {
    var operand: String
    var operatorType: String
    var isNumber: Bool
    var hasLeftParenthesis: Bool
    var hasRightParenthesis: Bool
    
    static func == (lhs: Expression, rhs: Expression) -> Bool {
        lhs.operand == rhs.operand &&
        lhs.operatorType == rhs.operatorType &&
        lhs.isNumber == rhs.isNumber &&
        lhs.hasLeftParenthesis == rhs.hasLeftParenthesis &&
        lhs.hasRightParenthesis == rhs.hasRightParenthesis
    }
}

struct ConditionExpression: Equatable {
    var leftOperand: String
    var operatorType: String
    var rightOperand: String
    var leftIsNumber: Bool
    var rightIsNumber: Bool
    
    static func == (lhs: ConditionExpression, rhs: ConditionExpression) -> Bool {
        lhs.leftOperand == rhs.leftOperand &&
        lhs.operatorType == rhs.operatorType &&
        lhs.rightOperand == rhs.rightOperand &&
        lhs.leftIsNumber == rhs.leftIsNumber &&
        lhs.rightIsNumber == rhs.rightIsNumber
    }
}

struct OperandRowView: View {
    @Binding var expression: Expression
    @Binding var operandContent: String
    let availableVariables: [String]
    let isLast: Bool
    let blockColor: Color
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button(action: { expression.hasLeftParenthesis.toggle() }) {
                    Text("(")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(expression.hasLeftParenthesis ? .white : .gray)
                        .frame(width: 24, height: 24)
                        .background(expression.hasLeftParenthesis ? blockColor : Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }

                Picker("", selection: Binding(
                    get: { expression.operand },
                    set: { newValue in
                        expression.operand = newValue
                        expression.isNumber = newValue == "number"
                        operandContent = newValue == "number" ? "" : newValue
                        validateNumberInput()
                    }
                )) {
                    ForEach(availableVariables, id: \.self) { variable in
                        Text(variable).tag(variable)
                    }
                    Text("Число").tag("number")
                }
                .pickerStyle(.menu)
                .tint(blockColor)

                if expression.isNumber {
                    TextField("Число", text: $operandContent, onEditingChanged: { _ in validateNumberInput() })
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.numberPad)
                        .frame(maxWidth: 100)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.1)))
                }

                Button(action: {
                    if expression.hasLeftParenthesis {
                        expression.hasRightParenthesis.toggle()
                    }
                }) {
                    Text(")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(expression.hasRightParenthesis && expression.hasLeftParenthesis ? .white : .gray)
                        .frame(width: 24, height: 24)
                        .background(expression.hasRightParenthesis && expression.hasLeftParenthesis ? blockColor : Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .disabled(!expression.hasLeftParenthesis)

                if !isLast {
                    Picker("", selection: $expression.operatorType) {
                        Text("+").tag("+")
                        Text("-").tag("-")
                        Text("*").tag("*")
                        Text("/").tag("/")
                        Text("%").tag("%")
                    }
                    .pickerStyle(.menu)
                    .tint(blockColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.05)))

            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal, 8)
            }
        }
    }

    private func validateNumberInput() {
        if expression.isNumber && !operandContent.isEmpty {
            if Double(operandContent) == nil {
                error = "Введите число"
            } else {
                error = nil
            }
        } else {
            error = nil
        }
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
            .sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(block.name)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(block.color)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            switch block.type {
            case .declareVars:
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Переменные (через запятую)", text: $variableInput)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.1)))
                        .onChange(of: variableInput) { debounceVariableUpdate() }
                        .onAppear { variableInput = block.variableNames.joined(separator: ", ") }
                    if let error = inputError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 8)
                    }
                }

            case .assign:
                HStack(spacing: 8) {
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
                        .pickerStyle(.menu)
                        .tint(block.color)
                        Text("=")
                        TextField("Выражение", text: $block.content)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .disabled(availableVariables.isEmpty)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.05)))

            case .operatorCase:
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        if !availableVariables.isEmpty {
                            Picker("", selection: $block.variable) {
                                Text("Выберите переменную").tag("")
                                ForEach(availableVariables, id: \.self) { variable in
                                    Text(variable).tag(variable)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(block.color)
                            Text("=")
                        } else {
                            Text("Нет доступных переменных")
                                .foregroundColor(.gray)
                        }

                        ForEach(expressions.indices, id: \.self) { index in
                            OperandRowView(
                                expression: $expressions[index],
                                operandContent: Binding(
                                    get: { index < block.operands.count ? block.operands[index].content : "" },
                                    set: { newValue in
                                        if index < block.operands.count {
                                            block.operands[index].content = newValue
                                        }
                                    }
                                ),
                                availableVariables: availableVariables,
                                isLast: index == expressions.count - 1,
                                blockColor: block.color
                            )
                        }

                        Button(action: {
                            let defaultOperand = availableVariables.first ?? ""
                            expressions.append(Expression(
                                operand: defaultOperand,
                                operatorType: "+",
                                isNumber: false,
                                hasLeftParenthesis: false,
                                hasRightParenthesis: false
                            ))
                            block.operands.append(BlockModel(
                                name: "",
                                type: .operatorCase,
                                color: block.color,
                                content: defaultOperand
                            ))
                        }) {
                            Text("Добавить операнд")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 80)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.05)))
                .onAppear {
                    if expressions.isEmpty {
                        expressions = block.operands.enumerated().map { index, operand in
                            let content = operand.content
                            let hasLeft = content.hasPrefix("(")
                            let hasRight = content.hasSuffix(")")
                            let cleanContent = content.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                            return Expression(
                                operand: cleanContent.isEmpty ? availableVariables.first ?? "" : cleanContent,
                                operatorType: index < block.operators.count ? block.operators[index] : "+",
                                isNumber: Double(cleanContent) != nil,
                                hasLeftParenthesis: hasLeft,
                                hasRightParenthesis: hasRight
                            )
                        }
                        if expressions.isEmpty {
                            let defaultOperand = availableVariables.first ?? ""
                            expressions.append(Expression(
                                operand: defaultOperand,
                                operatorType: "+",
                                isNumber: false,
                                hasLeftParenthesis: false,
                                hasRightParenthesis: false
                            ))
                            block.operands.append(BlockModel(
                                name: "",
                                type: .operatorCase,
                                color: block.color,
                                content: defaultOperand
                            ))
                        }
                    }
                }
                .onChange(of: expressions) { _, newExpressions in
                    block.operators = newExpressions.dropLast().map { $0.operatorType }
                    block.operands = newExpressions.enumerated().map { index, expr in
                        var content = expr.isNumber ? (expr.operand == "number" ? "" : expr.operand) : expr.operand
                        if expr.hasLeftParenthesis { content = "(" + content }
                        if expr.hasRightParenthesis { content = content + ")" }
                        return BlockModel(
                            name: "",
                            type: .operatorCase,
                            color: block.color,
                            content: content
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
                    .pickerStyle(.menu)
                    .tint(block.color)

                    if conditionIf.leftIsNumber {
                        TextField("Число", text: $leftNumberInputIf)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 100)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.1)))
                    }

                    Picker("", selection: $conditionIf.operatorType) {
                        Text(">").tag(">")
                        Text("<").tag("<")
                        Text("==").tag("==")
                        Text("!=").tag("!=")
                        Text(">=").tag(">=")
                        Text("<=").tag("<=")
                    }
                    .pickerStyle(.menu)
                    .tint(block.color)

                    Picker("", selection: Binding(
                        get: { conditionIf.rightOperand },
                        set: { conditionIf.rightOperand = $0; conditionIf.rightIsNumber = $0 == "number" }
                    )) {
                        ForEach(availableVariables, id: \.self) { variable in
                            Text(variable).tag(variable)
                        }
                        Text("Число").tag("number")
                    }
                    .pickerStyle(.menu)
                    .tint(block.color)

                    if conditionIf.rightIsNumber {
                        TextField("Число", text: $rightNumberInputIf)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 100)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.05)))
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
                            leftIsNumber: Double(components[0]) != nil,
                            rightIsNumber: Double(components[2]) != nil
                        )
                        leftNumberInputIf = conditionIf.leftIsNumber ? components[0] : ""
                        rightNumberInputIf = conditionIf.rightIsNumber ? components[2] : ""
                    }
                }

            case .elseCase:
                EmptyView()
              
            case .printCase:
                TextField("Что вывести", text: $block.content)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.1)))
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
            if varName.contains(" ") {
                inputError = "Имя переменной не должно содержать пробелы"
                return
            }
        }
        inputError = nil
        block.variableNames = newVars
    }

    private func debounceVariableUpdate() {
        variableUpdateTask?.cancel()
        let task = DispatchWorkItem { self.updateVariableNames(from: self.variableInput) }
        variableUpdateTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }

    private func debounceConditionUpdate() {
        updateTask?.cancel()
        let task = DispatchWorkItem {
            if self.conditionInput != self.block.content {
                self.block.content = self.conditionInput
            }
        }
        updateTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }
}
