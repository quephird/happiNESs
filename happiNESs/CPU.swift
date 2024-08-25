//
//  CPU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/14/24.
//

public struct CPU {
    static let nmiVectorAddress: UInt16 = 0xFFFA
    static let resetVectorAddress: UInt16 = 0xFFFC
    static let interruptVectorAddress: UInt16 = 0xFFFE
    // TODO: Need to look into why the stack pointer starts here and not at 0xFF!!!
    static let resetStackPointerValue: UInt8 = 0xFD
    static let stackBottomMemoryAddress: UInt16 = 0x0100

    public var accumulator: UInt8
    public var statusRegister: StatusRegister
    public var xRegister: UInt8
    public var yRegister: UInt8
    public var stackPointer: UInt8
    public var programCounter: UInt16
    public var bus: Bus

    public var tracingOn: Bool

    public init(bus: Bus, tracingOn: Bool = false) {
        self.accumulator = 0x00
        self.statusRegister = StatusRegister(rawValue: 0x00)
        self.xRegister = 0x00
        self.yRegister = 0x00
        self.stackPointer = Self.resetStackPointerValue
        self.programCounter = 0x0000
        self.bus = bus
        self.tracingOn = tracingOn
    }

    mutating public func reset() {
        self.accumulator = 0x00;
        self.statusRegister.reset();
        self.xRegister = 0x00;
        self.yRegister = 0x00;
        self.stackPointer = Self.resetStackPointerValue
        self.programCounter = self.readWord(address: Self.resetVectorAddress)

        // TODO: Look more deeply into whether or not this is the best strategy
        // for simulating the initial number of CPU cycles when resetting the CPU
        let _ = self.bus.tick(cycles: 7)
    }
}

extension CPU {
    mutating func adc(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let carry: UInt8 = self.statusRegister[.carry] ? 0x01 : 0x00

        let sum = UInt16(self.accumulator) + UInt16(value) + UInt16(carry)
        self.statusRegister[.carry] = sum > 0xFF
        self.statusRegister[.overflow] = ((UInt8(sum & 0xFF) ^ self.accumulator) & (UInt8(sum & 0xFF) ^ value) & 0x80) == 0x80
        self.accumulator = UInt8(sum & 0xFF)
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating func and(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.accumulator &= value
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating func asl(addressingMode: AddressingMode) -> (Bool, Int) {
        if addressingMode == .accumulator {
            self.statusRegister[.carry] = self.accumulator >> 7 == 1
            self.accumulator <<= 1
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);

            self.statusRegister[.carry] = value >> 7 == 1
            self.writeByte(address: address, byte: value << 1)
            self.updateZeroAndNegativeFlags(result: value << 1)
        }

        return (false, 0)
    }

    mutating func bcc() -> (Bool, Int) {
        return self.branch(condition: !self.statusRegister[.carry])
    }

    mutating func bcs() -> (Bool, Int) {
        return self.branch(condition: self.statusRegister[.carry])
    }

    mutating func beq() -> (Bool, Int) {
        return self.branch(condition: self.statusRegister[.zero])
    }

    mutating private func branch(condition: Bool) -> (Bool, Int) {
        if condition {
            let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: .relative)
            self.programCounter = address
            let extraCycles = 1 + (pageCrossed ? 1 : 0)
            return (true, extraCycles)
        }

        return (false, 0)
    }

    mutating func bit(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        let result = self.accumulator & value;
        self.statusRegister[.negative] = value >> 7 == 1
        self.statusRegister[.overflow] = value >> 6 & 0b0000_0001 == 1
        self.statusRegister[.zero] = result == 0

        return (false, 0)
    }

    mutating func bmi() -> (Bool, Int) {
        return self.branch(condition: self.statusRegister[.negative])
    }

    mutating func bne() -> (Bool, Int) {
        return self.branch(condition: !self.statusRegister[.zero])
    }

    mutating func bpl() -> (Bool, Int) {
        return self.branch(condition: !self.statusRegister[.negative])
    }

