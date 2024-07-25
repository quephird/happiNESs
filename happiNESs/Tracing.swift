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
    case .immediate, .implicit: 0
    default: cpu.getAbsoluteAddress(addressingMode: opcode.addressingMode, address: cpu.programCounter + 1)
    }
    let value: UInt8 = switch opcode.addressingMode {
    case .immediate, .implicit:
        0
    default:
        cpu.readByte(address: absoluteAddress)
    }

    let address = cpu.programCounter + 1
    let partialAsm = switch opcode.instructionLength {
    case 1:
        switch byte {
        case 0x0A, 0x2A, 0x4A, 0x6A: "A "
        default: ""
        }
    case 2:
        switch opcode.addressingMode {
        case .immediate: String(format: "$%02X", address)
        case .zeroPage: String(format: "$%02X = %02X", absoluteAddress, value)
        case .zeroPageX: String(format: "$%02X,X @ %02X = %02X", address, absoluteAddress, value)
        case .zeroPageY: String(format: "$%02X,Y @ %02X = %02X", address, absoluteAddress, value)
        case .indirectX: String(format: "($%02X,X) @ %02X = %04X = %02X", address, address &+ UInt16(cpu.xRegister), absoluteAddress, value)
        case .indirectY: String(format: "($%02X),Y @ %04X = %04X = %02X", address, address &- UInt16(cpu.yRegister), absoluteAddress, value)
//        case .relative: String(format: "$%04X", (address + 1) &+ ((address as i8) as usize))
        default: fatalError("Unexpected addressing mode encountered while tracing!")
        }
    default:
        ""
    }

    trace += "                             "

    trace += "A:" + String(format: "%02X", cpu.accumulator) + " "
    trace += "X:" + String(format: "%02X", cpu.xRegister) + " "
    trace += "Y:" + String(format: "%02X", cpu.yRegister) + " "
    trace += "P:" + String(format: "%02X", cpu.statusRegister.rawValue) + " "
    trace += "SP:" + String(format: "%02X", cpu.stackPointer)

    return trace
}
