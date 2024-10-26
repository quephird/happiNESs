//
//  PulseChannel.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/17/24.
//

public enum ChannelNumber {
    case one
    case two
}

enum PulseControlFlag {
    case lengthCounterEnabled
    case envelopeLoop
}

public struct PulseChannel {
    // NOTA BENE: Table below is a modified version of the one from
    // the Sequencer Behavior section in the following page:
    //
    //     https://www.nesdev.org/wiki/APU_Pulse
    static let dutyTable: [[Bool]] = [
        [false, true, false, false, false, false, false, false],
        [false, true, true, false, false, false, false, false],
        [false, true, true, true, true, false, false, false],
        [true, false, false, true, true, true, true, true],
    ]

    public var enabled: Bool = false
    public var channelNumber: ChannelNumber

    private var dutyMode: Int = 0
    private var dutyIndex: Int = 0
    private var controlFlag: PulseControlFlag = .lengthCounterEnabled
    private var constantVolumeFlag: Bool = false
    private var envelopeStart: Bool = false
    private var envelopePeriod: UInt8 = 0x00
    private var envelopeValue: UInt8 = 0x00
    private var envelopeVolume: UInt8 = 0x00
    private var constantVolume: UInt8 = 0x00

    private var sweepReloaded: Bool = false
    private var sweepEnabled: Bool = false
    private var sweepPeriod: UInt8 = 0x00
    private var sweepValue: UInt8 = 0x00
    private var sweepNegated: Bool = false
    private var sweepShift: UInt8 = 0x00

    public var lengthCounterValue: UInt8 = 0x00
    private var timerPeriod: UInt16 = 0x0000
    private var timerValue: UInt16 = 0x0000
    private var counterReload: UInt8 = 0x00

    public init(channelNumber: ChannelNumber) {
        self.channelNumber = channelNumber
    }
}

extension PulseChannel {
    mutating public func updateRegister1(byte: UInt8) {
        self.dutyMode = Int(byte[.pulseDutyMode])
        self.controlFlag = byte[.pulseControlFlag] == 1 ? .envelopeLoop : .lengthCounterEnabled
        self.constantVolumeFlag = byte[.pulseConstantVolumeFlag] == 1
        self.envelopePeriod = byte[.pulseVolume]
        self.constantVolume = byte[.pulseVolume]
        self.envelopeStart = true
    }

    mutating public func updateRegister2(byte: UInt8) {
        self.sweepEnabled = byte[.pulseSweepEnabled] == 1
        self.sweepPeriod = byte[.pulseSweepPeriod] + 1
        self.sweepNegated = byte[.pulseSweepNegated] == 1
        self.sweepShift = byte[.pulseSweepShift]
        self.sweepReloaded = true
    }

    mutating public func updateRegister3(byte: UInt8) {
        self.timerPeriod = (self.timerPeriod & 0b0000_0111_0000_0000) | UInt16(byte)
    }

    mutating public func updateRegister4(byte: UInt8) {
        self.lengthCounterValue = APU.lengthTable[Int(byte[.triangleLengthCounter])]
        self.timerPeriod = (self.timerPeriod & 0b0000_0000_1111_1111) | UInt16(byte[.triangleTimerHigh]) << 8
        self.envelopeStart = true
        self.dutyIndex = 0
    }

    mutating public func stepTimer() {
        if self.timerValue == 0 {
            self.timerValue = self.timerPeriod
            self.dutyIndex = (self.dutyIndex + 1) % 8
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

    mutating public func stepSweep() {
        if self.sweepReloaded {
            if self.sweepEnabled && self.sweepValue == 0 {
                self.updateTimerPeriod()
            }

            self.sweepValue = self.sweepPeriod
            self.sweepReloaded = false
        } else if self.sweepValue > 0 {
            self.sweepValue -= 1
        } else {
            if self.sweepEnabled {
                self.updateTimerPeriod()
            }

            self.sweepValue = self.sweepPeriod
        }
    }

    private mutating func updateTimerPeriod() {
        let delta = self.timerPeriod >> self.sweepShift
        if self.sweepNegated {
            self.timerPeriod &-= delta

            if self.channelNumber == .one {
                self.timerPeriod &-= 1
            }
        } else {
            self.timerPeriod &+= delta
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

        if Self.dutyTable[self.dutyMode][self.dutyIndex] {
            return 0
        }

        if self.timerPeriod < 8 || self.timerPeriod > 0x7FF {
            return 0
        }

        if self.constantVolumeFlag {
            return self.constantVolume
        } else {
            return self.envelopeVolume
        }
    }
}
