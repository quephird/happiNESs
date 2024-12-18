//
//  CPU+memory.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/6/24.
//

extension CPU {
    private func wasPageCrossed(fromAddress: UInt16, toAddress: UInt16) -> Bool {
        return (fromAddress & 0xFF00) != (toAddress & 0xFF00)
    }

    private func performDummyRead(baseAddress: UInt16, offset: UInt8) {
        var dummyAddress = baseAddress
        dummyAddress[.lowByte] = UInt8((UInt16(baseAddress.lowByte) + UInt16(offset)) & 0xFF)
        let _ = self.readByte(address: dummyAddress)
    }

    func getAbsoluteAddress(addressingMode: AddressingMode) -> (UInt16, Bool) {
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
        case .absoluteXDummyRead:
            let baseAddress = self.readWord(address: address)
            let newAddress = baseAddress &+ UInt16(self.xRegister)

            self.performDummyRead(baseAddress: baseAddress, offset: self.xRegister)

            return (newAddress, wasPageCrossed(fromAddress: baseAddress, toAddress: newAddress))
        case .absoluteY:
            let baseAddress = self.readWord(address: address)
            let newAddress = baseAddress &+ UInt16(self.yRegister)
            return (newAddress, wasPageCrossed(fromAddress: baseAddress, toAddress: newAddress))
        case .absoluteYDummyRead:
            let baseAddress = self.readWord(address: address)
            let newAddress = baseAddress &+ UInt16(self.yRegister)

            self.performDummyRead(baseAddress: baseAddress, offset: self.yRegister)

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
        case .indirectYDummyRead:
            let zeroPageAddress = self.readByte(address: address)

            let lowByte = self.readByte(address: UInt16(zeroPageAddress))
            let highByte = self.readByte(address: UInt16(zeroPageAddress &+ 1))

            let baseAddress = UInt16(lowByte: lowByte, highByte: highByte)
            let newAddress = baseAddress &+ UInt16(self.yRegister)

            self.performDummyRead(baseAddress: baseAddress, offset: self.yRegister)

            return (newAddress, wasPageCrossed(fromAddress: baseAddress, toAddress: newAddress))
        case .relative:
            let signedOffset = Int(Int8(bitPattern: self.readByte(address: address)))
            let signedNewAddress = Int(self.programCounter) + signedOffset + 1
            let newAddress = UInt16(truncatingIfNeeded: signedNewAddress)

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
        case .absoluteX, .absoluteXDummyRead:
            let baseAddress = self.readWordWithoutMutating(address: address)
            return baseAddress &+ UInt16(self.xRegister)
        case .absoluteY, .absoluteYDummyRead:
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
        case .indirectY, .indirectYDummyRead:
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

    func readWord(address: UInt16) -> UInt16 {
        let lowByte = self.readByte(address: address)
        let highByte = self.readByte(address: address + 1)
        return UInt16(lowByte: lowByte, highByte: highByte)
    }

    func readByte(address: UInt16) -> UInt8 {
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

    public func writeByte(address: UInt16, byte: UInt8) {
        self.bus.writeByte(address: address, byte: byte)
    }

    func writeWord(address: UInt16, word: UInt16) {
        self.writeByte(address: address, byte: word.lowByte);
        self.writeByte(address: address + 1, byte: word.highByte);
    }
}
