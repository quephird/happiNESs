//
//  DMCChannel.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/25/24.
//

public struct DMCChannel {
    static let periodTable: [UInt8] = [
        214, 190, 170, 160, 143, 127, 113, 107, 95, 80, 71, 64, 53, 42, 36, 27,
    ]

    public var bus: Bus? = nil
    public var enabled: Bool = false

    public var irqEnabled: Bool = false
    public var irqTriggered: Bool = false
    private var loopEnabled: Bool = false
    private var loopPeriod: UInt8 = 0x00
    private var loopValue: UInt8 = 0x00

    private var loadCounter: UInt8 = 0x00
    private var sampleAddress: UInt16 = 0x0000
    private var currentAddress: UInt16 = 0x0000
    private var sampleLength: UInt16 = 0x0000
    public var currentLength: UInt16 = 0x0000

    private var shiftRegister: UInt8 = 0x00
    private var bitCount: Int = 0
    private var sampleValue: UInt8 = 0x00

    mutating public func reset() {
        self.enabled = false

        self.irqEnabled = false
        self.irqTriggered = false
        self.loopEnabled = false
        self.loopPeriod = 0x00
        self.loopValue = 0x00

        self.loadCounter = 0x00
        self.sampleAddress = 0x0000
        self.currentAddress = 0x0000
        self.sampleLength = 0x0000
        self.currentLength = 0x0000

        self.shiftRegister = 0x00
        self.bitCount = 0
        self.sampleValue = 0x00
    }
}

extension DMCChannel {
    mutating public func setEnabled(enabled: Bool) {
        self.enabled = enabled
        self.irqTriggered = false

        if !self.enabled {
            self.currentLength = 0
        } else {
            if self.currentLength == 0 {
                self.restart()
            }
        }
    }

    mutating public func writeController(byte: UInt8) {
        self.irqEnabled = byte[.dmcIrqEnabled] == 1
        if !self.irqEnabled {
            self.irqTriggered = false
        }
        self.loopEnabled = byte[.dmcLoopEnabled] == 1
        self.loopPeriod = Self.periodTable[Int(byte[.dmcPeriod])] - 1
    }

    mutating public func writeLoadCounter(byte: UInt8) {
        self.loadCounter = byte[.dmcLoadCounter]
    }

    mutating public func writeSampleAddress(byte: UInt8) {
        self.sampleAddress = 0xC000 | (UInt16(byte) << 6)
    }

    mutating public func writeSampleLength(byte: UInt8) {
        self.sampleLength = (UInt16(byte) << 4) | 0x0001
    }
}

extension DMCChannel {
    mutating public func stepTimer() {
        if !self.enabled {
            return
        }

        self.stepReader()

        if self.loopValue == 0 {
            self.loopValue = self.loopPeriod
            self.stepShifter()
        } else {
            self.loopValue -= 1
        }
    }

    mutating public func restart() {
        self.currentAddress = self.sampleAddress
        self.currentLength = self.sampleLength
    }

    mutating private func stepReader() {
        if self.currentLength > 0 && self.bitCount == 0 {
            self.bus!.cpu!.stall += 4

            self.shiftRegister = self.bus!.readByte(address: self.currentAddress)
            self.bitCount = 8
            self.currentAddress += 1
            if self.currentAddress == 0 {
                self.currentAddress = 0x8000
            }

            self.currentLength -= 1
            if self.currentLength == 0 {
                if self.loopEnabled {
                    self.restart()
                } else if self.irqEnabled {
                    self.irqTriggered = true
                    self.bus!.triggerIrq()
                }
            }
        }
    }

    mutating private func stepShifter() {
        if self.bitCount == 0 {
            return
        }

        if (self.shiftRegister & 1) == 1 {
            if self.sampleValue <= 125 {
                self.sampleValue += 2
            }
        } else {
            if self.sampleValue >= 2 {
                self.sampleValue -= 2
            }
        }

        self.shiftRegister >>= 1
        self.bitCount -= 1
    }

    public func getSample() -> UInt8 {
        return self.sampleValue
    }
}