    mutating func brk() -> (Bool, Int) {
        let currentStatus = self.statusRegister.rawValue
        // NOTA BENE: We've already advanced the program counter upon consuming the
        // `BRK` byte; now we need to advance it one more time since the byte after
        // the instruction is ignored, per the documentation. See
        //
        //     https://www.pagetable.com/c64ref/6502/?tab=2#BRK
        self.programCounter += 1
        self.pushStack(word: self.programCounter)
        self.pushStack(byte: currentStatus)
        self.programCounter = self.readWord(address: Self.interruptVectorAddress)
        self.statusRegister[.interrupt] = true

        return (true, 0)
    }

    mutating func bvc() -> (Bool, Int) {
        return self.branch(condition: !self.statusRegister[.overflow])
    }

    mutating func bvs() -> (Bool, Int) {
        return self.branch(condition: self.statusRegister[.overflow])
    }

    mutating private func clearBit(bit: StatusRegister.Element) {
        self.statusRegister[bit] = false
    }

    mutating func clc() -> (Bool, Int) {
        self.clearBit(bit: .carry)

        return (false, 0)
    }

    mutating func cld() -> (Bool, Int) {
        self.clearBit(bit: .decimalMode)

        return (false, 0)
    }

    mutating func cli() -> (Bool, Int) {
        self.clearBit(bit: .interrupt)

        return (false, 0)
    }

    mutating func clv() -> (Bool, Int) {
        self.clearBit(bit: .overflow)

        return (false, 0)
    }

    mutating private func compareMemory(addressingMode: AddressingMode, to registerValue: UInt8) -> Bool {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let memoryValue = self.readByte(address: address)

        self.statusRegister[.carry] = (memoryValue <= registerValue)
        self.updateZeroAndNegativeFlags(result: registerValue &- memoryValue)

        return pageCrossed
    }

    mutating func cmp(addressingMode: AddressingMode) -> (Bool, Int) {
        let pageCrossed = self.compareMemory(addressingMode: addressingMode, to: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating func cpx(addressingMode: AddressingMode) -> (Bool, Int) {
        let _ = self.compareMemory(addressingMode: addressingMode, to: self.xRegister)

        return (false, 0)
    }

    mutating func cpy(addressingMode: AddressingMode) -> (Bool, Int) {
        let _ = self.compareMemory(addressingMode: addressingMode, to: self.yRegister)

        return (false, 0)
    }

    mutating func dcp(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)

        let newValue = value &- 1
        self.writeByte(address: address, byte: newValue)
        self.statusRegister[.carry] = newValue <= self.accumulator
        self.updateZeroAndNegativeFlags(result: self.accumulator &- newValue)

        return (false, 0)
    }

    mutating func dec(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.writeByte(address: address, byte: value &- 1)
        self.updateZeroAndNegativeFlags(result: self.readByte(address: address))

        return (false, 0)
    }

    mutating func dex() -> (Bool, Int) {
        self.xRegister = self.xRegister &- 1
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, 0)
    }

    mutating func dey() -> (Bool, Int) {
        self.yRegister = self.yRegister &- 1
        self.updateZeroAndNegativeFlags(result: self.yRegister)

        return (false, 0)
    }


    mutating func eor(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator ^= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating func inc(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.writeByte(address: address, byte: value &+ 1)
        self.updateZeroAndNegativeFlags(result: self.readByte(address: address))

        return (false, 0)
    }

    mutating func inx() -> (Bool, Int) {
        self.xRegister = self.xRegister &+ 1
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, 0)
    }

    mutating func iny() -> (Bool, Int) {
        self.yRegister = self.yRegister &+ 1
        self.updateZeroAndNegativeFlags(result: self.yRegister)

        return (false, 0)
    }

