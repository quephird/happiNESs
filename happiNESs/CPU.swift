//
//  CPU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/14/24.
//

let RESET_VECTOR_ADDRESS: UInt16 = 0xFFFC;
let RESET_STACK_POINTER_VALUE: UInt8 = 0xFF
let STACK_BOTTOM_MEMORY_ADDRESS: UInt16 = 0x0100;

public struct CPU {
    public var accumulator: UInt8
    public var statusRegister: StatusRegister
    public var xRegister: UInt8
    public var yRegister: UInt8
    public var stackPointer: UInt8
    public var programCounter: UInt16
    public var memory: [UInt8]

    init() {
        self.accumulator = 0x00
        self.statusRegister = StatusRegister(rawValue: 0x00)
        self.xRegister = 0x00
        self.yRegister = 0x00
        self.stackPointer = RESET_STACK_POINTER_VALUE
        self.programCounter = 0x0000
        self.memory = [UInt8](repeating: 0x00, count: 0xFFFF)
    }

    mutating func reset() {
        self.accumulator = 0x00;
        self.statusRegister.reset();
        self.xRegister = 0x00;
        self.yRegister = 0x00;
        self.stackPointer = RESET_STACK_POINTER_VALUE
        self.programCounter = self.readWord(address: RESET_VECTOR_ADDRESS);
    }
}

