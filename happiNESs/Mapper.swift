//
//  Mapper.swift
//  happiNESs
//
//  Created by Danielle Kefford on 9/20/24.
//

public enum Mapper: UInt8 {
    case nrom = 0
    case uxrom = 2
    case cnrom = 3
    case axrom = 7

    private func logIgnoredWrite(address: UInt16, byte: UInt8, inChr: Bool) {
        print(String(format: "Ignored write of %0x to %0x in \(inChr ? "CHR" : "PRG")", byte, address))
    }

    private func prgMemoryIndex(for address: UInt16, cartridge: Cartridge) -> Int {
        switch self {
        case .nrom, .cnrom:
            return Int(address)
        case .uxrom:
            switch address {
            case 0x8000 ... 0xBFFF:
                return cartridge.prgBankIndex * 0x4000 + Int(address - 0x8000)
            case 0xC000 ... 0xFFFF:
                let lastBankStart = 7 * 0x4000
                return lastBankStart + Int(address - 0xC000)
            default:
                fatalError("Whoops! tried addressing PRG memory out of range")
            }
        case .axrom:
            switch address {
            case 0x8000 ... 0xFFFF:
                return cartridge.prgBankIndex * 0x8000 + Int(address - 0x8000)
            default:
                fatalError("Whoops! tried addressing PRG memory out of range")
            }
        }
    }

    public func setPrgBankIndex(byte: UInt8, cartridge: Cartridge) {
        switch self {
        case .nrom, .cnrom:
            break
        case .uxrom:
            let bankIndex = byte & 0b0000_1111
            cartridge.prgBankIndex = Int(bankIndex)
        case .axrom:
            let bankIndex = byte & 0b0000_0111
            cartridge.prgBankIndex = Int(bankIndex)
        }
    }

    public func readPrg(address: UInt16, cartridge: Cartridge) -> UInt8 {
        switch self {
        case .nrom, .cnrom:
            var addressOffset = address - 0x8000

            // Mirror if needed
            if cartridge.prgMemory.count == 0x4000 {
                addressOffset = addressOffset % 0x4000
            }

            return cartridge.prgMemory[Int(addressOffset)]
        case .uxrom, .axrom:
            let memoryIndex = self.prgMemoryIndex(for: address, cartridge: cartridge)
            return cartridge.prgMemory[memoryIndex]
        }
    }

    private func chrMemoryIndex(for address: UInt16, cartridge: Cartridge) -> Int {
        switch self {
        case .nrom, .uxrom, .axrom:
            return Int(address)
        case .cnrom:
            return cartridge.chrBankIndex * 0x2000 + Int(address)
        }
    }

    public func setChrBankIndex(byte: UInt8, cartridge: Cartridge) {
        switch self {
        case .nrom, .uxrom, .axrom:
            // For some reason Ms. Pacman calls this even though there is
            // no bank switching for NROM games, so for now just ignore it.
            break
        case .cnrom:
            let bankIndex = byte & 0b0000_0011
            cartridge.chrBankIndex = Int(bankIndex)
        }
    }

    public func readChr(address: UInt16, cartridge: Cartridge) -> UInt8 {
        let memoryIndex = self.chrMemoryIndex(for: address, cartridge: cartridge)
        return cartridge.chrMemory[memoryIndex]
    }

    public func writeChr(address: UInt16, byte: UInt8, cartridge: Cartridge) {
        switch self {
        case .nrom, .cnrom:
            logIgnoredWrite(address: address, byte: byte, inChr: true)
        case .uxrom, .axrom:
            let memoryIndex = self.chrMemoryIndex(for: address, cartridge: cartridge)
            cartridge.chrMemory[memoryIndex] = byte
        }
    }
}
