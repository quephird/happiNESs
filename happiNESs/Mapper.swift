//
//  Mapper.swift
//  happiNESs
//
//  Created by Danielle Kefford on 9/20/24.
//

public enum Mapper: UInt8 {
    case nrom = 0
    case cnrom = 3

    private func logIgnoredWrite(address: UInt16, byte: UInt8, inChr: Bool) {
        print(String(format: "Ignored write of %0x to %0x in \(inChr ? "CHR" : "PRG")", byte, address))
    }

    private func chrMemoryIndex(for address: UInt16, cartridge: Cartridge) -> Int {
        switch self {
        case .nrom:
            return Int(address)
        case .cnrom:
            return cartridge.chrBankIndex * 0x2000 + Int(address)
        }
    }

    public func readPrg(address: UInt16, cartridge: Cartridge) -> UInt8 {
        switch self {
        case .nrom, .cnrom:
            var addressOffset = address - 0x8000

            // Mirror if needed
            if cartridge.prgRom.count == 0x4000 {
                addressOffset = addressOffset % 0x4000
            }

            return cartridge.prgRom[Int(addressOffset)]
        }
    }

    public func readChr(address: UInt16, cartridge: Cartridge) -> UInt8 {
        let memoryIndex = self.chrMemoryIndex(for: address, cartridge: cartridge)
        return cartridge.chrRom[memoryIndex]
    }

    public func readTileFromChr(startAddress: UInt16, cartridge: Cartridge) -> ArraySlice<UInt8> {
        let startMemoryIndex = self.chrMemoryIndex(for: startAddress, cartridge: cartridge)
        return cartridge.chrRom[startMemoryIndex ..< startMemoryIndex + 16]
    }

    public func writePrg(address: UInt16, byte: UInt8, cartridge: Cartridge) {
        switch self {
        case .nrom, .cnrom:
            logIgnoredWrite(address: address, byte: byte, inChr: false)
        }
    }

    public func writeChr(address: UInt16, byte: UInt8, cartridge: Cartridge) {
        switch self {
        case .nrom, .cnrom:
            logIgnoredWrite(address: address, byte: byte, inChr: true)
        }
    }

    public func setChrBankIndex(byte: UInt8, cartridge: Cartridge) {
        switch self {
        case .nrom:
            // For some reason Ms. Pacman calls this even though there is
            // no bank switching for NROM games, so for now just ignore it.
            break
        case .cnrom:
            let bankIndex = byte & 0b0000_0011
            cartridge.chrBankIndex = Int(bankIndex)
        }
    }
}
