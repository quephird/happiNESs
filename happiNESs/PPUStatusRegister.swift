//
//  PPUStatusRegister.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/16/24.
//

public struct PPUStatusRegister: OptionSet {
    public var rawValue: UInt8

    public init(rawValue: UInt8 = 0b0000_0000) {
        self.rawValue = rawValue
    }

    //  7 6 5 4 3 2 1 0
    //  V S O - - - - -
    //  | | | | | | | +--- Unused
    //  | | | | | | +----- Unused
    //  | | | | | +------- Unused
    //  | | | | +--------- Unused
    //  | | | +----------- Unused
    //  | | +------------- Sprite overflow
    //  | +--------------- Sprite zero hit
    //  +----------------- Vertical blank started
    public static let unused1 = Self(rawValue: 1 << 0)
    public static let unused2 = Self(rawValue: 1 << 1)
    public static let unused3 = Self(rawValue: 1 << 2)
    public static let unused4 = Self(rawValue: 1 << 3)
    public static let unused5 = Self(rawValue: 1 << 4)
    public static let spriteOverflow = Self(rawValue: 1 << 5)
    public static let spriteZeroHit = Self(rawValue: 1 << 6)
    public static let verticalBlankStarted = Self(rawValue: 1 << 7)

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

    mutating func reset() {
        self.rawValue = 0b0000_0000
    }
}
