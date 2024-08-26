//
//  Tracing.swift
//  happiNESs
//
//  Created by Danielle Kefford on 7/6/24.
//

func trace(cpu: CPU) -> String {
    var trace = ""
    trace += String(format: "%04X", cpu.programCounter) + "  "

    let byte = cpu.readByteWithoutMutating(address: cpu.programCounter)
    trace += String(format: "%02X", byte) + " "
    let opcode = Opcode(rawValue: byte)!
    switch opcode.instructionLength {
    case 1:
        trace += "      "
    case 2:
        trace += String(format: "%02X", cpu.readByteWithoutMutating(address: cpu.programCounter + 1))
        trace += "    "
    case 3:
        trace += String(format: "%02X", cpu.readByteWithoutMutating(address: cpu.programCounter + 1)) + " "
        trace += String(format: "%02X", cpu.readByteWithoutMutating(address: cpu.programCounter + 2))
        trace += " "
    default:
        fatalError("Tracing halted; opcode with unexpected length encountered!")
    }

    trace += opcode.isDocumented ? " " : "*"

    trace += opcode.mnemonic + " "

    let absoluteAddress: UInt16 = switch opcode.addressingMode {
    case .accumulator, .immediate, .implicit: 0
    default: cpu.getAbsoluteAddressWithoutMutating(addressingMode: opcode.addressingMode, address: cpu.programCounter + 1)
    }
    let value: UInt8 = switch opcode.addressingMode {
    case .accumulator, .immediate, .implicit:
        0
    default:
        cpu.readByteWithoutMutating(address: absoluteAddress)
    }

    let partialAsm: String
    if opcode.instructionLength == 1 {
        partialAsm = switch byte {
        case 0x0A, 0x2A, 0x4A, 0x6A: "A "
        default: ""
        }
    } else if opcode.instructionLength == 2 {
        let nextByte = cpu.readByteWithoutMutating(address: cpu.programCounter + 1)

        switch opcode.addressingMode {
        case .immediate:
            partialAsm = String(format: "#$%02X", nextByte)
        case .zeroPage:
            partialAsm = String(format: "$%02X = %02X", absoluteAddress, value)
        case .zeroPageX:
            partialAsm = String(format: "$%02X,X @ %02X = %02X", nextByte, absoluteAddress, value)
        case .zeroPageY:
            partialAsm = String(format: "$%02X,Y @ %02X = %02X", nextByte, absoluteAddress, value)
        case .indirectX:
            partialAsm = String(format: "($%02X,X) @ %02X = %04X = %02X", nextByte, nextByte &+ cpu.xRegister, absoluteAddress, value)
        case .indirectY:
            partialAsm = String(format: "($%02X),Y = %04X @ %04X = %02X", nextByte, absoluteAddress &- UInt16(cpu.yRegister), absoluteAddress, value)
        case .relative:
            let address = if nextByte >> 7 == 0 {
                (cpu.programCounter + 2) &+ UInt16(nextByte)
            } else {
                (cpu.programCounter + 2) &+ UInt16(nextByte) &- 0x0100
            }

            partialAsm = String(format: "$%04X", address)
        default: fatalError("Unexpected addressing mode encountered while tracing!")
        }
    } else if opcode.instructionLength == 3 {
        let address = cpu.readWordWithoutMutating(address: cpu.programCounter + 1)

        switch opcode.addressingMode {
        case .indirect:
            let jumpAddress: UInt16
            if address & 0x00FF == 0x00FF {
                let lowByte = cpu.readByteWithoutMutating(address: address)
                let highByte = cpu.readByteWithoutMutating(address: address & 0xFF00)
                jumpAddress = UInt16(highByte) << 8 | UInt16(lowByte)
            } else {
                jumpAddress = cpu.readWordWithoutMutating(address: address)
            }

            partialAsm = String(format: "($%04X) = %04X", address, jumpAddress)
        case .absolute:
            if [.jmpAbsolute, .jsr].contains(opcode) {
                partialAsm = String(format: "$%04X", absoluteAddress)
            } else {
                partialAsm = String(format: "$%04X = %02X", absoluteAddress, value)
            }
        case .absoluteX:
            partialAsm = String(format: "$%04X,X @ %04X = %02X", address, absoluteAddress, value)
        case .absoluteY:
            partialAsm = String(format: "$%04X,Y @ %04X = %02X", address, absoluteAddress, value)
        default:
            fatalError("Unexpected addressing mode encountered while tracing!")
        }
    } else {
        partialAsm = ""
    }

    partialAsm.withCString { cString in
        trace += String(format: "%-28s", cString)
    }

    trace += "A:" + String(format: "%02X ", cpu.accumulator)
    trace += "X:" + String(format: "%02X ", cpu.xRegister)
    trace += "Y:" + String(format: "%02X ", cpu.yRegister)
    trace += "P:" + String(format: "%02X ", cpu.statusRegister.rawValue)
    trace += "SP:" + String(format: "%02X ", cpu.stackPointer)

    trace += "PPU:" + String(format: "%3d,%3d ", cpu.bus.ppu.scanline, cpu.bus.ppu.cycles)

    trace += "CYC:" + String(cpu.bus.cycles)

    return trace
}
