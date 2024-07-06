//
//  Bus.swift
//  happiNESs
//
//  Created by Danielle Kefford on 7/4/24.
//

public struct Bus {
    static let ramMirrorsBegin: UInt16 = 0x0000;
    static let ramMirrorsEnd: UInt16 = 0x1FFF;
    static let ppuRegistersMirrorsBegin: UInt16 = 0x2000;
    static let ppuRegistersMirrorsEnd: UInt16 = 0x3FFF;

    var vram: [UInt8]
    var rom: Rom

    public init(rom: Rom) {
        self.vram = [UInt8](repeating: 0x00, count: 2048)
        self.rom = rom
    }
}

extension Bus {
    private func readPrgRom(address: UInt16) -> UInt8 {
        var addressOffset = address - 0x8000

        // Mirror if needed
        if self.rom.prgRom.count == 0x4000 && addressOffset >= 0x4000 {
            addressOffset = addressOffset % 0x4000
        }

        return self.rom.prgRom[Int(addressOffset)]
    }

    func readByte(address: UInt16) -> UInt8 {
        switch address {
        case Self.ramMirrorsBegin ... Self.ramMirrorsEnd:
            let vramAddress = Int(address & 0b0000_0111_1111_1111)
            return self.vram[vramAddress]
        case Self.ppuRegistersMirrorsBegin ... Self.ppuRegistersMirrorsEnd:
            let ppuAddress = Int(address & 0b0010_0000_0000_0111)
            fatalError("TODO! Implement PPU access!")
        case 0x8000 ... 0xFFFF:
            return self.readPrgRom(address: address)
        default:
            print("TODO: Implement memory reading for this address: \(address)")
            return 0x00
        }
    }

    mutating func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case Self.ramMirrorsBegin ... Self.ramMirrorsEnd:
            let vramAddress = Int(address & 0b0000_0111_1111_1111)
            self.vram[vramAddress] = byte
        case Self.ppuRegistersMirrorsBegin ... Self.ppuRegistersMirrorsEnd:
            let ppuAddress = Int(address & 0b0010_0000_0000_0111)
            fatalError("TODO! Implement PPU access!")
        case 0x8000 ... 0xFFFF:
            fatalError("Attempt to write to cartridge ROM space")
        default:
            print("TODO: Implement memory writing for this address: \(address)")
        }
    }
}
