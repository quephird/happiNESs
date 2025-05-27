//
//  CPU+instructions.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/6/24.
//

extension CPU {
    func adc(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let carry: UInt8 = self.status[.carry] ? 0x01 : 0x00

        let sum = UInt16(self.accumulator) + UInt16(value) + UInt16(carry)
        self.status[.carry] = sum > 0xFF
        self.status[.overflow] = ((UInt8(sum & 0xFF) ^ self.accumulator) & (UInt8(sum & 0xFF) ^ value) & 0x80) == 0x80
        self.accumulator = UInt8(sum & 0xFF)
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    func and(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.accumulator &= value
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    func asl(addressingMode: AddressingMode) -> (Bool, Int) {
        if addressingMode == .accumulator {
            self.status[.carry] = self.accumulator >> 7 == 1
            self.accumulator <<= 1
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);

            self.status[.carry] = value >> 7 == 1
            self.writeByte(address: address, byte: value << 1)
            self.updateZeroAndNegativeFlags(result: value << 1)
        }

        return (false, 0)
    }

    func asr(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);

        let aAndMemory = self.accumulator & value
        self.status[.carry] = (aAndMemory & 0b0000_0001) == 1
        self.accumulator = aAndMemory >> 1

        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, 0)
    }

    func bcc() -> (Bool, Int) {
        return self.branch(condition: !self.status[.carry])
    }

    func bcs() -> (Bool, Int) {
        return self.branch(condition: self.status[.carry])
    }

    func beq() -> (Bool, Int) {
        return self.branch(condition: self.status[.zero])
    }

    private func branch(condition: Bool) -> (Bool, Int) {
        if condition {
            let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: .relative)
            self.programCounter = address
            let extraCycles = 1 + (pageCrossed ? 1 : 0)
            return (true, extraCycles)
        }

        return (false, 0)
    }

    func bit(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        let result = self.accumulator & value;
        self.status[.negative] = value >> 7 == 1
        self.status[.overflow] = value >> 6 & 0b0000_0001 == 1
        self.status[.zero] = result == 0

        return (false, 0)
    }

    func bmi() -> (Bool, Int) {
        return self.branch(condition: self.status[.negative])
    }

    func bne() -> (Bool, Int) {
        return self.branch(condition: !self.status[.zero])
    }

    func bpl() -> (Bool, Int) {
        return self.branch(condition: !self.status[.negative])
    }

    func brk() -> (Bool, Int) {
        // NOTA BENE: We've already advanced the program counter upon consuming the
        // `BRK` byte; now we need to advance it one more time since the byte after
        // the instruction is ignored, per the documentation. See
        //
        //     https://www.pagetable.com/c64ref/6502/?tab=2#BRK
        self.programCounter += 1
        self.pushStack(word: self.programCounter)
        // ACHTUNG! We need to set the B flag upon pushing to the stack!
        //
        //     https://www.nesdev.org/wiki/Status_flags#The_B_flag
        self.pushStack(byte: self.status | 0b0001_0000)
        self.programCounter = self.readWord(address: Self.interruptVectorAddress)
        self.status[.interruptsDisabled] = true

        return (true, 0)
    }

    func bvc() -> (Bool, Int) {
        return self.branch(condition: !self.status[.overflow])
    }

    func bvs() -> (Bool, Int) {
        return self.branch(condition: self.status[.overflow])
    }

    func clearBit(bit: RegisterBit) {
        self.status[bit] = false
    }

    func clc() -> (Bool, Int) {
        self.clearBit(bit: .carry)

        return (false, 0)
    }

    func cld() -> (Bool, Int) {
        self.clearBit(bit: .decimalMode)

        return (false, 0)
    }

    func cli() -> (Bool, Int) {
        self.clearBit(bit: .interruptsDisabled)

        return (false, 0)
    }

    func clv() -> (Bool, Int) {
        self.clearBit(bit: .overflow)

        return (false, 0)
    }

    private func compareMemory(addressingMode: AddressingMode, to registerValue: UInt8) -> Bool {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let memoryValue = self.readByte(address: address)

        self.status[.carry] = (memoryValue <= registerValue)
        self.updateZeroAndNegativeFlags(result: registerValue &- memoryValue)

        return pageCrossed
    }

    func cmp(addressingMode: AddressingMode) -> (Bool, Int) {
        let pageCrossed = self.compareMemory(addressingMode: addressingMode, to: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    func cpx(addressingMode: AddressingMode) -> (Bool, Int) {
        let _ = self.compareMemory(addressingMode: addressingMode, to: self.xRegister)

        return (false, 0)
    }

    func cpy(addressingMode: AddressingMode) -> (Bool, Int) {
        let _ = self.compareMemory(addressingMode: addressingMode, to: self.yRegister)

        return (false, 0)
    }

    func dcp(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)

        let newValue = value &- 1
        self.writeByte(address: address, byte: newValue)
        self.status[.carry] = newValue <= self.accumulator
        self.updateZeroAndNegativeFlags(result: self.accumulator &- newValue)

        return (false, 0)
    }

    func dec(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.writeByte(address: address, byte: value &- 1)
        self.updateZeroAndNegativeFlags(result: self.readByte(address: address))

        return (false, 0)
    }

    func dex() -> (Bool, Int) {
        self.xRegister = self.xRegister &- 1
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, 0)
    }

    func dey() -> (Bool, Int) {
        self.yRegister = self.yRegister &- 1
        self.updateZeroAndNegativeFlags(result: self.yRegister)

        return (false, 0)
    }


    func eor(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator ^= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    func inc(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.writeByte(address: address, byte: value &+ 1)
        self.updateZeroAndNegativeFlags(result: self.readByte(address: address))

        return (false, 0)
    }

    func inx() -> (Bool, Int) {
        self.xRegister = self.xRegister &+ 1
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, 0)
    }

    func iny() -> (Bool, Int) {
        self.yRegister = self.yRegister &+ 1
        self.updateZeroAndNegativeFlags(result: self.yRegister)

        return (false, 0)
    }

    func isb(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        self.writeByte(address: address, byte: self.readByte(address: address) &+ 1)

        // ACHTUNG! This appears to ignore page crossings
        let (programCounterMutated, _) = self.sbc(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    func jmp(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        self.programCounter = address

        return (true, 0)
    }

    func jsr() -> (Bool, Int) {
        let (subroutineAddress, _) = self.getAbsoluteAddress(addressingMode: .absolute);
        // ACHTUNG!!! Note that this is pointing to the last byte of the `JSR` instruction!
        let returnAddress = self.programCounter + 2 - 1
        self.pushStack(word: returnAddress)
        self.programCounter = subroutineAddress

        return (true, 0)
    }

    func lax(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);

        self.accumulator = value
        self.xRegister = value
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    func lda(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);
        self.accumulator = value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    func ldx(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);
        self.xRegister = value;
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, pageCrossed ? 1 : 0)
    }

    func ldy(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);
        self.yRegister = value;
        self.updateZeroAndNegativeFlags(result: self.yRegister)

        return (false, pageCrossed ? 1 : 0)
    }

    func lsr(addressingMode: AddressingMode) -> (Bool, Int) {
        if addressingMode == .accumulator {
            self.status[.carry] = self.accumulator & 0b0000_0001 == 1
            self.accumulator >>= 1
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);

            self.status[.carry] = value & 0b0000_0001 == 1
            self.writeByte(address: address, byte: value >> 1)
            self.updateZeroAndNegativeFlags(result: value >> 1)
        }

        return (false, 0)
    }

    func nop(addressingMode: AddressingMode) -> (Bool, Int) {
        if addressingMode == .implicit {
            return (false, 0)
        }

        let (_, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        return (false, pageCrossed ? 1 : 0)
    }

    func ora(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address);
        self.accumulator |= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    public func pushStack(byte: UInt8) {
        self.writeByte(address: Self.stackBottomMemoryAddress + UInt16(self.stackPointer), byte: byte)
        self.stackPointer = self.stackPointer &- 1
    }

    public func pushStack(word: UInt16) {
        self.pushStack(byte: word.highByte)
        self.pushStack(byte: word.lowByte)
    }

    private func popStack() -> UInt8 {
        self.stackPointer = self.stackPointer &+ 1
        let byte = self.readByte(address: Self.stackBottomMemoryAddress + UInt16(self.stackPointer))
        return byte
    }

    func pha() -> (Bool, Int) {
        self.pushStack(byte: self.accumulator)

        return (false, 0)
    }

    func php() -> (Bool, Int) {
        // NOTA BENE: We need to set the so-called B flag upon a push to the stack:
        //
        //    https://www.nesdev.org/wiki/Status_flags#The_B_flag
        self.pushStack(byte: self.status | 0b0011_0000)

        return (false, 0)
    }

    func pla() -> (Bool, Int) {
        self.accumulator = self.popStack()
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, 0)
    }

    func plp() -> (Bool, Int) {
        self.status = self.popStack()
        self.status[.break] = false
        self.status[.cpuStatusUnused] = true

        return (false, 0)
    }

    func rla(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let oldCarry: UInt8 = self.status[.carry] ? 1 : 0
        self.writeByte(address: address, byte: (value << 1) | oldCarry)
        self.status[.carry] = (value >> 7) == 1

        // ACHTUNG! It appears that page crossings are ignored by this opcode
        let (programCounterMutated, _) = self.and(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    func rol(addressingMode: AddressingMode) -> (Bool, Int) {
        let oldCarry: UInt8 = self.status[.carry] ? 1 : 0

        if addressingMode == .accumulator {
            let carry = self.accumulator >> 7
            self.status[.carry] = carry == 1
            self.accumulator = (self.accumulator << 1) | oldCarry
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address);
            let carry = value >> 7

            self.status[.carry] = carry == 1
            let newValue = value << 1 | oldCarry
            self.writeByte(address: address, byte: newValue)
            self.updateZeroAndNegativeFlags(result: newValue)
        }

        return (false, 0)
    }

    func ror(addressingMode: AddressingMode) -> (Bool, Int) {
        let oldCarry: UInt8 = self.status[.carry] ? 1 : 0

        if addressingMode == .accumulator {
            self.status[.carry] = self.accumulator & 0b0000_0001 == 1
            self.accumulator = (self.accumulator >> 1) | (oldCarry << 7)
            self.updateZeroAndNegativeFlags(result: self.accumulator)
        } else {
            // Intentionally drop the page-crossed flag on the floor rather than take
            // an extra cycle like most instructions. This seems super-weird and I'm
            // not sure it's correct, but all the docs and other implementations are
            // consistent.
            let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
            let value = self.readByte(address: address)

            self.status[.carry] = value & 0b0000_0001 == 1
            let newValue = (value >> 1) | (oldCarry << 7)
            self.writeByte(address: address, byte: newValue)

            self.updateZeroAndNegativeFlags(result: newValue)
        }

        return (false, 0)
    }

    func rra(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let oldCarry: UInt8 = self.status[.carry] ? 1 : 0
        self.writeByte(address: address, byte: (value >> 1) | oldCarry << 7)
        self.status[.carry] = (value & 0b0000_0001) == 1

        // ACHTUNG! This instruction also appears to ignore page crossings
        let (programCounterMutated, _) = self.adc(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    func rti() -> (Bool, Int) {
        self.status = self.popStack()
        self.status[.break] = false
        self.status[.cpuStatusUnused] = true

        let addressLow = self.popStack()
        let addressHigh = self.popStack()
        let address = UInt16(lowByte: addressLow, highByte: addressHigh)
        self.programCounter = address

        return (true, 0)
    }

    func rts() -> (Bool, Int) {
        let addressLow = self.popStack()
        let addressHigh = self.popStack()
        // ACHTUNG!!! Note that this only works in conjunction with the `JSR` instruction!
        let address = UInt16(lowByte: addressLow, highByte: addressHigh) + 1
        self.programCounter = address

        return (true, 0)
    }

    func sax(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        self.writeByte(address: address, byte: self.accumulator & self.xRegister)

        return (false, 0)
    }

    func sbc(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        let carry: UInt8 = self.status[.carry] ? 0x01 : 0x00
        let oldAccumulator = self.accumulator

        self.accumulator = oldAccumulator &- value &- (1 - carry)
        self.status[.carry] = Int16(oldAccumulator) - Int16(value) - Int16(1 - carry) >= 0
        self.status[.overflow] = (oldAccumulator ^ value) & 0x80 != 0 && (oldAccumulator ^ self.accumulator) & 0x80 != 0
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, pageCrossed ? 1 : 0)
    }

    func sbx(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, pageCrossed) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)

        let aAndX = self.accumulator & self.xRegister
        let carry: UInt8 = self.status[.carry] ? 0x01 : 0x00
        self.xRegister = (aAndX) &- value

        self.status[.carry] = Int16(aAndX) - Int16(value) - Int16(1 - carry) >= 0
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, pageCrossed ? 1 : 0)
    }

    private func setBit(bit: RegisterBit) {
        self.status[bit] = true
    }

    func sec() -> (Bool, Int) {
        self.setBit(bit: .carry)

        return (false, 0)
    }

    func sed() -> (Bool, Int) {
        self.setBit(bit: .decimalMode)

        return (false, 0)
    }

    func sei() -> (Bool, Int) {
        self.setBit(bit: .interruptsDisabled)

        return (false, 0)
    }

    func sha(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let result = self.accumulator & self.xRegister & address.highByte
        self.writeByte(address: address, byte: result)

        return (false, 0)
    }

    func slo(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let oldValue = self.readByte(address: address)
        self.writeByte(address: address, byte: oldValue << 1)
        self.status[.carry] = (oldValue >> 7) == 1

        // ACHTUNG! It appears that page crossings are ignored by this opcode
        let (programCounterMutated, _) = self.ora(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    func sre(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        let value = self.readByte(address: address)
        self.writeByte(address: address, byte: value >> 1)
        self.status[.carry] = (value & 0b0000_0001) == 1

        // ACHTUNG! It appears that page crossings are ignored by this opcode
        let (programCounterMutated, _) = self.eor(addressingMode: addressingMode)
        return (programCounterMutated, 0)
    }

    func sta(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode)
        self.writeByte(address: address, byte: self.accumulator)

        return (false, 0)
    }

    func stx(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
        self.writeByte(address: address, byte: self.xRegister);

        return (false, 0)
    }

    func sty(addressingMode: AddressingMode) -> (Bool, Int) {
        let (address, _) = self.getAbsoluteAddress(addressingMode: addressingMode);
        self.writeByte(address: address, byte: self.yRegister);

        return (false, 0)
    }

    func tax() -> (Bool, Int) {
        self.xRegister = self.accumulator;
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, 0)
    }

    func tay() -> (Bool, Int) {
        self.yRegister = self.accumulator;
        self.updateZeroAndNegativeFlags(result: self.yRegister)

        return (false, 0)
    }

    func tsx() -> (Bool, Int) {
        self.xRegister = self.stackPointer;
        self.updateZeroAndNegativeFlags(result: self.xRegister)

        return (false, 0)
    }

    func txa() -> (Bool, Int) {
        self.accumulator = self.xRegister;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, 0)
    }

    func txs() -> (Bool, Int) {
        self.stackPointer = self.xRegister;

        return (false, 0)
    }

    func tya() -> (Bool, Int) {
        self.accumulator = self.yRegister;
        self.updateZeroAndNegativeFlags(result: self.accumulator)

        return (false, 0)
    }

    private func updateZeroAndNegativeFlags(result: UInt8) {
        self.status[.zero] = result == 0
        self.status[.negative] = (result & 0b1000_0000) != 0
    }
}
