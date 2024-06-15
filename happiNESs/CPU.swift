//
//  CPU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/14/24.
//

let RESET_VECTOR_ADDRESS: UInt16 = 0xFFFC;

public struct CPU {
    public var accumulator: UInt8
    public var statusRegister: StatusRegister
    public var xRegister: UInt8
    public var yRegister: UInt8
    public var programCounter: UInt16
    public var memory: [UInt8]

    init() {
        self.accumulator = 0x00
        self.statusRegister = StatusRegister(rawValue: 0x00)
        self.xRegister = 0x00
        self.yRegister = 0x00
        self.programCounter = 0x0000
        self.memory = [UInt8](repeating: 0x00, count: 0xFFFF)
    }

    mutating func reset() {
        self.accumulator = 0x00;
        self.xRegister = 0x00;
        self.yRegister = 0x00;
        self.statusRegister.reset();
        self.programCounter = self.readWord(address: RESET_VECTOR_ADDRESS);
    }
}

extension CPU {
    mutating func and(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator &= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func asl(addressingMode: AddressingMode) {
        if addressingMode == .accumulator {
            self.statusRegister[.carry] = self.accumulator >> 7 == 1
            self.accumulator <<= 1
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let address = self.getOperandAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);

            self.statusRegister[.carry] = value >> 7 == 1
            self.writeByte(address: address, byte: value << 1)
            self.updateZeroAndNegativeFlags(result: value << 1)
        }
    }

    mutating func eor(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator ^= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func inx() {
        self.xRegister = self.xRegister &+ 1
        self.updateZeroAndNegativeFlags(result: self.xRegister)
    }

    mutating func lda(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator = value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func ldx(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.xRegister = value;
        self.updateZeroAndNegativeFlags(result: self.xRegister)
    }

    mutating func ldy(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.yRegister = value;
        self.updateZeroAndNegativeFlags(result: self.yRegister)
    }

    mutating func lsr(addressingMode: AddressingMode) {
        if addressingMode == .accumulator {
            self.statusRegister[.carry] = self.accumulator & 0b0000_0001 == 1
            self.accumulator >>= 1
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let address = self.getOperandAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);

            self.statusRegister[.carry] = value & 0b0000_0001 == 1
            self.writeByte(address: address, byte: value >> 1)
            self.updateZeroAndNegativeFlags(result: value >> 1)
        }
    }

    mutating func ora(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator |= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func rol(addressingMode: AddressingMode) {
        if addressingMode == .accumulator {
            let carry = self.accumulator >> 7
            self.statusRegister[.carry] = carry == 1
            self.accumulator = (self.accumulator << 1) | carry
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let address = self.getOperandAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);
            let carry = value >> 7

            self.statusRegister[.carry] = carry == 1
            let newValue = value << 1 | carry
            self.writeByte(address: address, byte: newValue)
            self.updateZeroAndNegativeFlags(result: newValue)
        }
    }

    mutating func ror(addressingMode: AddressingMode) {
        if addressingMode == .accumulator {
            let carry = self.accumulator & 0b0000_0001
            self.statusRegister[.carry] = carry == 1
            self.accumulator = (self.accumulator >> 1) | carry << 7
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let address = self.getOperandAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);
            let carry = value & 0b0000_0001

            self.statusRegister[.carry] = carry == 1
            let newValue = value >> 1 | carry << 7
            self.writeByte(address: address, byte: newValue)
            self.updateZeroAndNegativeFlags(result: newValue)
        }
    }

    mutating func sta(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        self.writeByte(address: address, byte: self.accumulator);
    }

    mutating func stx(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        self.writeByte(address: address, byte: self.xRegister);
    }

    mutating func sty(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        self.writeByte(address: address, byte: self.yRegister);
    }

    mutating func tax() {
        self.xRegister = self.accumulator;
        self.updateZeroAndNegativeFlags(result: self.xRegister)
    }

    mutating func updateZeroAndNegativeFlags(result: UInt8) {
        self.statusRegister[.zero] = result == 0
        self.statusRegister[.negative] = (result & 0b1000_0000) != 0
    }
}

extension CPU {
    mutating func loadAndRun(program: [UInt8]) {
        self.load(program: program);
        self.reset();
        self.run();
    }

    mutating func load(program: [UInt8]) {
        self.memory.replaceSubrange(0x8000 ... 0x8000+program.count, with: program)
        self.writeWord(address: RESET_VECTOR_ADDRESS, word: 0x8000);
    }

