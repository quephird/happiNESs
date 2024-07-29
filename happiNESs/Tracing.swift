//
//  Tracing.swift
//  happiNESs
//
//  Created by Danielle Kefford on 7/6/24.
//

func trace(cpu: CPU) -> String {
    var trace = ""
    trace += String(format: "%04X", cpu.programCounter) + "  "

    let byte = cpu.readByte(address: cpu.programCounter)
    trace += String(format: "%02X", byte) + " "
    let opcode = Opcode(rawValue: byte)!
    switch opcode.instructionLength {
    case 1:
        trace += "       "
    case 2:
        trace += String(format: "%02X", cpu.readByte(address: cpu.programCounter + 1))
        trace += "     "
    case 3:
        trace += String(format: "%02X", cpu.readByte(address: cpu.programCounter + 1)) + " "
        trace += String(format: "%02X", cpu.readByte(address: cpu.programCounter + 2))
        trace += "  "
    default:
        fatalError("Tracing halted; opcode with unexpected length encountered!")
    }

    trace += opcode.mnemonic + " "

    let absoluteAddress: UInt16 = switch opcode.addressingMode {
    case .accumulator, .immediate, .implicit: 0
    default: cpu.getAbsoluteAddress(addressingMode: opcode.addressingMode, address: cpu.programCounter + 1)
    }
    let value: UInt8 = switch opcode.addressingMode {
    case .accumulator, .immediate, .implicit:
        0
    default:
        cpu.readByte(address: absoluteAddress)
    }

    let partialAsm: String
    if opcode.instructionLength == 1 {
        partialAsm = switch byte {
        case 0x0A, 0x2A, 0x4A, 0x6A: "A "
        default: ""
        }
    } else if opcode.instructionLength == 2 {
        let nextByte = cpu.readByte(address: cpu.programCounter + 1)

        partialAsm = switch opcode.addressingMode {
        case .immediate: String(format: "$%02X", nextByte)
        case .zeroPage: String(format: "$%02X = %02X", absoluteAddress, value)
        case .zeroPageX: String(format: "$%02X,X @ %02X = %02X", nextByte, absoluteAddress, value)
        case .zeroPageY: String(format: "$%02X,Y @ %02X = %02X", nextByte, absoluteAddress, value)
        case .indirectX: String(format: "($%02X,X) @ %02X = %04X = %02X", nextByte, nextByte &+ cpu.xRegister, absoluteAddress, value)
        case .indirectY: String(format: "($%02X),Y @ %04X = %04X = %02X", nextByte, absoluteAddress &- UInt16(cpu.yRegister), absoluteAddress, value)
        case .relative: String(format: "$%04X", (cpu.programCounter + 2) &+ UInt16(nextByte))
        default: fatalError("Unexpected addressing mode encountered while tracing!")
        }
    } else {
        partialAsm = ""
    }

    trace += partialAsm.padding(toLength: 32, withPad: " ")

    trace += "A:" + String(format: "%02X", cpu.accumulator) + " "
    trace += "X:" + String(format: "%02X", cpu.xRegister) + " "
    trace += "Y:" + String(format: "%02X", cpu.yRegister) + " "
    trace += "P:" + String(format: "%02X", cpu.statusRegister.rawValue) + " "
    trace += "SP:" + String(format: "%02X", cpu.stackPointer)

    return trace
}

extension StringProtocol {
    func padding(toLength length: Int, withPad pad: some StringProtocol, startingAt paddingInsertionIndex: String.Index) -> String {
        padding(toLength: length, withPad: pad, startingAt: paddingInsertionIndex.utf16Offset(in: pad))
    }

    func padding(toLength length: Int, withPad pad: some StringProtocol) -> String {
        padding(toLength: length, withPad: pad, startingAt: pad.startIndex)
    }
}