    mutating func isb(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        self.writeByte(address: address, byte: self.readByte(address: address) &+ 1)

        // ACHTUNG! This appears to ignore page crossings
        let (programCounterMutated, _) = self.sbc(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    mutating func jmp(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        self.programCounter = address

        return (true, 0)
    }

    mutating func jsr() -> (Bool, Int) {
        let (subroutineAddress, _) = self.getAbsoluteAddress(addressingMode: .absolute);
        // ACHTUNG!!! Note that this is pointing to the last byte of the `JSR` instruction!
        let returnAddress = self.programCounter + 2 - 1
        self.pushStack(word: returnAddress)
        self.programCounter = subroutineAddress

        return (true, 0)
    }

    mutating func lax(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);

        self.accumulator = value
        self.xRegister = value
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating func lda(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);
        self.accumulator = value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating func ldx(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);
        self.xRegister = value;
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating func ldy(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);
        self.yRegister = value;
        self.updateZeroAndNegativeFlags(result: self.yRegister)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating func lsr(addressingMode: AddressingMode) -> (Bool, Int) {
        if addressingMode == .accumulator {
            self.statusRegister[.carry] = self.accumulator & 0b0000_0001 == 1
            self.accumulator >>= 1
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);

            self.statusRegister[.carry] = value & 0b0000_0001 == 1
            self.writeByte(address: address, byte: value >> 1)
            self.updateZeroAndNegativeFlags(result: value >> 1)
        }

        return (false, 0)
    }

    mutating func nop(addressingMode: AddressingMode) -> (Bool, Int) {
        if addressingMode == .implicit {
            return (false, 0)
        }

        let (_, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        return (false, pageCrossed ? 1 : 0)
    }

    mutating func ora(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);
        self.accumulator |= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating private func pushStack(byte: UInt8) {
        self.writeByte(address: Self.stackBottomMemoryAddress + UInt16(self.stackPointer), byte: byte)
        self.stackPointer = self.stackPointer &- 1
    }

    mutating private func pushStack(word: UInt16) {
        self.pushStack(byte: word.highByte)
        self.pushStack(byte: word.lowByte)
    }

    mutating private func popStack() -> UInt8 {
        self.stackPointer = self.stackPointer &+ 1
        let byte = self.readByte(address: Self.stackBottomMemoryAddress + UInt16(self.stackPointer))
        return byte
    }

    mutating func pha() -> (Bool, Int) {
        self.pushStack(byte: self.accumulator)

        return (false, 0)
    }

    mutating func php() -> (Bool, Int) {
        // NOTA BENE: We need to set the so-called B flag upon a push to the stack:
        //
        //    https://www.nesdev.org/wiki/Status_flags#The_B_flag
        self.pushStack(byte: self.statusRegister.rawValue | 0b0001_0000)

        return (false, 0)
    }

    mutating func pla() -> (Bool, Int) {
        self.accumulator = self.popStack()
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, 0)
    }

    mutating func plp() -> (Bool, Int) {
        self.statusRegister.rawValue = self.popStack()
        self.statusRegister[.break] = false
        self.statusRegister[.unused] = true

        return (false, 0)
    }

    mutating func rla(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let oldCarry: UInt8 = self.statusRegister[.carry] ? 1 : 0
        self.writeByte(address: address, byte: (value << 1) | oldCarry)
        self.statusRegister[.carry] = (value >> 7) == 1

        // ACHTUNG! It appears that page crossings are ignored by this opcode
        let (programCounterMutated, _) = self.and(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    mutating func rol(addressingMode: AddressingMode) -> (Bool, Int) {
        let oldCarry: UInt8 = self.statusRegister[.carry] ? 1 : 0

        if addressingMode == .accumulator {
            let carry = self.accumulator >> 7
            self.statusRegister[.carry] = carry == 1
            self.accumulator = (self.accumulator << 1) | oldCarry
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);
            let carry = value >> 7

            self.statusRegister[.carry] = carry == 1
            let newValue = value << 1 | oldCarry
            self.writeByte(address: address, byte: newValue)
            self.updateZeroAndNegativeFlags(result: newValue)
        }

        return (false, 0)
    }

    mutating func ror(addressingMode: AddressingMode) -> (Bool, Int) {
        let oldCarry: UInt8 = self.statusRegister[.carry] ? 1 : 0

        if addressingMode == .accumulator {
            self.statusRegister[.carry] = self.accumulator & 0b0000_0001 == 1
            self.accumulator = (self.accumulator >> 1) | (oldCarry << 7)
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            // Intentionally drop the page-crossed flag on the floor rather than take
            // an extra cycle like most instructions. This seems super-weird and I'm
            // not sure it's correct, but all the docs and other implementations are
            // consistent.
            let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address)

            self.statusRegister[.carry] = value & 0b0000_0001 == 1
            let newValue = (value >> 1) | (oldCarry << 7)
            self.writeByte(address: address, byte: newValue)

            self.updateZeroAndNegativeFlags(result: newValue)
        }

        return (false, 0)
    }

    mutating func rra(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let oldCarry: UInt8 = self.statusRegister[.carry] ? 1 : 0
        self.writeByte(address: address, byte: (value >> 1) | oldCarry << 7)
        self.statusRegister[.carry] = (value & 0b0000_0001) == 1

        // ACHTUNG! This instruction also appears to ignore page crossings
        let (programCounterMutated, _) = self.adc(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    mutating func rti() -> (Bool, Int) {
        self.statusRegister.rawValue = self.popStack()
        self.statusRegister[.break] = false
        self.statusRegister[.unused] = true

        let addressLow = self.popStack()
        let addressHigh = self.popStack()
        let address = UInt16(lowByte: addressLow, highByte: addressHigh)
        self.programCounter = address

        return (true, 0)
    }

    mutating func rts() -> (Bool, Int) {
        let addressLow = self.popStack()
        let addressHigh = self.popStack()
        // ACHTUNG!!! Note that this only works in conjunction with the `JSR` instruction!
        let address = UInt16(lowByte: addressLow, highByte: addressHigh) + 1
        self.programCounter = address

        return (true, 0)
    }

    mutating func sax(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        self.writeByte(address: address, byte: self.accumulator & self.xRegister)

        return (false, 0)
    }

    mutating func sbc(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let carry: UInt8 = self.statusRegister[.carry] ? 0x01 : 0x00
        let oldAccumulator = self.accumulator

        self.accumulator = oldAccumulator &- value &- (1 - carry)
        self.statusRegister[.carry] = Int16(oldAccumulator) - Int16(value) - Int16(1 - carry) >= 0
        self.statusRegister[.overflow] = (oldAccumulator ^ value) & 0x80 != 0 && (oldAccumulator ^ self.accumulator) & 0x80 != 0
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    mutating private func setBit(bit: StatusRegister.Element) {
        self.statusRegister[bit] = true
    }

    mutating func sec() -> (Bool, Int) {
        self.setBit(bit: .carry)

        return (false, 0)
    }

    mutating func sed() -> (Bool, Int) {
        self.setBit(bit: .decimalMode)

        return (false, 0)
    }

    mutating func sei() -> (Bool, Int) {
        self.setBit(bit: .interrupt)

        return (false, 0)
    }

    mutating func slo(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let oldValue = self.readByte(address: address)
        self.writeByte(address: address, byte: oldValue << 1)
        self.statusRegister[.carry] = (oldValue >> 7) == 1

        // ACHTUNG! It appears that page crossings are ignored by this opcode
        let (programCounterMutated, _) = self.ora(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    mutating func sre(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.writeByte(address: address, byte: value >> 1)
        self.statusRegister[.carry] = (value & 0b0000_0001) == 1

        // ACHTUNG! It appears that page crossings are ignored by this opcode
        let (programCounterMutated, _) = self.eor(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    mutating func sta(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        self.writeByte(address: address, byte: self.accumulator)

        return (false, 0)
    }

    mutating func stx(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
        self.writeByte(address: address, byte: self.xRegister);

        return (false, 0)
    }

    mutating func sty(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
        self.writeByte(address: address, byte: self.yRegister);

        return (false, 0)
    }

    mutating func tax() -> (Bool, Int) {
        self.xRegister = self.accumulator;
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, 0)
    }

    mutating func tay() -> (Bool, Int) {
        self.yRegister = self.accumulator;
        self.updateZeroAndNegativeFlags(result: self.yRegister)

        return (false, 0)
    }

    mutating func tsx() -> (Bool, Int) {
        self.xRegister = self.stackPointer;
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, 0)
    }

    mutating func txa() -> (Bool, Int) {
        self.accumulator = self.xRegister;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, 0)
    }

    mutating func txs() -> (Bool, Int) {
        self.stackPointer = self.xRegister;

        return (false, 0)
    }

    mutating func tya() -> (Bool, Int) {
        self.accumulator = self.yRegister;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, 0)
    }

    mutating private func updateZeroAndNegativeFlags(result: UInt8) {
        self.statusRegister[.zero] = result == 0
        self.statusRegister[.negative] = (result & 0b1000_0000) != 0
    }
}

public enum StopCondition {
    case instructions(Int)
    case nextFrame
}

extension CPU {
    // NOTA BENE: This method is only ever called from unit tests.
    mutating public func executeInstructions(stoppingAfter: Int) {
        executeInstructions(stoppingAfter: .instructions(stoppingAfter))
    }

    mutating public func executeInstructions(stoppingAfter: StopCondition) {
        switch stoppingAfter {
        case .instructions(let count):
            (0..<count).forEach { i in
                let _ = self.executeInstruction()
            }

        case .nextFrame:
            // We keep calling executeInstruction() until it returns
            // `true`, in which case the screen needs redrawing.
            while !executeInstruction() {
            }
        }
    }

    // This method returns the value from the call to Bus.tick()
    // which represents whether or not the screen needs to be redrawn
    mutating func executeInstruction() -> Bool {
        if let _ = self.bus.pollNmiStatus() {
            self.interruptNmi()
        }

        if self.tracingOn {
            print(happiNESs.trace(cpu: self))
        }

        let byte = self.readByte(address: self.programCounter);
        if let opcode = Opcode(rawValue: byte) {
            self.programCounter += 1;

            let (programCounterMutated, extraCycles) = switch opcode {
            case .adcImmediate, .adcZeroPage, .adcZeroPageX, .adcAbsolute, .adcAbsoluteX, .adcAbsoluteY, .adcIndirectX, .adcIndirectY:
                self.adc(addressingMode: opcode.addressingMode)
            case .andImmediate, .andZeroPage, .andZeroPageX, .andAbsolute, .andAbsoluteX, .andAbsoluteY, .andIndirectX, .andIndirectY:
                self.and(addressingMode: opcode.addressingMode)
            case .aslAccumulator, .aslZeroPage, .aslZeroPageX, .aslAbsolute, .aslAbsoluteX:
                self.asl(addressingMode: opcode.addressingMode)
            case .bcc:
                self.bcc()
            case .bcs:
                self.bcs()
            case .beq:
                self.beq()
            case .bitZeroPage, .bitAbsolute:
                self.bit(addressingMode: opcode.addressingMode)
            case .bmi:
                self.bmi()
            case .bne:
                self.bne()
            case .bpl:
                self.bpl()
            case .brk:
                self.brk()
            case .bvc:
                self.bvc()
            case .bvs:
                self.bvs()
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
            case .dcpAbsolute, .dcpAbsoluteX, .dcpAbsoluteY, .dcpZeroPage, .dcpZeroPageX, .dcpIndirectX, .dcpIndirectY:
                self.dcp(addressingMode: opcode.addressingMode)
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
            case .isbAbsolute, .isbAbsoluteX, .isbAbsoluteY, .isbZeroPage, .isbZeroPageX, .isbIndirectX, .isbIndirectY:
                self.isb(addressingMode: opcode.addressingMode)
            case .jmpAbsolute, .jmpIndirect:
                self.jmp(addressingMode: opcode.addressingMode)
            case .jsr:
                self.jsr()
            case .laxImmediate, .laxZeroPage, .laxZeroPageY, .laxAbsolute, .laxAbsoluteY, .laxIndirectX, .laxIndirectY:
                self.lax(addressingMode: opcode.addressingMode)
            case .ldaImmediate, .ldaZeroPage, .ldaZeroPageX, .ldaAbsolute, .ldaAbsoluteX, .ldaAbsoluteY, .ldaIndirectX, .ldaIndirectY:
                self.lda(addressingMode: opcode.addressingMode)
            case .ldxImmediate, .ldxZeroPage, .ldxZeroPageY, .ldxAbsolute, .ldxAbsoluteY:
                self.ldx(addressingMode: opcode.addressingMode)
            case .ldyImmediate, .ldyZeroPage, .ldyZeroPageX, .ldyAbsolute, .ldyAbsoluteX:
                self.ldy(addressingMode: opcode.addressingMode)
            case .lsrAccumulator, .lsrZeroPage, .lsrZeroPageX, .lsrAbsolute, .lsrAbsoluteX:
                self.lsr(addressingMode: opcode.addressingMode)
            case .nopImplicit1, .nopImplicit2, .nopImplicit3, .nopImplicit4, .nopImplicit5, .nopImplicit6, .nopImplicit7,
                    .nopImmediate1, .nopImmediate2, .nopImmediate3, .nopImmediate4, .nopImmediate5,
                    .nopAbsolute,
                    .nopAbsoluteX1, .nopAbsoluteX2, .nopAbsoluteX3, .nopAbsoluteX4, .nopAbsoluteX5, .nopAbsoluteX6,
                    .nopZeroPage1, .nopZeroPage2, .nopZeroPage3,
                    .nopZeroPageX1, .nopZeroPageX2, .nopZeroPageX3, .nopZeroPageX4, .nopZeroPageX5, .nopZeroPageX6:
                self.nop(addressingMode: opcode.addressingMode)
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
            case .rlaAbsolute, .rlaAbsoluteX, .rlaAbsoluteY, .rlaZeroPage, .rlaZeroPageX, .rlaIndirectX, .rlaIndirectY:
                self.rla(addressingMode: opcode.addressingMode)
            case .rolAccumulator, .rolZeroPage, .rolZeroPageX, .rolAbsolute, .rolAbsoluteX:
                self.rol(addressingMode: opcode.addressingMode)
            case .rorAccumulator, .rorZeroPage, .rorZeroPageX, .rorAbsolute, .rorAbsoluteX:
                self.ror(addressingMode: opcode.addressingMode)
            case .rraAbsolute, .rraAbsoluteX, .rraAbsoluteY, .rraZeroPage, .rraZeroPageX, .rraIndirectX, .rraIndirectY:
                self.rra(addressingMode: opcode.addressingMode)
            case .rti:
                self.rti()
            case .rts:
                self.rts()
            case .saxZeroPage, .saxZeroPageY, .saxAbsolute, .saxIndirectX:
                self.sax(addressingMode: opcode.addressingMode)
            case .sbcImmediate1, .sbcImmediate2, .sbcZeroPage, .sbcZeroPageX, .sbcAbsolute, .sbcAbsoluteX, .sbcAbsoluteY, .sbcIndirectX, .sbcIndirectY:
                self.sbc(addressingMode: opcode.addressingMode)
            case .sec:
                self.sec()
            case .sed:
                self.sed()
            case .sei:
                self.sei()
            case .sloAbsolute, .sloAbsoluteX, .sloAbsoluteY, .sloZeroPage, .sloZeroPageX, .sloIndirectX, .sloIndirectY:
                self.slo(addressingMode: opcode.addressingMode)
            case .sreAbsolute, .sreAbsoluteX, .sreAbsoluteY, .sreZeroPage, .sreZeroPageX, .sreIndirectX, .sreIndirectY:
                self.sre(addressingMode: opcode.addressingMode)
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

            let totalCycles = opcode.cycles + extraCycles
            let result = self.bus.tick(cycles: totalCycles)

            if !programCounterMutated {
                self.programCounter += UInt16(opcode.instructionLength - 1)
            }

            return result
        } else {
            fatalError("Whoops! Instruction \(byte) at \(programCounter) not recognized!!!")
        }
    }

//    mutating func run() {
//        while true {
//            self.executeInstruction()
//        }
//    }

    func wasPageCrossed(fromAddress: UInt16, toAddress: UInt16) -> Bool {
        return (fromAddress & 0xFF00) != (toAddress & 0xFF00)
    }

    mutating func getAbsoluteAddress(addressingMode: AddressingMode) -> (UInt16, Bool) {
        let address = self.programCounter

        switch addressingMode {
        case .immediate:
            return (address, false)
        case .zeroPage:
            return (UInt16(self.readByte(address: address)), false)
        case .zeroPageX:
            let baseAddress = self.readByte(address: address)
            return (UInt16(baseAddress &+ self.xRegister), false)
        case .zeroPageY:
            let baseAddress = self.readByte(address: address)
            return (UInt16(baseAddress &+ self.yRegister), false)
        case .absolute:
            return (self.readWord(address: address), false)
        case .absoluteX:
            let baseAddress = self.readWord(address: address)
            let newAddress = baseAddress &+ UInt16(self.xRegister)
            return (newAddress, wasPageCrossed(fromAddress: baseAddress, toAddress: newAddress))
        case .absoluteY:
            let baseAddress = self.readWord(address: address)
            let newAddress = baseAddress &+ UInt16(self.yRegister)
            return (newAddress, wasPageCrossed(fromAddress: baseAddress, toAddress: newAddress))
        case .indirect:
            // See http://www.6502.org/tutorials/6502opcodes.html#JMP for more details
            // on this implementation, which only applies to the 0x6C opcode.
            let baseAddress = self.readWord(address: address)
            if baseAddress & 0x00FF == 0x00FF {
                let lowByte = self.readByte(address: baseAddress)
                let highByte = self.readByte(address: baseAddress & 0xFF00)
                return (UInt16(lowByte: lowByte, highByte: highByte), false)
            }

            return (self.readWord(address: baseAddress), false)
        case .indirectX:
            // operand_ptr = *(void **)(constant_byte + x_register)
            let baseAddress = self.readByte(address: address)
            let indirectAddress = baseAddress &+ self.xRegister

            let lowByte = self.readByte(address: UInt16(indirectAddress))
            let highByte = self.readByte(address: UInt16(indirectAddress &+ 1))

            return (UInt16(lowByte: lowByte, highByte: highByte), false)
        case .indirectY:
            // operand_ptr = *((void **)constant_byte) + y_register
            let zeroPageAddress = self.readByte(address: address)

            let lowByte = self.readByte(address: UInt16(zeroPageAddress))
            let highByte = self.readByte(address: UInt16(zeroPageAddress &+ 1))

            let baseAddress = UInt16(lowByte: lowByte, highByte: highByte)
            let newAddress = baseAddress &+ UInt16(self.yRegister)
            return (newAddress, wasPageCrossed(fromAddress: baseAddress, toAddress: newAddress))
        case .relative:
            let offset = UInt16(self.readByte(address: address)) &+ 1
            let newAddress = if offset >> 7 == 0 {
                self.programCounter &+ offset
            } else {
                self.programCounter &+ offset &- 0x0100
            }

            return (newAddress, wasPageCrossed(fromAddress: address + 1, toAddress: newAddress))
        default:
            fatalError("Addressing mode not supported!")
        }
    }

    // NOTA BENE: Called directly by the tracer
    func getAbsoluteAddressWithoutMutating(addressingMode: AddressingMode, address: UInt16) -> UInt16 {
        switch addressingMode {
        case .immediate:
            return address
        case .zeroPage:
            return UInt16(self.readByteWithoutMutating(address: address))
        case .zeroPageX:
            let baseAddress = self.readByteWithoutMutating(address: address)
            return UInt16(baseAddress &+ self.xRegister)
        case .zeroPageY:
            let baseAddress = self.readByteWithoutMutating(address: address)
            return UInt16(baseAddress &+ self.yRegister)
        case .absolute:
            return self.readWordWithoutMutating(address: address)
        case .absoluteX:
            let baseAddress = self.readWordWithoutMutating(address: address)
            return baseAddress &+ UInt16(self.xRegister)
        case .absoluteY:
            let baseAddress = self.readWordWithoutMutating(address: address)
            return baseAddress &+ UInt16(self.yRegister)
        case .indirect:
            // See http://www.6502.org/tutorials/6502opcodes.html#JMP for more details
            // on this implementation, which only applies to the 0x6C opcode.
            let baseAddress = self.readWordWithoutMutating(address: address)
            if baseAddress & 0x00FF == 0x00FF {
                let lowByte = self.readByteWithoutMutating(address: baseAddress)
                let highByte = self.readByteWithoutMutating(address: baseAddress & 0xFF00)
                return UInt16(highByte) << 8 | UInt16(lowByte)
            }

            return self.readWordWithoutMutating(address: baseAddress)
        case .indirectX:
            // operand_ptr = *(void **)(constant_byte + x_register)
            let baseAddress = self.readByteWithoutMutating(address: address)
            let indirectAddress = baseAddress &+ self.xRegister

            let lowByte = self.readByteWithoutMutating(address: UInt16(indirectAddress))
            let highByte = self.readByteWithoutMutating(address: UInt16(indirectAddress &+ 1))

            return UInt16(highByte) << 8 | UInt16(lowByte)
        case .indirectY:
            // operand_ptr = *((void **)constant_byte) + y_register
            let baseAddress = self.readByteWithoutMutating(address: address)

            let lowByte = self.readByteWithoutMutating(address: UInt16(baseAddress))
            let highByte = self.readByteWithoutMutating(address: UInt16(baseAddress &+ 1))

            let indirectAddress = UInt16(highByte) << 8 | UInt16(lowByte)
            return indirectAddress &+ UInt16(self.yRegister)
        case .relative:
            let offset = UInt16(self.readByteWithoutMutating(address: address)) &+ 1
            let address = if offset >> 7 == 0 {
                self.programCounter &+ offset
            } else {
                self.programCounter &+ offset &- 0x0100
            }

            return address
        default:
            fatalError("Addressing mode not supported!")
        }
    }

    mutating func readWord(address: UInt16) -> UInt16 {
        let lowByte = self.readByte(address: address)
        let highByte = self.readByte(address: address + 1)
        return UInt16(lowByte: lowByte, highByte: highByte)
    }

    mutating func readByte(address: UInt16) -> UInt8 {
        self.bus.readByte(address: address)
    }

    // NOTA BENE: Called directly by the tracer, as well as by readByte()
    func readByteWithoutMutating(address: UInt16) -> UInt8 {
        self.bus.readByteWithoutMutating(address: address)
    }

    // NOTA BENE: Called directly by the tracer, as well as by readWord()
    func readWordWithoutMutating(address: UInt16) -> UInt16 {
        let lowByte = self.readByteWithoutMutating(address: address)
        let highByte = self.readByteWithoutMutating(address: address + 1)
        return UInt16(lowByte: lowByte, highByte: highByte)
    }

    mutating public func writeByte(address: UInt16, byte: UInt8) {
        self.bus.writeByte(address: address, byte: byte)
    }

    mutating func writeWord(address: UInt16, word: UInt16) {
        self.writeByte(address: address, byte: word.lowByte);
        self.writeByte(address: address + 1, byte: word.highByte);
    }
}

extension CPU {
    mutating public func buttonDown(button: JoypadButton) {
        self.writeByte(address: 0x00FF, byte: button.rawValue)
    }
}

extension CPU {
    mutating public func updateScreenBuffer(_ screenBuffer: inout [NESColor]) {
        self.bus.ppu.updateScreenBuffer(&screenBuffer)
    }
}

extension CPU {
    mutating private func interruptNmi() {
        self.pushStack(word: self.programCounter)

        var copy = self.statusRegister
        copy[.break] = false
        copy[.unused] = true

        self.pushStack(byte: copy.rawValue)
        self.statusRegister[.interrupt] = true

        let _ = self.bus.tick(cycles: 2)
        self.programCounter = self.readWord(address: Self.nmiVectorAddress)
    }
}
