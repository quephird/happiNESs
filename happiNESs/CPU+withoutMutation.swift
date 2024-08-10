//
//  CPU+withoutMutation.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/10/24.
//

extension CPU {
    func readByteWithoutMutating(address: UInt16) -> UInt8 {
        self.bus.readByteWithoutMutating(address: address)
    }

    func readWordWithoutMutating(address: UInt16) -> UInt16 {
        let lowByte = self.readByteWithoutMutating(address: address)
        let highByte = self.readByteWithoutMutating(address: address + 1)
        return UInt16(lowByte: lowByte, highByte: highByte)
    }

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
}
