//
//  UInt16+bytes.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/8/24.
//

extension UInt16 {
    public init(lowByte: UInt8, highByte: UInt8) {
        self = (UInt16(highByte) << 8) | UInt16(lowByte)
    }

    var lowByte: UInt8 {
        get {
            UInt8(self & 0x00FF)
        }
        set {
            self = (self & 0xFF00) | UInt16(newValue)
        }
    }
    var highByte: UInt8 {
        get {
            UInt8(self >> 8)
        }
        set {
            self = (self & 0x00FF) | (UInt16(newValue) << 8)
        }
    }
}
