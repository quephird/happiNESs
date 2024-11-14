//
//  Register.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/15/24.
//

public typealias Register = UInt8

extension Register {
    subscript (_ flag: RegisterBit) -> Bool {
        get {
            (self & (1 << flag.bitIndex)) > 0
        }
        set {
            self &= ~(1 << flag.bitIndex)
            self |= (newValue ? 1 : 0) << flag.bitIndex
        }
    }
}
