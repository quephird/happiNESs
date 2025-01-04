//
//  Timer.swift
//  happiNESs
//
//  Created by Danielle Kefford on 12/31/24.
//

struct Timer {
    public var value: UInt16 = 0
    public var period: UInt16 = 0

    mutating public func reset() {
        self.period = 0
        self.value = 0
    }
}

extension Timer {
    mutating public func setValueLow(value: UInt8) {
        self.period = (self.period & 0b0000_0111_0000_0000) | UInt16(value)
    }

    mutating public func setValueHigh(value: UInt8) {
        self.period = (self.period & 0b0000_0000_1111_1111) | UInt16(value[.pulseTimerHigh]) << 8
    }

    mutating public func step() -> Bool {
        if self.value == 0 {
            self.value = self.period
            return true
        }

        self.value -= 1
        return false
    }

    mutating public func reload() {
        self.value = self.period
    }
}
