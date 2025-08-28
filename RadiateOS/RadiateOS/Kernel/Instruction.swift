import Foundation

// Traditional CPU Instruction
struct Instruction {
    let opcode: TraditionalOpcode
    let operands: [Any]
    
    func execute() -> Any? {
        switch opcode {
        case .add:
            return executeAdd()
        case .sub:
            return executeSub()
        case .mul:
            return executeMul()
        case .div:
            return executeDiv()
        case .mov:
            return executeMove()
        case .jmp:
            return executeJump()
        case .cmp:
            return executeCompare()
        case .push:
            return executePush()
        case .pop:
            return executePop()
        case .call:
            return executeCall()
        case .ret:
            return executeReturn()
        case .nop:
            return nil
        }
    }
    
    private func executeAdd() -> Any? {
        guard operands.count >= 2,
              let a = operands[0] as? Int,
              let b = operands[1] as? Int else { return nil }
        return a + b
    }
    
    private func executeSub() -> Any? {
        guard operands.count >= 2,
              let a = operands[0] as? Int,
              let b = operands[1] as? Int else { return nil }
        return a - b
    }
    
    private func executeMul() -> Any? {
        guard operands.count >= 2,
              let a = operands[0] as? Int,
              let b = operands[1] as? Int else { return nil }
        return a * b
    }
    
    private func executeDiv() -> Any? {
        guard operands.count >= 2,
              let a = operands[0] as? Int,
              let b = operands[1] as? Int,
              b != 0 else { return nil }
        return a / b
    }
    
    private func executeMove() -> Any? {
        guard !operands.isEmpty else { return nil }
        return operands[0]
    }
    
    private func executeJump() -> Any? {
        guard !operands.isEmpty else { return nil }
        return operands[0] // Return jump address
    }
    
    private func executeCompare() -> Any? {
        guard operands.count >= 2,
              let a = operands[0] as? Int,
              let b = operands[1] as? Int else { return nil }
        return a == b
    }
    
    private func executePush() -> Any? {
        guard !operands.isEmpty else { return nil }
        return operands[0]
    }
    
    private func executePop() -> Any? {
        return nil // Stack operation handled elsewhere
    }
    
    private func executeCall() -> Any? {
        guard !operands.isEmpty else { return nil }
        return operands[0] // Return function address
    }
    
    private func executeReturn() -> Any? {
        return nil // Return handled by call stack
    }
}

enum TraditionalOpcode {
    case add, sub, mul, div
    case mov, jmp, cmp
    case push, pop
    case call, ret
    case nop
}