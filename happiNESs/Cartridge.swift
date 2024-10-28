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

    public var mirroring: Mirroring
    public var mapper: Mapper
    public var prgMemory: [UInt8]
    public var prgBankIndex: Int
    public var chrMemory: [UInt8]
    public var chrBankIndex: Int

    public init(bytes: [UInt8]) throws {
        if Array(bytes[0..<4]) != Self.nesTag {
            throw NESError.romNotInInesFormat
        }

        let inesVersion = (bytes[7] >> 2) & 0b11;
        if inesVersion != 0 {
            throw NESError.versionTwoPointOhNotSupported
        }

        let fourScreenBit = bytes[6] & 0b1000 != 0;
        let horizontalVerticalbit = bytes[6] & 0b1 != 0;
        let mirroring: Mirroring = switch (fourScreenBit, horizontalVerticalbit) {
        case (true, _): .fourScreen
        case (false, true): .vertical
        case (false, false): .horizontal
        }

        let mapperNumber = (bytes[7] & 0b1111_0000) | (bytes[6] >> 4)
        guard let mapper = Mapper(rawValue: mapperNumber) else {
            throw NESError.mapperNotSupported(Int(mapperNumber))
        }
        self.mapper = mapper

        let prgRomSize = Int(bytes[4]) * Self.prgMemoryPageSize
        let chrRomSize = Int(bytes[5]) * Self.chrMemoryPageSize
        let skipTrainerBit = bytes[6] & 0b100 != 0
        let prgMemoryStart = 16 + (skipTrainerBit ? 512 : 0)
        let chrMemoryStart = prgMemoryStart + prgRomSize
        let prgMemory = Array(bytes[prgMemoryStart ..< (prgMemoryStart + prgRomSize)])
        let chrMemory = if chrRomSize == 0 {
            [UInt8](repeating: 0x00, count: Self.chrMemoryPageSize)
        } else {
            Array(bytes[chrMemoryStart ..< (chrMemoryStart + chrRomSize)])
        }

        self.mirroring = mirroring
        self.mapper = mapper
        self.prgMemory = prgMemory
        self.prgBankIndex = 0
        self.chrMemory = chrMemory
        self.chrBankIndex = 0
    }

    public func writeByte(address: UInt16, byte: UInt8) {
        switch self.mapper {
        case .nrom:
            break
        case .uxrom:
            self.mapper.setPrgBankIndex(byte: byte, cartridge: self)
        case .cnrom:
            self.mapper.setChrBankIndex(byte: byte, cartridge: self)
        case .axrom:
            let mirrorBit = (byte & 0b0001_0000) >> 4
            self.mirroring = mirrorBit == 1 ? .singleScreen1 : .singleScreen0
            self.mapper.setPrgBankIndex(byte: byte, cartridge: self)
        }
    }

    public func readPrg(address: UInt16) -> UInt8 {
        mapper.readPrg(address: address, cartridge: self)
    }

    public func writePrg(address: UInt16, byte: UInt8) {
        mapper.writePrg(address: address, byte: byte, cartridge: self)
    }

    public func readChr(address: UInt16) -> UInt8 {
        mapper.readChr(address: address, cartridge: self)
    }

    public func readTileFromChr(startAddress: UInt16) -> ArraySlice<UInt8> {
        mapper.readTileFromChr(startAddress: startAddress, cartridge: self)
    }

    public func writeChr(address: UInt16, byte: UInt8) {
        mapper.writeChr(address: address, byte: byte, cartridge: self)
    }
}
