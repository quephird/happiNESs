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

public struct PulseChannel {
    // NOTA BENE: Table below is a modified version of the one from
    // the Sequencer Behavior section in the following page:
    //
    //     https://www.nesdev.org/wiki/APU_Pulse
    static let dutyTable: [[Bool]] = [
        [false, false, false, false, false, false, false, true],
        [false, false, false, false, false, false, true, true],
        [false, false, false, false, true, true, true, true],
        [true, true, true, true, true, true, false, false],
    ]

    public var channelNumber: ChannelNumber

    private var dutyMode: Int = 0
    private var dutyIndex: Int = 0

    private var sweepEnabled: Bool = false
    private var sweepNegated: Bool = false
    private var sweepShift: UInt8 = 0x00
    private var sweepReloaded: Bool = false
    private var sweepTimer: Timer = Timer()

    public var lengthCounter: LengthCounter = LengthCounter()
    private var timer: Timer = Timer()
    private var targetPeriod: UInt16 = 0x0000
    private var envelope: Envelope = Envelope()

    public init(channelNumber: ChannelNumber) {
        self.channelNumber = channelNumber
    }

    mutating public func reset() {
        self.dutyMode = 0
        self.dutyIndex = 0

        self.sweepEnabled = false
        self.sweepNegated = false
        self.sweepShift = 0x00
        self.sweepReloaded = false
        self.sweepTimer.reset()

        self.lengthCounter.reset()
        self.timer.reset()
        self.targetPeriod = 0x0000
        self.envelope.reset()
    }
}

extension PulseChannel {
    mutating public func setEnabled(enabled: Bool) {
        self.lengthCounter.setEnabled(enabled: enabled)
    }

    mutating public func writeController(byte: UInt8) {
        self.dutyMode = Int(byte[.pulseDutyMode])
        self.envelope.loopEnabled = byte[.pulseControlFlag] == 1
        self.lengthCounter.halted = byte[.pulseControlFlag] == 1
        self.envelope.constantVolume = byte[.pulseConstantVolumeFlag] == 1
        self.envelope.timer.period = UInt16(byte[.pulseVolume])
    }

    mutating public func writeSweep(byte: UInt8) {
        self.sweepEnabled = byte[.pulseSweepEnabled] == 1
        self.sweepTimer.period = UInt16(byte[.pulseSweepPeriod])
        self.sweepNegated = byte[.pulseSweepNegated] == 1
        self.sweepShift = byte[.pulseSweepShift]
        self.sweepReloaded = true
        self.updateTargetPeriod()
    }

    mutating public func writeTimerLow(byte: UInt8) {
        self.timer.setValueLow(value: byte)
        self.updateTargetPeriod()
    }

    mutating public func writeLengthAndTimerHigh(byte: UInt8) {
        self.lengthCounter.setValue(index: byte[.pulseLengthCounter])
        self.timer.setValueHigh(value: byte)
        self.updateTargetPeriod()
        self.envelope.started = true
        self.dutyIndex = 0
    }

    private mutating func updateTargetPeriod() {
        let delta = self.timer.period >> self.sweepShift

        if self.sweepNegated {
            if self.timer.period <= delta {
                self.targetPeriod = 0
            } else {
                self.targetPeriod = self.timer.period - delta

                if self.channelNumber == .one {
                    self.targetPeriod -= 1
                }
            }
        } else {
            self.targetPeriod = self.timer.period + delta
        }
    }

    mutating public func stepTimer() {
        if self.timer.step() {
            self.dutyIndex = (self.dutyIndex - 1) & 0b111
        }
    }

    mutating public func stepEnvelope() {
        self.envelope.step()
    }

    mutating public func stepSweep() {
        let sweepTimerReset = self.sweepTimer.step()

        if sweepTimerReset && self.sweepEnabled && self.sweepShift > 0 && !(self.timer.period < 8 || self.targetPeriod > 0x7FF) {
            self.updateTargetPeriod()
            self.timer.period = self.targetPeriod
        }

        if sweepTimerReset || self.sweepReloaded {
            self.sweepReloaded = false
            self.sweepTimer.reload()
        }
    }

    mutating public func stepLength() {
        self.lengthCounter.step()
    }

    public func getSample() -> UInt8 {
        if self.lengthCounter.value == 0 {
            return 0
        }

        if !Self.dutyTable[self.dutyMode][self.dutyIndex] {
            return 0
        }

        if self.timer.period < 8 || self.targetPeriod > 0x7FF {
            return 0
        }

        return self.envelope.getSample()
    }
}
