//
//  Rom.swift
//  happiNESs
//
//  Created by Danielle Kefford on 7/4/24.
//

public class Cartridge {
    static let nesTag: [UInt8] = [0x4E, 0x45, 0x53, 0x1A]
    static let prgRomPageSize: Int = 16384
    static let chrRomPageSize: Int = 8192

    public var mirroring: Mirroring
    public var mapper: UInt8
    public var prgRom: [UInt8]
    public var chrRom: [UInt8]

    public init?(bytes: [UInt8]) {
        if Array(bytes[0..<4]) != Self.nesTag {
            return nil
        }

        let inesVersion = (bytes[7] >> 2) & 0b11;
        if inesVersion != 0 {
            return nil
        }

        let fourScreenBit = bytes[6] & 0b1000 != 0;
        let horizontalVerticalbit = bytes[6] & 0b1 != 0;
        let mirroring: Mirroring = switch (fourScreenBit, horizontalVerticalbit) {
        case (true, _): .fourScreen
        case (false, true): .vertical
        case (false, false): .horizontal
        }

        let mapper = (bytes[7] & 0b1111_0000) | (bytes[6] >> 4)

        let prgRomSize = Int(bytes[4]) * Self.prgRomPageSize
        let chrRomSize = Int(bytes[5]) * Self.chrRomPageSize
        let skipTrainerBit = bytes[6] & 0b100 != 0
        let prgRomStart = 16 + (skipTrainerBit ? 512 : 0)
        let chrRomStart = prgRomStart + prgRomSize
        let prgRom = Array(bytes[prgRomStart ..< (prgRomStart + prgRomSize)])
        let chrRom = Array(bytes[chrRomStart ..< (chrRomStart + chrRomSize)])

        self.mirroring = mirroring
        self.mapper = mapper
        self.prgRom = prgRom
        self.chrRom = chrRom
    }

    public func readChrRom(address: UInt16) -> UInt8 {
        return self.chrRom[Int(address)]
    }

    public func readPrgRom(address: UInt16) -> UInt8 {
        var addressOffset = address - 0x8000

        // Mirror if needed
        if self.prgRom.count == 0x4000 && addressOffset >= 0x4000 {
            addressOffset = addressOffset % 0x4000
        }
        return self.prgRom[Int(addressOffset)]
    }
}
