//
//  Axrom.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/28/24.
//

class Axrom: Mapper {
    public unowned var cartridge: Cartridge

    init(cartridge: Cartridge) {
        self.cartridge = cartridge
    }

    public func readByte(address: UInt16) -> UInt8 {
        switch address {
        case 0x0000 ... 0x1FFF:
            let memoryIndex = Int(address)
            return cartridge.chrMemory[memoryIndex]
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            return self.cartridge.sram[index]
        case 0x8000 ... 0xFFFF:
            let memoryIndex = cartridge.prgBankIndex * 0x8000 + Int(address - 0x8000)
            return cartridge.prgMemory[Int(memoryIndex)]
        default:
            print("Attempted to read cartridge at address: \(address)")
            return 0x00
        }
    }

    public func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case 0x0000 ... 0x1FFF:
            let memoryIndex = Int(address)
            cartridge.chrMemory[memoryIndex] = byte
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            self.cartridge.sram[index] = byte
        case 0x8000 ... 0xFFFF:
            let bankIndex = byte & 0b0000_0111
            cartridge.prgBankIndex = Int(bankIndex)

            let mirrorBit = (byte & 0b0001_0000) >> 4
            self.cartridge.mirroring = mirrorBit == 1 ? .singleScreen1 : .singleScreen0
        default:
            print("Attempted to write to NROM cartridge at address: \(address)")
        }
    }

    func tick(ppu: borrowing PPU) {
        // No-op for this mapper type
    }
}
