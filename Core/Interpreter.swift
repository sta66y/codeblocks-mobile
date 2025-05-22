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
    
    var result = evaluateExpression(expression: block.operands[0].content, context: context)
    
    for i in 1..<block.operands.count {
        let operand = evaluateExpression(expression: block.operands[i].content, context: context)
        let operatorType = i - 1 < block.operators.count ? block.operators[i - 1] : "+"
        let (operationResult, hasError) = performOperation(operand1: result, operatorType: operatorType, operand2: operand, output: &output)
        if hasError {
            return
        }
        result = operationResult
    }
    
    context[block.variable] = result
    output.append("\(block.variable) = \(result)")
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
    if block.content.hasPrefix("\"") && block.content.hasSuffix("\"") {
        let text = String(block.content.dropFirst().dropLast())
        output.append(text)
    } else {
        let value = evaluateExpression(expression: block.content, context: context)
        output.append(String(value))
    }
}

func evaluateExpression(expression: String, context: Context) -> Int {
    if let value = Int(expression) {
        return value
    } else if let value = context[expression] {
        return value
    } else {
        return 0
    }
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
        default:
            output.append("Ошибка: неизвестный оператор условия \(operatorType)")
            return false
        }
    } else {
        output.append("Ошибка: некорректное условие в блоке")
        return false
    }
}
