//
//  Uxrom.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/28/24.
//

struct Cnrom: Mapper {
    public unowned var cartridge: Cartridge

    public func readByte(address: UInt16) -> UInt8 {
        switch address {
        case 0x0000 ... 0x1FFF:
            let memoryIndex = self.cartridge.chrBankIndex * 0x2000 + Int(address)
            return self.cartridge.chrMemory[memoryIndex]
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            return self.cartridge.sram[index]
        case 0x8000 ... 0xFFFF:
            var memoryIndex = address - 0x8000

            // Mirror if needed
            if self.cartridge.prgMemory.count == 0x4000 {
                memoryIndex = memoryIndex % 0x4000
            }

            return self.cartridge.prgMemory[Int(memoryIndex)]
        default:
            print("Attempted to read cartridge at address: \(address)")
            return 0x00
        }
    }

    public func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case 0x0000 ... 0x1FFF:
            break
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            self.cartridge.sram[index] = byte
        case 0x8000 ... 0xFFFF:
            let bankIndex = byte & 0b0000_0011
            self.cartridge.chrBankIndex = Int(bankIndex)
        default:
            print("Attempted to write to NROM cartridge at address: \(address)")
        }
    }
}
