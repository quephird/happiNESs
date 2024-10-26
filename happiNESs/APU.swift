//
//  APU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/15/24.
//

enum SequencerMode {
    case four
    case five
}

public struct APU {
    static let frameCounterRate = CPU.frequency / 240.0

    // Values for this table taken from:
    //
    //     https://www.nesdev.org/wiki/APU_Length_Counter
    static let lengthTable: [UInt8] = [
        10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14,
        12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30,
    ]

    public var cycles: Int = 0
    private var sequencerMode: SequencerMode = .four
    private var frameIrqInhibited: Bool = false
    public var sampleRate: Double

    // TODO: Add the other channels
    public var pulse1: PulseChannel = PulseChannel(channelNumber: .one)
    public var pulse2: PulseChannel = PulseChannel(channelNumber: .two)
    public var triangle: TriangleChannel = TriangleChannel()
    public var noise: NoiseChannel = NoiseChannel()
    public var dmc: DMCChannel = DMCChannel()
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
        case 0x4000:
            self.pulse1.updateRegister1(byte: byte)
        case 0x4001:
            self.pulse1.updateRegister2(byte: byte)
        case 0x4002:
            self.pulse1.updateRegister3(byte: byte)
        case 0x4003:
            self.pulse1.updateRegister4(byte: byte)
        case 0x4004:
            self.pulse2.updateRegister1(byte: byte)
        case 0x4005:
            self.pulse2.updateRegister2(byte: byte)
        case 0x4006:
            self.pulse2.updateRegister3(byte: byte)
        case 0x4007:
            self.pulse2.updateRegister4(byte: byte)
        case 0x4008:
            self.triangle.updateRegister1(byte: byte)
        case 0x4009:
            // Unused register
            break
        case 0x400A:
            self.triangle.updateRegister3(byte: byte)
        case 0x400B:
            self.triangle.updateRegister4(byte: byte)
        case 0x400C:
            self.noise.updateRegister1(byte: byte)
        case 0x400D:
            // Unused register
            break
        case 0x400E:
            self.noise.updateRegister3(byte: byte)
        case 0x400F:
            self.noise.updateRegister4(byte: byte)
        case 0x4010:
            self.dmc.updateRegister1(byte: byte)
        case 0x4011:
            self.dmc.updateRegister2(byte: byte)
        case 0x4012:
            self.dmc.updateRegister3(byte: byte)
        case 0x4013:
            self.dmc.updateRegister4(byte: byte)
        case 0x4015:
            self.updateStatus(byte: byte)
        case 0x4017:
            self.updateSequencer(byte: byte)
        default:
            // For now, this is a no-op for any other addresses
            break
        }
    }

    mutating public func updateStatus(byte: UInt8) {
        self.status = byte

        // TODO: Handle the other channels when they are implemented
        self.pulse1.enabled = self.status[.pulse1Enabled]
        self.pulse2.enabled = self.status[.pulse2Enabled]
        self.triangle.enabled = self.status[.triangleEnabled]
        self.noise.enabled = self.status[.noiseEnabled]
        self.dmc.enabled = self.status[.dmcEnabled]

        if !self.pulse1.enabled {
            self.pulse1.lengthCounterValue = 0x00
        }
        if !self.pulse2.enabled {
            self.pulse2.lengthCounterValue = 0x00
        }
        if !self.triangle.enabled {
            self.triangle.lengthCounterValue = 0x00
        }
        if !self.noise.enabled {
            self.noise.lengthCounterValue = 0x00
        }
        if !self.dmc.enabled {
            self.dmc.currentLength = 0
        } else {
            if self.dmc.currentLength == 0 {
                self.dmc.restart()
            }
        }
    }

    mutating public func updateSequencer(byte: UInt8) {
        self.sequencerMode = byte[.sequencerMode] ? .five : .four
        self.frameIrqInhibited = byte[.frameIrqInhibited]

        if self.sequencerMode == .five {
            // TODO: Implement other steppers
            self.stepEnvelope()
            self.stepSweep()
            self.stepLength()
        }
    }
}

