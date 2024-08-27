//
//  JoypadButton.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/29/24.
//

public struct JoypadButton: OptionSet {
    public var rawValue: UInt8

    public init(rawValue: UInt8 = 0b0000_0000) {
        self.rawValue = rawValue
    }

    //  7 6 5 4 3 2 1 0
    //  R L D U S L B A
    //  | | | | | | | +--- Button A
    //  | | | | | | +----- Button B
    //  | | | | | +------- Select
    //  | | | | +--------- Start
    //  | | | +----------- Up
    //  | | +------------- Down
    //  | +--------------- Left
    //  +----------------- Right
    public static let buttonA = Self(rawValue: 1 << 0)
    public static let buttonB = Self(rawValue: 1 << 1)
    public static let select = Self(rawValue: 1 << 2)
    public static let start = Self(rawValue: 1 << 3)
    public static let up = Self(rawValue: 1 << 4)
    public static let down = Self(rawValue: 1 << 5)
    public static let left = Self(rawValue: 1 << 6)
    public static let right = Self(rawValue: 1 << 7)

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
