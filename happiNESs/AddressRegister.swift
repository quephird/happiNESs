//
//  AddressRegister.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/6/24.
//

public struct AddressRegister {
    private var address: UInt16
    public var highPointer: Bool
}

extension AddressRegister {
    public init() {
        self.address = 0x0000
        self.highPointer = true
    }

    mutating public func reset() {
        self.address = 0x0000
        self.highPointer = true
    }

    mutating public func setAddress(address: UInt16) {
        self.address = address
    }

    mutating public func incrementAddress(value: UInt8) {
        self.address = self.address &+ UInt16(value)

        if self.getAddress() > 0x3FFF {
            // Mirror down addresses above 0x3FFF
            self.setAddress(address: self.getAddress() & 0b0011_1111_1111_1111)
        }
    }

    mutating public func updateAddress(byte: UInt8) {
        if highPointer {
            self.address.highByte = byte
        } else {
            self.address.lowByte = byte
        }

        if self.getAddress() > 0x3FFF {
            // Mirror down addresses above 0x3FFF
            self.setAddress(address: self.getAddress() & 0b0011_1111_1111_1111)
        }

        self.highPointer = !self.highPointer
    }

    public func getAddress() -> UInt16 {
        return self.address
    }

    mutating public func resetLatch() {
        self.highPointer = true
    }
}