extension APU {
    var shouldSendSample: Bool {
        let oldSampleNumber = Int(Double(self.cycles - 1) / self.sampleRate)
        let newSampleNumber = Int(Double(self.cycles) / self.sampleRate)
        return newSampleNumber != oldSampleNumber
    }

    mutating public func tick(cpuCycles: Int) {
        for _ in 0 ..< cpuCycles {
            self.cycles += 1

            self.stepTimer()
            self.stepSequencer()

            if self.shouldSendSample {
                self.sendSample()
            }
        }
    }

    mutating private func stepTimer() {
        // NOTA BENE: From the NESDev wiki:
        //
        //     "The triangle channel's timer is clocked on every CPU cycle,
        //     but the pulse, noise, and DMC timers are clocked only on every
        //     second CPU cycle and thus produce only even periods."

        if self.cycles % 2 == 0 {
            // TODO: call the methods on the other channels once they're implemented
            self.pulse1.stepTimer()
            self.pulse2.stepTimer()
            self.noise.stepTimer()
            self.dmc.stepTimer()
        }

        self.triangle.stepTimer()
    }

    mutating private func stepSequencer() {
        // NOTA BENE: Constants used below taken from:
        //
        //     https://www.nesdev.org/wiki/APU_Frame_Counter
        //
        // Note that the figures are doubled here because the sequencer clocks
        // at _half_ the rate of the CPU. Also, this is hardcoded to work with
        // NTSC timings.
        switch self.sequencerMode {
        case .four:
            switch self.cycles % 29830 {
            case 0:
                self.generateIRQ()
            case 7457: // Step 1
                self.stepEnvelope()
            case 14913: // Step 2
                self.stepEnvelope()
                self.stepSweep()
                self.stepLength()
            case 22371: // Step 3
                self.stepEnvelope()
            case 29828:
                self.generateIRQ()
            case 29829: // Step 4
                self.stepEnvelope()
                self.stepSweep()
                self.stepLength()
                self.generateIRQ()
            default:
                break
            }
        case .five:
            switch self.cycles % 37282 {
            case 7457: // Step 1
                self.stepEnvelope()
            case 14913: // Step 2
                self.stepEnvelope()
                self.stepSweep()
                self.stepLength()
            case 22371: // Step 3
                self.stepEnvelope()
            case 29829: // Step 4
                break
            case 37281: // Step 5
                self.stepEnvelope()
                self.stepSweep()
                self.stepLength()
            default:
                break
            }
        }
    }

    mutating private func stepEnvelope() {
        // TODO: call the methods on the other channels once they're implemented
        self.pulse1.stepEnvelope()
        self.pulse2.stepEnvelope()
        self.triangle.stepCounter()
        self.noise.stepEnvelope()
    }

    mutating private func stepSweep() {
        // TODO: call the methods on the other channels once they're implemented
        self.pulse1.stepSweep()
        self.pulse2.stepSweep()
    }

    mutating private func stepLength() {
        // TODO: call the methods on the other channels once they're implemented
        self.pulse1.stepLength()
        self.pulse2.stepLength()
        self.triangle.stepLength()
        self.noise.stepLength()
    }

    mutating private func sendSample() {
        // TODO: call the methods on the other channels once they're implemented
        let pulse1Sample = self.pulse1.getSample()
        let pulse2Sample = self.pulse2.getSample()
        let triangleSample = self.triangle.getSample()
        let noiseSample = self.noise.getSample()
        let dmcSample = self.dmc.getSample()

        let signal = mix(pulse1: pulse1Sample,
                         pulse2: pulse2Sample,
                         triangle: triangleSample,
                         noise: noiseSample,
                         dmc: dmcSample)
        self.buffer.append(value: signal)
    }

    // NOTA BENE: Coefficients for next two functions taken from:
    //
    //     https://www.nesdev.org/wiki/APU_Mixer
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