extension CPU {
    mutating func adc(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let carry: UInt8 = self.statusRegister[.carry] ? 0x01 : 0x00

        let sum = UInt16(self.accumulator) + UInt16(value) + UInt16(carry)
        self.statusRegister[.carry] = sum > 0xFF
        self.statusRegister[.overflow] = ((UInt8(sum & 0xFF) ^ self.accumulator) & (UInt8(sum & 0xFF) ^ value) & 0x80) == 0x80
        self.accumulator = UInt8(sum & 0xFF)
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func and(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.accumulator &= value
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

    mutating func bit(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        let result = self.accumulator & value;
        self.statusRegister[.negative] = value >> 7 == 1
        self.statusRegister[.overflow] = value >> 6 & 0b0000_0001 == 1
        self.statusRegister[.zero] = result == 0
    }

    mutating private func clearBit(bit: StatusRegister.Element) {
        self.statusRegister[bit] = false
    }

    mutating func clc() {
        self.clearBit(bit: .carry)
    }

    mutating func cld() {
        self.clearBit(bit: .decimalMode)
    }

    mutating func cli() {
        self.clearBit(bit: .interrupt)
    }

    mutating func clv() {
        self.clearBit(bit: .overflow)
    }

    mutating private func compareMemory(addressingMode: AddressingMode, to registerValue: UInt8) {
        let address = self.getOperandAddress(addressingMode: addressingMode)
        let memoryValue = self.readByte(address: address)

        self.statusRegister[.carry] = (memoryValue <= registerValue)
        self.updateZeroAndNegativeFlags(result: registerValue &- memoryValue)
    }

    mutating func cmp(addressingMode: AddressingMode) {
        self.compareMemory(addressingMode: addressingMode, to: self.accumulator)
    }

    mutating func cpx(addressingMode: AddressingMode) {
        self.compareMemory(addressingMode: addressingMode, to: self.xRegister)
    }

    mutating func cpy(addressingMode: AddressingMode) {
        self.compareMemory(addressingMode: addressingMode, to: self.yRegister)
    }

    mutating func dec(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.writeByte(address: address, byte: value &- 1)
        self.updateZeroAndNegativeFlags(result: self.readByte(address: address))
    }

    mutating func dex() {
        self.xRegister = self.xRegister &- 1
        self.updateZeroAndNegativeFlags(result: self.xRegister)
    }

    mutating func dey() {
        self.yRegister = self.yRegister &- 1
        self.updateZeroAndNegativeFlags(result: self.yRegister)
    }


    mutating func eor(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator ^= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func inc(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.writeByte(address: address, byte: value &+ 1)
        self.updateZeroAndNegativeFlags(result: self.readByte(address: address))
    }

    mutating func inx() {
        self.xRegister = self.xRegister &+ 1
        self.updateZeroAndNegativeFlags(result: self.xRegister)
    }

    mutating func jmp(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode)
        self.programCounter = address
    }

    mutating func jsr() {
        let subroutineAddress = self.getOperandAddress(addressingMode: .absolute);
        // ACHTUNG!!! Note that this is pointing to the last byte of the `JSR` instruction!
        let returnAddress = self.programCounter + 2 - 1
        let returnAddressHigh = UInt8(returnAddress >> 8)
        let returnAddressLow = UInt8(returnAddress & 0xFF)
        self.pushStack(byte: returnAddressHigh)
        self.pushStack(byte: returnAddressLow)
        self.programCounter = subroutineAddress
    }

    mutating func iny() {
        self.yRegister = self.yRegister &+ 1
        self.updateZeroAndNegativeFlags(result: self.yRegister)
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

    mutating func nop() {
        // For now do nothing but presumably later we'll have to account for CPU cycles
    }

    mutating func ora(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator |= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating private func pushStack(byte: UInt8) {
        self.writeByte(address: STACK_BOTTOM_MEMORY_ADDRESS + UInt16(self.stackPointer), byte: byte)
        self.stackPointer = self.stackPointer &- 1
    }

    mutating private func popStack() -> UInt8 {
        self.stackPointer = self.stackPointer &+ 1
        let byte = self.readByte(address: STACK_BOTTOM_MEMORY_ADDRESS + UInt16(self.stackPointer))
        return byte
    }

    mutating func pha() {
        self.pushStack(byte: self.accumulator)
    }

    mutating func php() {
        self.pushStack(byte: self.statusRegister.rawValue)
    }

    mutating func pla() {
        self.accumulator = self.popStack()
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func plp() {
        // TODO: Come back to this and check to see if any bits
        // in the status register need to be explicitly set
        self.statusRegister.rawValue = self.popStack()
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

    mutating func rts() {
        let addressLow = self.popStack()
        let addressHigh = self.popStack()
        // ACHTUNG!!! Note that this only works in conjunction with the `JSR` instruction!
        let address = UInt16(addressHigh) << 8 | UInt16(addressLow) + 1
        self.programCounter = address
    }

    mutating func sbc(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let borrow: UInt8 = self.statusRegister[.carry] ? 0x00 : 0x01

        let sum = UInt16(self.accumulator) + UInt16(~value) + UInt16(borrow)
        self.statusRegister[.carry] = sum > 0xFF
        self.statusRegister[.overflow] = ((UInt8(sum & 0xFF) ^ self.accumulator) & (UInt8(sum & 0xFF) ^ value) & 0x80) == 0x80
        self.accumulator = UInt8(sum & 0xFF)
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating private func setBit(bit: StatusRegister.Element) {
        self.statusRegister[bit] = true
    }

    mutating func sec() {
        self.setBit(bit: .carry)
    }

    mutating func sed() {
        self.setBit(bit: .decimalMode)
    }

    mutating func sei() {
        self.setBit(bit: .interrupt)
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

    mutating func tay() {
        self.yRegister = self.accumulator;
        self.updateZeroAndNegativeFlags(result: self.yRegister)
    }

    mutating func tsx() {
        self.xRegister = self.stackPointer;
        self.updateZeroAndNegativeFlags(result: self.xRegister)
    }

    mutating func txa() {
        self.accumulator = self.xRegister;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func txs() {
        self.stackPointer = self.xRegister;
        self.updateZeroAndNegativeFlags(result: self.stackPointer)
    }

    mutating func tya() {
        self.accumulator = self.yRegister;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
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

    mutating func executeInstruction() {
        let byte = self.readByte(address: self.programCounter);
        if let opcode = Opcode(rawValue: byte) {
            self.programCounter += 1;
            switch opcode {
            case .adcImmediate, .adcZeroPage, .adcZeroPageX, .adcAbsolute, .adcAbsoluteX, .adcAbsoluteY, .adcIndirectX, .adcIndirectY:
                self.adc(addressingMode: opcode.addressingMode)
            case .andImmediate, .andZeroPage, .andZeroPageX, .andAbsolute, .andAbsoluteX, .andAbsoluteY, .andIndirectX, .andIndirectY:
                self.and(addressingMode: opcode.addressingMode)
            case .aslAccumulator, .aslZeroPage, .aslZeroPageX, .aslAbsolute, .aslAbsoluteX:
                self.asl(addressingMode: opcode.addressingMode)
            case .bitZeroPage, .bitAbsolute:
                self.bit(addressingMode: opcode.addressingMode)
            case .break:
                return;
            case .clc:
                self.clc()
            case .cld:
                self.cld()
            case .cli:
                self.cli()
            case .clv:
                self.clv()
            case .cmpImmediate, .cmpZeroPage, .cmpZeroPageX, .cmpAbsolute, .cmpAbsoluteX, .cmpAbsoluteY, .cmpIndirectX, .cmpIndirectY:
                self.cmp(addressingMode: opcode.addressingMode)
            case .cpxImmediate, .cpxZeroPage, .cpxAbsolute:
                self.cpx(addressingMode: opcode.addressingMode)
            case .cpyImmediate, .cpyZeroPage, .cpyAbsolute:
                self.cpy(addressingMode: opcode.addressingMode)
            case .decZeroPage, .decZeroPageX, .decAbsolute, .decAbsoluteX:
                self.dec(addressingMode: opcode.addressingMode)
            case .dex:
                self.dex()
            case .dey:
                self.dey()
            case .eorImmediate, .eorZeroPage, .eorZeroPageX, .eorAbsolute, .eorAbsoluteX, .eorAbsoluteY, .eorIndirectX, .eorIndirectY:
                self.eor(addressingMode: opcode.addressingMode)
            case .incZeroPage, .incZeroPageX, .incAbsolute, .incAbsoluteX:
                self.inc(addressingMode: opcode.addressingMode)
            case .inx:
                self.inx()
            case .iny:
                self.iny()
            case .jmpAbsolute, .jmpIndirect:
                self.jmp(addressingMode: opcode.addressingMode)
            case .jsr:
                self.jsr()
            case .ldaImmediate, .ldaZeroPage, .ldaZeroPageX, .ldaAbsolute, .ldaAbsoluteX, .ldaAbsoluteY, .ldaIndirectX, .ldaIndirectY:
                self.lda(addressingMode: opcode.addressingMode)
            case .ldxImmediate, .ldxZeroPage, .ldxZeroPageY, .ldxAbsolute, .ldxAbsoluteY:
                self.ldx(addressingMode: opcode.addressingMode)
            case .ldyImmediate, .ldyZeroPage, .ldyZeroPageX, .ldyAbsolute, .ldyAbsoluteX:
                self.ldy(addressingMode: opcode.addressingMode)
            case .lsrAccumulator, .lsrZeroPage, .lsrZeroPageX, .lsrAbsolute, .lsrAbsoluteX:
                self.lsr(addressingMode: opcode.addressingMode)
            case .nop:
                self.nop()
            case .oraImmediate, .oraZeroPage, .oraZeroPageX, .oraAbsolute, .oraAbsoluteX, .oraAbsoluteY, .oraIndirectX, .oraIndirectY:
                self.ora(addressingMode: opcode.addressingMode)
            case .pha:
                self.pha()
            case .php:
                self.php()
            case .pla:
                self.pla()
            case .plp:
                self.plp()
            case .rolAccumulator, .rolZeroPage, .rolZeroPageX, .rolAbsolute, .rolAbsoluteX:
                self.rol(addressingMode: opcode.addressingMode)
            case .rorAccumulator, .rorZeroPage, .rorZeroPageX, .rorAbsolute, .rorAbsoluteX:
                self.ror(addressingMode: opcode.addressingMode)
            case .rts:
                self.rts()
            case .sbcImmediate, .sbcZeroPage, .sbcZeroPageX, .sbcAbsolute, .sbcAbsoluteX, .sbcAbsoluteY, .sbcIndirectX, .sbcIndirectY:
                self.sbc(addressingMode: opcode.addressingMode)
            case .sec:
                self.sec()
            case .sed:
                self.sed()
            case .sei:
                self.sei()
            case .staZeroPage, .staZeroPageX, .staAbsolute, .staAbsoluteX, .staAbsoluteY, .staIndirectX, .staIndirectY:
                self.sta(addressingMode: opcode.addressingMode)
            case .stxZeroPage, .stxZeroPageY, .stxAbsolute:
                self.stx(addressingMode: opcode.addressingMode)
            case .styZeroPage, .styZeroPageY, .styAbsolute:
                self.sty(addressingMode: opcode.addressingMode)
            case .tax:
                self.tax()
            case .tay:
                self.tay()
            case .tsx:
                self.tsx()
            case .txa:
                self.txa()
            case .txs:
                self.txs()
            case .tya:
                self.tya()
            }

            if !opcode.manipulatesProgramCounter {
                self.programCounter += UInt16(opcode.instructionLength - 1)
            }
        } else {
            fatalError("Whoops! Instruction \(byte) not recognized!!!")
        }
    }

    mutating func run() {
        while true {
            self.executeInstruction()
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
        case .indirect:
            let baseAddress = self.readWord(address: self.programCounter)
            return self.readWord(address: baseAddress)
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
