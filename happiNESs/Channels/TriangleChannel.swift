//
//  TriangleChannel.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/15/24.
//

public struct TriangleChannel {
    // NOTA BENE: Figures below taken from:
    //
    //     https://www.nesdev.org/wiki/APU_Triangle
    private static var sampleValues: [UInt8] = [
        15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    ]

    // TODO: Need comments explaining all these fields!!!
    public var linearCounterEnabled: Bool = false
    public var linearCounterReload: Bool = false
    public var linearCounterPeriod: UInt8 = 0x00
    public var linearCounterValue: UInt8 = 0x00

    public var lengthCounter: LengthCounter = LengthCounter()
    private var timer: Timer = Timer()
    public var dutyIndex: Int = 0

    mutating public func reset() {
        self.linearCounterEnabled = false
        self.linearCounterReload = false
        self.linearCounterPeriod = 0x00
        self.linearCounterValue = 0x00

        self.lengthCounter.reset()
        self.timer.reset()
        self.dutyIndex = 0
    }
}

extension TriangleChannel {
    mutating public func setEnabled(enabled: Bool) {
        self.lengthCounter.setEnabled(enabled: enabled)
    }

    mutating public func writeController(byte: UInt8) {
        self.lengthCounter.halted = byte[.triangleControlFlag] == 1
        self.linearCounterEnabled = byte[.triangleControlFlag] == 1
        self.linearCounterPeriod = byte[.triangleLinearCounterReload]
    }

    mutating public func writeTimerLow(byte: UInt8) {
        self.timer.setValueLow(value: byte)
    }

    mutating public func writeLengthAndTimerHigh(byte: UInt8) {
        self.lengthCounter.setValue(index: byte[.triangleLengthCounter])
        self.timer.setValueHigh(value: byte[.triangleTimerHigh])
        self.linearCounterReload = true
    }

    mutating public func stepTimer() {
        if self.timer.step() {
            if self.lengthCounter.value > 0 && self.linearCounterValue > 0 {
                self.dutyIndex = (self.dutyIndex + 1) % Self.sampleValues.count
            }
        }
    }

    mutating public func stepCounter() {
        if self.linearCounterReload {
            self.linearCounterValue = self.linearCounterPeriod
        } else if self.linearCounterValue > 0 {
            self.linearCounterValue -= 1
        }

        if !self.linearCounterEnabled {
            self.linearCounterReload = false
        }
    }

    mutating public func stepLength() {
        self.lengthCounter.step()
    }

    public func getSample() -> UInt8 {
        if self.lengthCounter.value == 0 {
            return 0
        }

        if self.linearCounterValue == 0 {
            return 0
        }

        if self.timer.period < 2 {
            return 7
        } else {
            return Self.sampleValues[self.dutyIndex]
        }
    }
}
