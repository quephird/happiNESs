//
//  ControllerRegister.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/8/24.
//

public struct ControllerRegister: OptionSet {
    public var rawValue: UInt8

    public init(rawValue: UInt8 = 0) {
        self.rawValue = rawValue
    }

    //  7 6 5 4 3 2 1 0
    //  V P H B S I N N
    //  | | | | | | | +--- Nametable bit 1
    //  | | | | | | +----- Nametable bit 2
    //  | | | | | |        (00 = $2000; 01 = $2400; 10 = $2800; 11 = $2C00)
    //  | | | | | +------- VRAM address increment per CPU read/write of PPUDATA
    //  | | | | |          (0: add 1, going across; 1: add 32, going down)
    //  | | | | +--------- Sprite pattern bank index for 8x8 sprites
    //  | | | |            (0: $0000; 1: $1000; ignored in 8x16 mode)
    //  | | | +----------- Background pattern bank index
    //  | | |              (0: $0000; 1: $1000)
    //  | | +------------- Sprite size
    //  | |                (0: 8x8 pixels; 1: 8x16 pixels)
    //  | +--------------- PPU master/slave select
    //  |                  (0: read backdrop from EXT pins; 1: output color on EXT pins)
    //  +----------------- Generate an NMI at the start of the vertical blanking interval
    //                     (0: off; 1: on)
    public static let nametable1 = Self(rawValue: 1 << 0)
    public static let nametable2 = Self(rawValue: 1 << 1)
    public static let vramAddressIncrement = Self(rawValue: 1 << 2)
    public static let spritePatternBankIndex = Self(rawValue: 1 << 3)
    public static let backgroundPatternBankIndex = Self(rawValue: 1 << 4)
    public static let spriteSize = Self(rawValue: 1 << 5)
    public static let masterSlaveSelect = Self(rawValue: 1 << 6)
    public static let generateNmi = Self(rawValue: 1 << 7)

    subscript (_ flags: Self) -> Bool {
        get {
            self.isSuperset(of: flags)
        }
        set {
            if newValue {
                self.insert(flags)
            } else {
                self.remove(flags)
            }
        }
    }

    public func vramAddressIncrement() -> UInt8 {
        if self[.vramAddressIncrement] {
            return 32
        } else {
            return 1
        }
    }

    public func nametableAddress() -> UInt16 {
        switch self.rawValue & 0b0000_0011 {
        case 0b0000_0000: 0x2000
        case 0b0000_0001: 0x2400
        case 0b0000_0010: 0x2800
        case 0b0000_0011: 0x2C00
        default:
            fatalError("Impossible bit configuration for nametable address")
        }
    }

    mutating public func update(byte: UInt8) {
        self.rawValue = byte
    }
}
