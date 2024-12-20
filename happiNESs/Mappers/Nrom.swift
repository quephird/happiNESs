//
//  Nrom.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/28/24.
//

class Nrom: Mapper {
    public unowned var cartridge: Cartridge

    init(cartridge: Cartridge) {
        self.cartridge = cartridge
    }

    public func readByte(address: UInt16) -> UInt8 {
        switch address {
        case 0x0000 ... 0x1FFF:
            let memoryIndex = Int(address)
            return self.cartridge.chrMemory[memoryIndex]
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            return self.cartridge.sram[index]
        case 0x8000 ... 0xFFFF:
            var memoryIndex = address - 0x8000

            // Mirror if needed
            if self.cartridge.prgMemory.count == 0x4000 {
                memoryIndex = memoryIndex % 0x4000
            } else if self.cartridge.prgMemory.count == 0x2000 {
                // ACHTUNG! This is a hack for games like Galaxian which are one
                // of the very vew games that has an 8Kb PRG ROM
                memoryIndex = memoryIndex % 0x2000
            }

            return self.cartridge.prgMemory[Int(memoryIndex)]
        default:
            print("Attempted to read cartridge at address: \(address)")
            return 0x00
        }
    }

    public func writeByte(address: UInt16, byte: UInt8) {
        // NOTA BENE: No writes expected for this ROM type
        switch address {
        case 0x0000 ... 0x1FFF:
            break
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            self.cartridge.sram[index] = byte
        case 0x8000 ... 0xFFFF:
            break
        default:
            print("Attempted to write to NROM cartridge at address: \(address)")
        }
    }

    func tick(ppu: borrowing PPU) {
        // No-op for this mapper type
    }
}
