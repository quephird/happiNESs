//
//  OAMRegister.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/20/24.
//

public struct OAMRegister {
    public var address: UInt8
    public var data: [UInt8]

    init() {
        self.address = 0
        self.data = [UInt8](repeating: 0x00, count: 256)
    }
}

extension OAMRegister {
    mutating public func updateAddress(byte: UInt8) {
        self.address = byte
    }

    public func readByte() -> UInt8 {
        self.data[Int(self.address)]
    }

    mutating public func writeByte(byte: UInt8) {
        self.data[Int(self.address)] = byte
        self.address =  self.address &+ 1
    }
}
