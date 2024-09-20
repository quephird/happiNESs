//
//  ScrollRegister.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/20/24.
//

public struct ScrollRegister {
    public var scrollX: UInt8
    public var scrollY: UInt8
    public var latch: Bool

    init() {
        self.scrollX = 0
        self.scrollY = 0
        self.latch = false
    }

    mutating public func reset() {
        self.scrollX = 0
        self.scrollY = 0
        self.latch = false
    }
}

extension ScrollRegister {
    mutating public func writeByte(byte: UInt8) {
        if self.latch {
            self.scrollY = byte
        } else {
            self.scrollX = byte
        }

        self.latch = !self.latch
    }

    mutating public func resetLatch() {
        self.latch = false
    }
}
