//
//  Uxrom.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/28/24.
//

struct Uxrom: Mapper {
    public unowned var cartridge: Cartridge

    public func readByte(address: UInt16) -> UInt8 {
        switch address {
        case 0x0000 ... 0x1FFF:
            let memoryIndex = Int(address)
            return self.cartridge.chrMemory[memoryIndex]
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            return self.cartridge.sram[index]
        case 0x8000 ... 0xBFFF:
            let memoryIndex = self.cartridge.prgBankIndex * 0x4000 + Int(address - 0x8000)
            return self.cartridge.prgMemory[Int(memoryIndex)]
        case 0xC000 ... 0xFFFF:
            let lastBankStart = 7 * 0x4000
            let memoryIndex = lastBankStart + Int(address - 0xC000)
            return self.cartridge.prgMemory[Int(memoryIndex)]
        default:
            print("Attempted to read cartridge at address: \(address)")
            return 0x00
        }
    }

    public func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case 0x0000 ... 0x1FFF:
            let memoryIndex = Int(address)
            self.cartridge.chrMemory[memoryIndex] = byte
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            self.cartridge.sram[index] = byte
        case 0x8000 ... 0xFFFF:
            let bankIndex = byte & 0b0000_1111
            self.cartridge.prgBankIndex = Int(bankIndex)
        default:
            print("Attempted to write to NROM cartridge at address: \(address)")
        }
    }

    mutating func tick(ppu: borrowing PPU) {
        // No-op for this mapper type
    }
}
