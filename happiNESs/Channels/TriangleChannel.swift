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

    public var lengthCounter: LengthCounter = LengthCounter()
    public var linearCounter: LinearCounter = LinearCounter()
    private var timer: Timer = Timer()
    public var dutyIndex: Int = 0

    mutating public func reset() {
        self.lengthCounter.reset()
        self.linearCounter.reset()
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
        self.linearCounter.enabled = byte[.triangleControlFlag] == 1
        self.linearCounter.period = byte[.triangleLinearCounterPeriod]
    }

    mutating public func writeTimerLow(byte: UInt8) {
        self.timer.setValueLow(value: byte)
    }

    mutating public func writeLengthCounterAndTimerHigh(byte: UInt8) {
        self.lengthCounter.setValue(index: byte[.triangleLengthCounter])
        self.timer.setValueHigh(value: byte[.triangleTimerHigh])
        self.linearCounter.reload = true
    }

    mutating public func stepTimer() {
        if self.timer.step() {
            if self.lengthCounter.value > 0 && self.linearCounter.value > 0 {
                self.dutyIndex = (self.dutyIndex + 1) % Self.sampleValues.count
            }
        }
    }

    mutating public func stepLinearCounter() {
        self.linearCounter.step()
    }

    mutating public func stepLengthCounter() {
        self.lengthCounter.step()
    }

    public func getSample() -> UInt8 {
        if self.lengthCounter.value == 0 {
            return 0
        }

        if self.linearCounter.value == 0 {
            return 0
        }

        if self.timer.period < 2 {
            return 7
        } else {
            return Self.sampleValues[self.dutyIndex]
        }
    }
}
