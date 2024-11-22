//
//  Rom.swift
//  happiNESs
//
//  Created by Danielle Kefford on 7/4/24.
//

public class Cartridge {
    static let nesTag: [UInt8] = [0x4E, 0x45, 0x53, 0x1A]
    static let prgMemoryPageSize: Int = 16384
    static let chrMemoryPageSize: Int = 8192

    public var timingMode: TimingMode
    public var mirroring: Mirroring
    public var mapperNumber: MapperNumber
    public var prgMemory: [UInt8]
    public var prgBankIndex: Int
    public var chrMemory: [UInt8]
    public var chrBankIndex: Int
    public var sram: [UInt8]

    public lazy var mapper: Mapper = mapperNumber.makeMapper(cartridge: self)

    public init(bytes: [UInt8]) throws {
        if Array(bytes[0..<4]) != Self.nesTag {
            throw NESError.romNotInInesFormat
        }

        let inesVersion = (bytes[7] >> 2) & 0b11;
        if inesVersion > 2 {
            throw NESError.versionTwoPointOhOrEarlierSupported
        }
        let isNesTwoPointOh = inesVersion == 2

        let timingMode = if isNesTwoPointOh {
            TimingMode(rawValue: bytes[9] & 0b0000_0001)
        } else {
            TimingMode(rawValue: bytes[12] & 0b0000_0011)
        }
        guard let timingMode, [.ntsc, .pal].contains(timingMode) else {
            throw NESError.unsupportedTimingMode
        }

        let fourScreenBit = bytes[6] & 0b1000 != 0;
        let horizontalVerticalbit = bytes[6] & 0b1 != 0;
        let mirroring: Mirroring = switch (fourScreenBit, horizontalVerticalbit) {
        case (true, _): .fourScreen
        case (false, true): .vertical
        case (false, false): .horizontal
        }

        let mapperBits = if isNesTwoPointOh {
            ((bytes[8] & 0b0000_1111) << 8) | (bytes[7] & 0b1111_0000) | (bytes[6] >> 4)
        } else {
            (bytes[7] & 0b1111_0000) | (bytes[6] >> 4)
        }
        guard let mapperNumber = MapperNumber(rawValue: UInt16(mapperBits)) else {
            throw NESError.mapperNotSupported(Int(mapperBits))
        }
        self.mapperNumber = mapperNumber

        let prgRomSize: Int
        if isNesTwoPointOh {
            let msbNibble = UInt16(bytes[9]) & 0b0000_1111
            if msbNibble == 0x0F {
                let exponent = Int((bytes[4] & 0b1111_1100) >> 2)
                let multiplier = Int(bytes[4] & 0b0000_0011)
                prgRomSize = (1 << exponent) * (multiplier * 2 + 1)
            } else {
                prgRomSize = Int(msbNibble << 8 | UInt16(bytes[4])) * Self.prgMemoryPageSize
            }
        } else {
            prgRomSize = Int(bytes[4]) * Self.prgMemoryPageSize
        }

        let skipTrainerBit = bytes[6] & 0b100 != 0
        let prgMemoryStart = if isNesTwoPointOh {
            16
        } else {
            16 + (skipTrainerBit ? 512 : 0)
        }
        let prgMemory = Array(bytes[prgMemoryStart ..< (prgMemoryStart + prgRomSize)])

        let chrRomSize: Int
        if isNesTwoPointOh {
            let msbNibble = (UInt16(bytes[9]) & 0b1111_0000) >> 4
            if msbNibble == 0x0F {
                let exponent = Int((bytes[5] & 0b1111_1100) >> 2)
                let multiplier = Int(bytes[5] & 0b0000_0011)
                chrRomSize = (1 << exponent) * (multiplier * 2 + 1)
            } else {
                chrRomSize = Int(msbNibble << 8 | UInt16(bytes[5])) * Self.chrMemoryPageSize
            }
        } else {
            chrRomSize = Int(bytes[5]) * Self.chrMemoryPageSize
        }

        let chrMemoryStart = if isNesTwoPointOh {
            prgMemoryStart + prgRomSize + (skipTrainerBit ? 512 : 0)
        } else {
            prgMemoryStart + prgRomSize
        }
        let chrMemory = if chrRomSize == 0 {
            [UInt8](repeating: 0x00, count: Self.chrMemoryPageSize)
        } else {
            Array(bytes[chrMemoryStart ..< (chrMemoryStart + chrRomSize)])
        }

        self.timingMode = timingMode
        self.mirroring = mirroring
        self.prgMemory = prgMemory
        self.prgBankIndex = 0
        self.chrMemory = chrMemory
        self.chrBankIndex = 0
        self.sram = [UInt8](repeating: 0x00, count: 0x2000)
    }

    public func readByte(address: UInt16) -> UInt8 {
        return self.mapper.readByte(address: address)
    }

    public func writeByte(address: UInt16, byte: UInt8) {
        self.mapper.writeByte(address: address, byte: byte)
    }
}
