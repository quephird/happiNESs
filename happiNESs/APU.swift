//
//  APU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/15/24.
//

enum FramePeriod {
    case four
    case five
}

public struct APU {
    static let frameCounterRate = CPU.frequency / 240.0

    static let lengthTable: [UInt8] = [
        10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14,
        12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30,
    ]

    public var cycles: Int = 0
    private var framePeriod: FramePeriod = .four
    private var frameCounter: Int = 0
    private var frameIrqInhibited: Bool = false
    public var sampleRate: Double

    // TODO: Add the other channels
    public var triangle: TriangleChannel = TriangleChannel()
    public var status: Register = 0x00
    public var buffer = AudioRingBuffer()

    public init(sampleRate: Double) {
        self.sampleRate = sampleRate
    }
}

extension APU {
    public func readByte(address: UInt16) -> UInt8 {
        switch address {
        case 0x4015:
            self.status[.apuStatus]
        default:
            0x00
        }
    }

    mutating public func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case 0x4008:
            self.triangle.updateRegister1(byte: byte)
        case 0x4009:
            // Unused register
            break
        case 0x400A:
            self.triangle.updateRegister3(byte: byte)
        case 0x400B:
            self.triangle.updateRegister4(byte: byte)
        case 0x4015:
            self.updateStatus(byte: byte)
        case 0x4017:
            self.updateFrameCounter(byte: byte)
        default:
            // For now, this is a no-op for any other addresses
            break
        }
    }

    mutating public func updateStatus(byte: UInt8) {
        self.status = byte

        // TODO: Handle the other channels when they are implemented
        self.triangle.enabled = self.status[.triangleEnabled]

        if !self.triangle.enabled {
            self.triangle.lengthCounterValue = 0x00
        }
    }

    mutating public func updateFrameCounter(byte: UInt8) {
        self.framePeriod = byte[.frameSequencerMode] ? .five : .four
        self.frameIrqInhibited = byte[.frameIrqInhibited]

        if self.framePeriod == .five {
            // TODO: Implement other steppers
            self.stepEnvelope()
            self.stepLength()
        }
    }
}

extension APU {
    mutating public func tick(cpuCycles: Int) {
        for _ in 0 ..< cpuCycles {
            let cycleOld = self.cycles
            self.cycles += 1
            let cycleNew = self.cycles

            self.stepTimer()

            let frameOld = Int(Double(cycleOld) / Self.frameCounterRate)
            let frameNew = Int(Double(cycleNew) / Self.frameCounterRate)
            if frameOld != frameNew {
                self.stepFrameCounter()
            }

            let sampleOld = Int(Double(cycleOld) / self.sampleRate)
            let sampleNew = Int(Double(cycleNew) / self.sampleRate)
            if sampleOld != sampleNew {
                self.sendSample()
            }
        }
    }

    mutating private func stepTimer() {
        // TODO: call the methods on the other channels once they're implemented
        self.triangle.stepTimer()
    }

    mutating private func stepFrameCounter() {
        switch self.framePeriod {
        case .four:
            self.frameCounter = (self.frameCounter + 1) % 4

            switch self.frameCounter {
            case 0, 2:
                self.stepEnvelope()
            case 1:
                self.stepEnvelope()
                self.stepSweep()
                self.stepLength()
            case 3:
                self.stepEnvelope()
                self.stepSweep()
                self.stepLength()
                self.generateIRQ()
            default:
                fatalError("Encountered frame counter value of \(self.frameCounter) with frame period \(self.framePeriod)")
            }
        case .five:
            self.frameCounter = (self.frameCounter + 1) % 5

            switch self.frameCounter {
            case 0, 2:
                self.stepEnvelope()
            case 1, 3:
                self.stepEnvelope()
                self.stepSweep()
                self.stepLength()
            case 4:
                break
            default:
                fatalError("Encountered frame counter value of \(self.frameCounter) with frame period \(self.framePeriod)")
            }
        }

    }

    mutating private func stepEnvelope() {
        // TODO: call the methods on the other channels once they're implemented
        self.triangle.stepCounter()
    }

    mutating private func stepSweep() {
        // TODO: call the methods on the other channels once they're implemented
    }

    mutating private func stepLength() {
        // TODO: call the methods on the other channels once they're implemented
        self.triangle.stepLength()
    }

    mutating private func sendSample() {
        // TODO: call the methods on the other channels once they're implemented
        let triangleSample = self.triangle.getSample()
        let signal = mix(pulse1: 0, pulse2: 0, triangle: triangleSample, noise: 0, dmc: 0)
        self.buffer.append(value: signal)
    }

    private func mixPulses(pulse1: UInt8, pulse2: UInt8) -> Float {
        let denominator = (8128.0 / (Float(pulse1) + Float(pulse2))) + 100.0
        return 95.88 /  denominator
    }

    private func mixTnd(triangle: UInt8, noise: UInt8, dmc: UInt8) -> Float {
        let denominator = (Float(triangle) / 8227.0) + (Float(noise) / 12241.0) + (Float(dmc) / 22638.0)
        return 159.79 / ((1 / denominator) + 100.0)
    }

    private func mix(pulse1: UInt8, pulse2: UInt8, triangle: UInt8, noise: UInt8, dmc: UInt8) -> Float {
        let pulses = mixPulses(pulse1: pulse1, pulse2: pulse2)
        let tnd = mixTnd(triangle: triangle, noise: noise, dmc: dmc)
        return pulses + tnd
    }

    mutating private func generateIRQ() {
        // TODO!!!
    }
}
