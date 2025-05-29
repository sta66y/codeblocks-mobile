import Foundation
import SwiftUI

typealias Context = [String: Int]

func interpret(blocks: [BlockModel], context: inout Context) -> [String] {
    var output: [String] = []
    for block in blocks {
        switch block.type {
        case .declareVars:
            handleDeclareVars(block: block, context: &context, output: &output)
        case .assign:
            handleAssign(block: block, context: &context, output: &output)
        case .operatorCase:
            handleOperatorCase(block: block, context: &context, output: &output)
        case .ifCase:
            handleIfCase(block: block, context: &context, output: &output)
        case .printCase:
            handlePrintCase(block: block, context: context, output: &output)
        default:
            break
        }
    }
    return output
}

func handleDeclareVars(block: BlockModel, context: inout Context, output: inout [String]) {
    for varName in block.variableNames {
        context[varName] = 0
    }
    let childOutput = interpret(blocks: block.children, context: &context)
    output.append(contentsOf: childOutput)
}

func handleAssign(block: BlockModel, context: inout Context, output: inout [String]) {
    let value = evaluateExpression(expression: block.content, context: context)
    context[block.variable] = value
    output.append("\(block.variable) = \(value)")
}

func handleOperatorCase(block: BlockModel, context: inout Context, output: inout [String]) {
    guard !block.variable.isEmpty else {
        output.append("Ошибка: не выбрана переменная для присваивания")
        return
    }
    
    guard !block.operands.isEmpty else {
        output.append("Ошибка: нет операндов в арифметическом выражении")
        return
    }
    
    let result = evaluateOperatorExpression(operands: block.operands, operators: block.operators, context: context, output: &output)
    if result.hasError {
        return
    }
    
    context[block.variable] = result.value
    output.append("\(block.variable) = \(result.value)")
}

func handleIfCase(block: BlockModel, context: inout Context, output: inout [String]) {
    let condition = evaluateCondition(condition: block.content, context: context, output: &output)
    output.append("Условие \(block.content): \(condition)")
    if condition {
        let childOutput = interpret(blocks: block.children, context: &context)
        output.append(contentsOf: childOutput)
    }
}

func handlePrintCase(block: BlockModel, context: Context, output: inout [String]) {
    let quotePairs: [(open: Character, close: Character)] = [
        ("\"", "\""),
        ("'", "'"),
        ("“", "”"),
        ("‘", "’")
    ]
    
    for (openQuote, closeQuote) in quotePairs {
        if block.content.hasPrefix(String(openQuote)) && block.content.hasSuffix(String(closeQuote)) {
            let startIndex = block.content.index(block.content.startIndex, offsetBy: 1)
            let endIndex = block.content.index(block.content.endIndex, offsetBy: -1)
            let text = String(block.content[startIndex..<endIndex])
            output.append(text)
            return
        }
    }
    
    let value = evaluateExpression(expression: block.content, context: context)
    if context[block.content] != nil {
        output.append("\(block.content) = \(value)")
    } else if Int(block.content) != nil {
        output.append(String(value))
    } else {
        output.append("Ошибка: переменная '\(block.content)' не определена")
    }
}

func evaluateExpression(expression: String, context: Context) -> Int {
    let cleanExpression = expression.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
    if let value = Int(cleanExpression) {
        return value
    } else if let value = context[cleanExpression] {
        return value
    } else {
        return 0
    }
}

