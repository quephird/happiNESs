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
    public var mapper: Mapper
    public var prgRom: [UInt8]
    public var chrRom: [UInt8]
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
        self.chrBankIndex = 0
    }

    public func readPrg(address: UInt16) -> UInt8 {
        mapper.readPrg(address: address, cartridge: self)
    }

    public func readChr(address: UInt16) -> UInt8 {
        mapper.readChr(address: address, cartridge: self)
    }

    public func readTileFromChr(startAddress: UInt16) -> ArraySlice<UInt8> {
        mapper.readTileFromChr(startAddress: startAddress, cartridge: self)
    }

    public func writePrg(address: UInt16, byte: UInt8) {
        mapper.writePrg(address: address, byte: byte, cartridge: self)
    }

    public func writeChr(address: UInt16, byte: UInt8) {
        mapper.writeChr(address: address, byte: byte, cartridge: self)
    }

    public func setChrBankIndex(byte: UInt8) {
        mapper.setChrBankIndex(byte: byte, cartridge: self)
    }
}
