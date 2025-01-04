//
//  LengthCounter.swift
//  happiNESs
//
//  Created by Danielle Kefford on 12/31/24.
//

public struct LengthCounter {
    private static let table: [UInt8] = [
        10, 254, 20, 2, 40, 4, 80, 6,
        160, 8, 60, 10, 14, 12, 26, 14,
        12, 16, 24, 18, 48, 20, 96, 22,
        192, 24, 72, 26, 16, 28, 32, 30,
    ]

    public var enabled: Bool = false
    public var halted: Bool = false
    public var value: UInt8 = 0

    mutating public func reset() {
        self.enabled = false
        self.halted = false
        self.value = 0
    }
}

extension LengthCounter {
    mutating public func setEnabled(enabled: Bool) {
        if enabled {
            self.enabled = true
        } else {
            self.enabled = false
            self.value = 0
        }
    }

    mutating public func setValue(index: UInt8) {
        if self.enabled {
            self.value = Self.table[Int(index)]
        }
    }

    mutating public func step() {
        if !self.halted && self.value > 0 {
            self.value -= 1
        }
    }
}
