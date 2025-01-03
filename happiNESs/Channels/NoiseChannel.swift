//
//  NoiseChannel.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/24/24.
//

enum NoiseControlFlag {
    case lengthCounterEnabled
    case envelopeLoop
}

public struct NoiseChannel {
    static let timerPeriods: [UInt16] = [
        4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068,
    ]

    // TODO: Need comments explaining all these fields!!!
    private var controlFlag: NoiseControlFlag = .lengthCounterEnabled
    private var constantVolumeFlag: Bool = false
    private var constantVolume: UInt8 = 0x00
    private var mode: Int = 1
    private var shiftRegister: UInt16 = 0x0001
    private var timerPeriod: UInt16 = 0x0000
    private var timerValue: UInt16 = 0x0000

    private var dutyIndex: Int = 0
    public var lengthCounter: LengthCounter = LengthCounter()
    private var envelope: Envelope = Envelope()

    mutating public func reset() {
        self.controlFlag = .lengthCounterEnabled
        self.constantVolumeFlag = false
        self.constantVolume = 0x00
        self.mode = 1
        self.shiftRegister = 0x0001
        self.timerPeriod = 0x0000
        self.timerValue = 0x0000
        self.lengthCounter.reset()
        self.envelope.reset()
        self.dutyIndex = 0
    }
}

extension NoiseChannel {
    mutating public func setEnabled(enabled: Bool) {
        self.lengthCounter.setEnabled(enabled: enabled)
    }

    mutating public func writeController(byte: UInt8) {
        self.lengthCounter.halted = byte[.noiseControlFlag] == 1
        self.envelope.loopEnabled = byte[.noiseControlFlag] == 1
        self.envelope.constantVolume = byte[.noiseConstantVolumeFlag] == 1
        self.envelope.timer.period = UInt16(byte[.noiseVolume])
    }

    mutating public func writeLoopAndPeriod(byte: UInt8) {
        self.mode = byte[.noiseMode] == 1 ? 6 : 1
        self.timerPeriod = Self.timerPeriods[Int(byte[.noisePeriod])]
    }

    mutating public func writeLength(byte: UInt8) {
        self.lengthCounter.setValue(index: byte[.noiseLengthCounter])
        self.envelope.started = true
    }

    mutating public func stepTimer() {
        if self.timerValue == 0 {
            self.timerValue = self.timerPeriod

            let bit1 = self.shiftRegister & 1
            let bit2 = (self.shiftRegister >> self.mode) & 1
            self.shiftRegister >>= 1
            self.shiftRegister |= (bit1 ^ bit2) << 14
        } else {
            self.timerValue -= 1
        }
    }

    mutating public func stepEnvelope() {
        self.envelope.step()
    }

    mutating public func stepLength() {
        self.lengthCounter.step()
    }

    public func getSample() -> UInt8 {
        if self.lengthCounter.value == 0 {
            return 0
        }

        if self.shiftRegister & 1 == 1 {
            return 0
        }

        return self.envelope.getSample()
    }
}
