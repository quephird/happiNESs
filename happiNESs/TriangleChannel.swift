//
//  TriangleChannel.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/15/24.
//

public struct TriangleChannel {
    private static var sampleValues: [UInt8] = [
        15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    ]

    // TODO: Need comments explaining all these fields!!!
    public var enabled: Bool = false
    public var controlFlagEnabled: Bool = false
    public var linearCounterReloadFLag: Bool = false
    public var linearCounterReload: UInt8 = 0x00
    public var linearCounterValue: UInt8 = 0x00
    public var lengthCounterValue: UInt8 = 0x00
    public var timerPeriod: UInt16 = 0x0000
    public var timerValue: UInt16 = 0x0000
    public var dutyIndex: Int = 0
}

extension TriangleChannel {
    mutating public func updateRegister1(byte: UInt8) {
        self.controlFlagEnabled = byte[.triangleControlFlag] == 0
        self.linearCounterReload = byte[.triangleLinearCounterReload]
    }

    mutating public func updateRegister3(byte: UInt8) {
        self.timerPeriod = (self.timerPeriod & 0b0000_0111_0000_0000) | UInt16(byte)
    }

    mutating public func updateRegister4(byte: UInt8) {
        self.lengthCounterValue = APU.lengthTable[Int(byte[.triangleLengthCounter])]
        self.timerPeriod = (self.timerPeriod & 0b0000_0000_1111_1111) | UInt16(byte[.triangleTimerHigh]) << 8
        self.timerValue = self.timerPeriod + 1
        self.linearCounterReloadFLag = true
    }

    mutating public func stepTimer() {
        if self.timerValue == 0 {
            self.timerValue = self.timerPeriod + 1

            if self.lengthCounterValue > 0 && self.linearCounterValue > 0 {
                self.dutyIndex = (self.dutyIndex + 1) % Self.sampleValues.count
            }
        } else {
            self.timerValue -= 1
        }
    }

    mutating public func stepCounter() {
        if self.linearCounterReloadFLag {
            self.linearCounterValue = self.linearCounterReload
        } else if self.linearCounterValue > 0 {
            self.linearCounterValue -= 1
        }

        if self.controlFlagEnabled {
            self.linearCounterReloadFLag = false
        }
    }

    mutating public func stepLength() {
        if self.controlFlagEnabled && self.lengthCounterValue > 0 {
            self.lengthCounterValue -= 1
        }
    }

    public func getSample() -> UInt8 {
        if !self.enabled {
            return 0
        }

        if self.timerPeriod < 3 {
            return 0
        }

        if self.lengthCounterValue == 0 {
            return 0
        }

        if self.linearCounterValue == 0 {
            return 0
        }

        return Self.sampleValues[self.dutyIndex]
    }
}
