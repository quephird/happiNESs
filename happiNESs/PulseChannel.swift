//
//  PulseChannel.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/17/24.
//

public struct PulseChannel {
    public var enabled: Bool = false
    public var controlFlagEnabled: Bool = false
    public var sweepEnabled: Bool = false
    public var period: UInt8 = 0x00
    public var negate: Bool = false
    public var shift: UInt8 = 0x00
    public var lengthCounter: UInt8 = 0x00
    public var timer: UInt16 = 0x0000
    public var counterReload: UInt8 = 0x00
}

extension PulseChannel {
//    mutating public func updateLengthCounter(byte: UInt8) {
//        self.lengthCounter = byte
//    }
//
//    mutating public func updateTimerLow(byte: UInt8) {
//        self.timer = (self.timer & 0b0000_0111_0000_0000) | UInt16(byte)
//    }
//
//    mutating public func updateTimerHigh(byte: UInt8) {
//        self.timer = (self.timer & 0b0000_0000_1111_1111) | UInt16(byte[.triangleTimerHigh]) << 8
//    }
//
//    mutating public func updateCounterReload(byte: UInt8) {
//        self.counterReload = byte[.triangleCounterReload]
//    }
//
//    mutating public func updateControlFlagEnabled(byte: UInt8) {
//        self.controlFlagEnabled = byte[.triangleControlFlag] == 1
//    }
//
//    mutating public func updateSweepEnabled(byte: UInt8) {
//        self.sweepEnabled = byte[.pulseSweepEnabled] == 1
//    }
//
//    mutating public func updatePeriod(byte: UInt8) {
//        self.period = byte[.pulsePeriod]
//    }
//
//    mutating public func updateNegate(byte: UInt8) {
//        self.negate = byte[.pulseNegate] == 1
//    }
//
//    mutating public func updateShift(byte: UInt8) {
//        self.shift = byte[.pulseShift]
//    }
}
