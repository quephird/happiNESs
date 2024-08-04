//
//  StatusRegister.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/14/24.
//

public struct StatusRegister: OptionSet {
    public var rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    //  7 6 5 4 3 2 1 0
    //  N V U B D I Z C
    //  | | | | | | | +--- Carry Flag
    //  | | | | | | +----- Zero Flag
    //  | | | | | +------- Interrupt Disable
    //  | | | | +--------- Decimal Mode (not used on NES)
    //  | | | +----------- Break Command
    //  | | +------------- Unused (but always 1)
    //  | +--------------- Overflow Flag
    //  +----------------- Negative Flag
    public static let carry = Self(rawValue: 1 << 0)
    public static let zero = Self(rawValue: 1 << 1)
    public static let interrupt = Self(rawValue: 1 << 2)
    public static let decimalMode = Self(rawValue: 1 << 3)
    public static let `break` = Self(rawValue: 1 << 4)
    public static let unused = Self(rawValue: 1 << 5)
    public static let overflow = Self(rawValue: 1 << 6)
    public static let negative = Self(rawValue: 1 << 7)

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
        // TODO: Need to document why this is the case!
        self.rawValue = 0x24
    }
}
