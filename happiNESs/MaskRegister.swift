//
//  MaskRegister.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/20/24.
//

public struct MaskRegister: OptionSet {
    public var rawValue: UInt8

    public init(rawValue: UInt8 = 0b0000_0000) {
        self.rawValue = rawValue
    }

    //  7 6 5 4 3 2 1 0
    //  B G R s b M m G
    //  | | | | | | | |
    //  | | | | | | | +- Greyscale
    //  | | | | | | |    0: normal color, 1: produce a greyscale display
    //  | | | | | | +--- Background in leftmost 8 pixels of screen
    //  | | | | | |      0: hide, 1: show
    //  | | | | | +----- Sprites in leftmost 8 pixels of screen
    //  | | | | |        0: hide, 1: show
    //  | | | | +------- Background
    //  | | | |          0: hide, 1: show
    //  | | | +--------- Sprites
    //  | | |            0: hide, 1: show
    //  | | +----------- Emphasize red (green on PAL/Dendy)
    //  | +------------- Emphasize green (red on PAL/Dendy)
    //  +--------------- Emphasize blue
    public static let greyscale = Self(rawValue: 1 << 0)
    public static let showBackgroundLeftmostPixels = Self(rawValue: 1 << 1)
    public static let showSpritesLeftmostPixels = Self(rawValue: 1 << 2)
    public static let showBackground = Self(rawValue: 1 << 3)
    public static let showSprites = Self(rawValue: 1 << 4)
    public static let emphasizeRed = Self(rawValue: 1 << 5)
    public static let emphasizeGreen = Self(rawValue: 1 << 6)
    public static let emphasizeBlue = Self(rawValue: 1 << 7)

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

    mutating public func reset() {
        self.rawValue = 0b0000_0000
    }

    mutating public func update(byte: UInt8) {
        self.rawValue = byte
    }
}
