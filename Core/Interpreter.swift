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
    //kolyan, tebe
}

func handleIfCase(block: BlockModel, context: inout Context, output: inout [String]) {
    let condition = evaluateCondition(condition: block.content, context: context)
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

func performOperation(operand1: Int, operatorType: String, operand2: Int) -> Int {
    switch operatorType {
    case "Сложить": return operand1 + operand2
    case "Вычесть": return operand1 - operand2
    case "Умножить": return operand1 * operand2
    case "Разделить":
        if operand2 != 0 {
            return operand1 / operand2
        } else {
            print("Ошибка: деление на ноль")
            return 0
        }
    default:
        print("Ошибка: неизвестный оператор \(operatorType)")
        return 0
    }
}

func evaluateCondition(condition: String, context: Context) -> Bool {
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
            print("Ошибка: неизвестный оператор условия \(operatorType)")
            return false
        }
    } else {
        print("Ошибка: некорректное условие в блоке")
        return false
    }
}
