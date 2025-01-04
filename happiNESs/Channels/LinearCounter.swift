//
//  LinearCounter.swift
//  happiNESs
//
//  Created by Danielle Kefford on 1/3/25.
//

public struct LinearCounter {
    public var enabled: Bool = false
    public var reload: Bool = false
    public var period: UInt8 = 0x00
    public var value: UInt8 = 0x00

    mutating public func reset() {
        self.enabled = false
        self.reload = false
        self.period = 0x00
        self.value = 0x00
    }
}

extension LinearCounter {
    mutating public func step() {
        if self.reload {
            self.value = self.period
        } else if self.value > 0 {
            self.value -= 1
        }

        if !self.enabled {
            self.reload = false
        }
    }
}