    mutating func run() {
        while true {
            let byte = self.readByte(address: self.programCounter);
            if let opcode = Opcode(rawValue: byte) {
                self.programCounter += 1;
                switch opcode {
                case .andImmediate, .andZeroPage, .andZeroPageX, .andAbsolute, .andAbsoluteX, .andAbsoluteY, .andIndirectX, .andIndirectY:
                    self.and(addressingMode: opcode.addressingMode)
                case .aslAccumlator, .aslZeroPage, .aslZeroPageX, .aslAbsolute, .aslAbsoluteX:
                    self.asl(addressingMode: opcode.addressingMode)
                case .break:
                    return;
                case .eorImmediate, .eorZeroPage, .eorZeroPageX, .eorAbsolute, .eorAbsoluteX, .eorAbsoluteY, .eorIndirectX, .eorIndirectY:
                    self.eor(addressingMode: opcode.addressingMode)
                case .ldaImmediate, .ldaZeroPage, .ldaZeroPageX, .ldaAbsolute, .ldaAbsoluteX, .ldaAbsoluteY, .ldaIndirectX, .ldaIndirectY:
                    self.lda(addressingMode: opcode.addressingMode)
                case .ldxImmediate, .ldxZeroPage, .ldxZeroPageY, .ldxAbsolute, .ldxAbsoluteY:
                    self.ldx(addressingMode: opcode.addressingMode)
                case .ldyImmediate, .ldyZeroPage, .ldyZeroPageX, .ldyAbsolute, .ldyAbsoluteX:
                    self.ldy(addressingMode: opcode.addressingMode)
                case .lsrAccumlator, .lsrZeroPage, .lsrZeroPageX, .lsrAbsolute, .lsrAbsoluteX:
                    self.lsr(addressingMode: opcode.addressingMode)
                case .oraImmediate, .oraZeroPage, .oraZeroPageX, .oraAbsolute, .oraAbsoluteX, .oraAbsoluteY, .oraIndirectX, .oraIndirectY:
                    self.ora(addressingMode: opcode.addressingMode)
                case .rolAccumlator, .rolZeroPage, .rolZeroPageX, .rolAbsolute, .rolAbsoluteX:
                    self.rol(addressingMode: opcode.addressingMode)
                case .rorAccumlator, .rorZeroPage, .rorZeroPageX, .rorAbsolute, .rorAbsoluteX:
                    self.ror(addressingMode: opcode.addressingMode)
                case .staZeroPage, .staZeroPageX, .staAbsolute, .staAbsoluteX, .staAbsoluteY, .staIndirectX, .staIndirectY:
                    self.sta(addressingMode: opcode.addressingMode)
                case .stxZeroPage, .stxZeroPageY, .stxAbsolute:
                    self.stx(addressingMode: opcode.addressingMode)
                case .styZeroPage, .styZeroPageY, .styAbsolute:
                    self.sty(addressingMode: opcode.addressingMode)
                case .tax:
                    self.tax()
                case .inx:
                    self.inx()
                }

                self.programCounter += UInt16(opcode.instructionLength - 1)
            } else {
                fatalError("Whoops! Instruction \(byte) not recognized!!!")
            }
        }
    }

    func getOperandAddress(addressingMode: AddressingMode) -> UInt16 {
        switch addressingMode {
        case .immediate:
            return self.programCounter
        case .zeroPage:
            return UInt16(self.readByte(address: self.programCounter))
        case .zeroPageX:
            let baseAddress = self.readByte(address: self.programCounter)
            return UInt16(baseAddress &+ self.xRegister)
        case .zeroPageY:
            let baseAddress = self.readByte(address: self.programCounter)
            return UInt16(baseAddress &+ self.yRegister)
        case .absolute:
            return self.readWord(address: self.programCounter)
        case .absoluteX:
            let baseAddress = self.readWord(address: self.programCounter)
            return baseAddress &+ UInt16(self.xRegister)
        case .absoluteY:
            let baseAddress = self.readWord(address: self.programCounter)
            return baseAddress &+ UInt16(self.yRegister)
        case .indirectX:
            // operand_ptr = *(void **)(constant_byte + x_register)
            let baseAddress = self.readByte(address: self.programCounter)
            let indirectAddress = baseAddress &+ self.xRegister

            let lowByte = self.readByte(address: UInt16(indirectAddress))
            let highByte = self.readByte(address: UInt16(indirectAddress &+ 1))

            return UInt16(highByte) << 8 | UInt16(lowByte)
        case .indirectY:
            // operand_ptr = *((void **)constant_byte) + y_register
            let baseAddress = self.readByte(address: self.programCounter)

            let lowByte = self.readByte(address: UInt16(baseAddress))
            let highByte = self.readByte(address: UInt16(baseAddress &+ 1))

            let indirectAddress = UInt16(highByte) << 8 | UInt16(lowByte)
            return indirectAddress &+ UInt16(self.yRegister)
        default:
            fatalError("Addressing mode not supported!")
        }
    }

    func readWord(address: UInt16) -> UInt16 {
        let lowByte = self.readByte(address: address)
        let highByte = self.readByte(address: address + 1)
        return UInt16(highByte) << 8 | UInt16(lowByte)
    }

    mutating func writeWord(address: UInt16, word: UInt16) {
        let lowByte = UInt8(word & 0xFF)
        let highByte = UInt8(word >> 8)
        self.writeByte(address: address, byte: lowByte);
        self.writeByte(address: address + 1, byte: highByte);
    }

    func readByte(address: UInt16) -> UInt8 {
        self.memory[Int(address)]
    }

    mutating func writeByte(address: UInt16, byte: UInt8) {
        self.memory[Int(address)] = byte
    }
}