func evaluateOperatorExpression(operands: [BlockModel], operators: [String], context: Context, output: inout [String]) -> (value: Int, hasError: Bool) {
    var values: [Int] = []
    var ops = operators
    var parenGroups: [(start: Int, end: Int)] = []
    var currentIndex = 0
    

    while currentIndex < operands.count {
        let content = operands[currentIndex].content
        if content.hasPrefix("(") {
            var openCount = 1
            var endIndex = currentIndex + 1
            while endIndex < operands.count && openCount > 0 {
                let nextContent = operands[endIndex].content
                if nextContent.hasPrefix("(") {
                    openCount += 1
                }
                if nextContent.hasSuffix(")") {
                    openCount -= 1
                }
                endIndex += 1
            }
            if openCount == 0 && endIndex <= operands.count {
                parenGroups.append((start: currentIndex, end: endIndex - 1))
                currentIndex = endIndex
            } else {
                output.append("Ошибка: несбалансированные скобки")
                return (0, true)
            }
        } else {
            values.append(evaluateExpression(expression: content, context: context))
            currentIndex += 1
        }
    }
    
    if ops.isEmpty && values.count == 1 && parenGroups.isEmpty {
        return (values[0], false)
    }
    
    if ops.count < values.count + parenGroups.count - 1 {
        while ops.count < values.count + parenGroups.count - 1 {
            ops.append("+")
        }
    } else if ops.count > values.count + parenGroups.count - 1 {
        ops = Array(ops.prefix(values.count + parenGroups.count - 1))
    }
    
    let precedence: [String: Int] = [
        "+": 1, "Сложить": 1,
        "-": 1, "Вычесть": 1,
        "*": 2, "Умножить": 2,
        "/": 2, "Разделить": 2,
        "%": 2
    ]
    
    var valueStack: [Int] = []
    var opStack: [String] = []
    var operandIndex = 0
    var operatorIndex = 0
    var parenIndex = 0
    
    for i in 0..<(values.count + parenGroups.count) {
        if parenIndex < parenGroups.count && parenGroups[parenIndex].start == i {
            let group = parenGroups[parenIndex]
            let subOperands = Array(operands[group.start...group.end]).map { BlockModel(
                name: $0.name,
                type: $0.type,
                color: $0.color,
                content: $0.content.trimmingCharacters(in: CharacterSet(charactersIn: "()")),
                children: $0.children,
                variableNames: $0.variableNames,
                variable: $0.variable,
                operands: $0.operands,
                operators: $0.operators
            )}
            let subOperators = Array(ops[operatorIndex..<(operatorIndex + group.end - group.start)])
            operatorIndex += group.end - group.start
            
            let subResult = evaluateOperatorExpression(operands: subOperands, operators: subOperators, context: context, output: &output)
            if subResult.hasError {
                return (0, true)
            }
            valueStack.append(subResult.value)
            parenIndex += 1
        } else {
            valueStack.append(values[operandIndex])
            operandIndex += 1
        }
        
        if operatorIndex < ops.count {
            let currentOp = ops[operatorIndex]
            operatorIndex += 1
            
            guard precedence[currentOp] != nil else {
                output.append("Ошибка: неизвестный оператор \(currentOp)")
                return (0, true)
            }
            
            while !opStack.isEmpty,
                  let lastOp = opStack.last,
                  let lastPrecedence = precedence[lastOp],
                  let currentPrecedence = precedence[currentOp],
                  lastPrecedence >= currentPrecedence {
                guard let op = opStack.popLast(),
                      let operand2 = valueStack.popLast(),
                      let operand1 = valueStack.popLast() else {
                    output.append("Ошибка: некорректное выражение")
                    return (0, true)
                }
                let (result, hasError) = performOperation(operand1: operand1, operatorType: op, operand2: operand2, output: &output)
                if hasError {
                    return (0, true)
                }
                valueStack.append(result)
            }
            
            opStack.append(currentOp)
        }
    }
    
    while !opStack.isEmpty {
        guard let op = opStack.popLast(),
              let operand2 = valueStack.popLast(),
              let operand1 = valueStack.popLast() else {
            output.append("Ошибка: некорректное выражение")
            return (0, true)
        }
        let (result, hasError) = performOperation(operand1: operand1, operatorType: op, operand2: operand2, output: &output)
        if hasError {
            return (0, true)
        }
        valueStack.append(result)
    }
    
    guard let finalResult = valueStack.first, valueStack.count == 1 else {
        output.append("Ошибка: некорректное выражение")
        return (0, true)
    }
    
    return (finalResult, false)
}

func performOperation(operand1: Int, operatorType: String, operand2: Int, output: inout [String]) -> (result: Int, hasError: Bool) {
    switch operatorType {
    case "+", "Сложить":
        return (operand1 + operand2, false)
    case "-", "Вычесть":
        return (operand1 - operand2, false)
    case "*", "Умножить":
        return (operand1 * operand2, false)
    case "/", "Разделить":
        if operand2 != 0 {
            return (operand1 / operand2, false)
        } else {
            output.append("Ошибка: деление на ноль")
            return (0, true)
        }
    case "%":
        if operand2 != 0 {
            return (operand1 % operand2, false)
        } else {
            output.append("Ошибка: деление на ноль")
            return (0, true)
        }
    default:
        output.append("Ошибка: неизвестный оператор \(operatorType)")
        return (0, true)
    }
}

func evaluateCondition(condition: String, context: Context, output: inout [String]) -> Bool {
    let components = condition.split(separator: " ").map { String($0) }
    if components.count == 3 {
        let left = evaluateExpression(expression: components[0], context: context)
        let operatorType = components[1]
        let right = evaluateExpression(expression: components[2], context: context)
        switch operatorType {
        case ">": return left > right
        case "<": return left < right
        case "==": return left == right
        case "!=": return left != right
        case ">=": return left >= right
        case "<=": return left <= right
        default:
            output.append("Ошибка: неизвестный оператор условия \(operatorType)")
            return false
        }
    } else {
        output.append("Ошибка: некорректное условие в блоке")
        return false
    }
}
