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
    public var enabled: Bool = false
    private var controlFlag: NoiseControlFlag = .lengthCounterEnabled
    private var constantVolumeFlag: Bool = false
    private var constantVolume: UInt8 = 0x00
    private var envelopeStart: Bool = false
    private var envelopePeriod: UInt8 = 0x00
    private var envelopeValue: UInt8 = 0x00
    private var envelopeVolume: UInt8 = 0x00
    private var mode: Int = 1
    private var shiftRegister: UInt16 = 0x0001
    private var timerPeriod: UInt16 = 0x0000
    private var timerValue: UInt16 = 0x0000
    public var lengthCounterValue: UInt8 = 0x00
    private var dutyIndex: Int = 0
}

extension NoiseChannel {
    mutating public func updateRegister1(byte: UInt8) {
        self.controlFlag = byte[.noiseControlFlag] == 1 ? .envelopeLoop : .lengthCounterEnabled
        self.constantVolumeFlag = byte[.noiseConstantVolumeFlag] == 1
        self.envelopePeriod = byte[.noiseVolume]
        self.constantVolume = byte[.noiseVolume]
        self.envelopeStart = true
    }

    mutating public func updateRegister3(byte: UInt8) {
        self.mode = byte[.noiseMode] == 1 ? 6 : 1
        self.timerPeriod = Self.timerPeriods[Int(byte[.noisePeriod])]
    }

    mutating public func updateRegister4(byte: UInt8) {
        self.lengthCounterValue = APU.lengthTable[Int(byte[.noiseLengthCounter])]
        self.envelopeStart = true
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
        if self.envelopeStart {
            self.envelopeVolume = 15
            self.envelopeValue = self.envelopePeriod
            self.envelopeStart = false
        } else if self.envelopeValue > 0 {
            self.envelopeValue -= 1
        } else {
            if self.envelopeVolume > 0 {
                self.envelopeVolume -= 1
            } else if self.controlFlag == .envelopeLoop {
                self.envelopeVolume = 15
            }

            self.envelopeValue = self.envelopePeriod
        }
    }

    mutating public func stepLength() {
        if self.controlFlag == .lengthCounterEnabled && self.lengthCounterValue > 0 {
            self.lengthCounterValue -= 1
        }
    }

    public func getSample() -> UInt8 {
        if !self.enabled {
            return 0
        }

        if self.lengthCounterValue == 0 {
            return 0
        }

        if self.shiftRegister & 1 == 1 {
            return 0
        }

        if self.constantVolumeFlag {
            return self.constantVolume
        } else {
            return self.envelopeVolume
        }
    }
}
