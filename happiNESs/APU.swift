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
    public static let audioSampleRate: Float = 44100.0
    static let frameCounterRate = CPU.frequency / 240.0

    // Values for this table taken from:
    //
    //     https://www.nesdev.org/wiki/APU_Length_Counter
    static let lengthTable: [UInt8] = [
        10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14,
        12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30,
    ]

    public var bus: Bus? = nil
    public var cycles: Int = 0
    private var sequencerMode: SequencerMode = .four
    private var sequencerCount: Int = 0
    private var frameIrqInhibited: Bool = false
    private var frameIrqEnabled: Bool = false
    public var sampleRate: Float

    public var pulse1: PulseChannel = PulseChannel(channelNumber: .one)
    public var pulse2: PulseChannel = PulseChannel(channelNumber: .two)
    public var triangle: TriangleChannel = TriangleChannel()
    public var noise: NoiseChannel = NoiseChannel()
    public var dmc: DMCChannel = DMCChannel()
    private var filterChain: FilterChain

    public var status: Register = 0x00
    public var buffer = AudioRingBuffer()
    private var newSequencerValue: UInt8?
    private var newSequencerValueDelay: Int = 0

    public init(sampleRate: Float) {
        self.sampleRate = sampleRate
        // NOTA BENE: Even though according to the following section in the NESDev
        // wiki that there ought to be two high pass filters, I found that adding
        // the one for 400 Hz made the resultant audio sound way too tinny, and so
        // only one high pass and one low pass have been left in.
        //
        //     https://www.nesdev.org/wiki/APU_Mixer
        self.filterChain = FilterChain(filters: [
            HighPassFilter(sampleRate: Self.audioSampleRate, cutoffFrequency: 90),
            LowPassFilter(sampleRate: Self.audioSampleRate, cutoffFrequency: 14000),
        ])
    }

    mutating public func reset() {
        self.frameIrqInhibited = false
        self.frameIrqEnabled = false

        self.pulse1.reset()
        self.pulse2.reset()
        self.triangle.reset()
        self.noise.reset()
        self.dmc.reset()
        self.buffer.reset()

        self.newSequencerValue = nil
        self.newSequencerValueDelay = 0

        self.sequencerCount = 0
    }
}

extension APU {
    private func readStatus() -> UInt8 {
        var value: UInt8 = 0x00
        value[.pulse1Enabled] = self.pulse1.lengthCounter.value > 0
        value[.pulse2Enabled] = self.pulse2.lengthCounter.value > 0
        value[.triangleEnabled] = self.triangle.lengthCounter.value > 0
        value[.noiseEnabled] = self.noise.lengthCounter.value > 0
        value[.dmcEnabled] = self.dmc.currentLength > 0
        value[.frameIrqEnabled] = self.frameIrqEnabled
        value[.apuStatusUnused3] = self.dmc.irqEnabled

        return value
    }

    mutating public func readByte(address: UInt16) -> UInt8 {
        let value = switch address {
        case 0x4015:
            self.readStatus()
        default:
            UInt8(0x00)
        }

        self.frameIrqEnabled = false
        return value
    }

    mutating public func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case 0x4000:
            self.pulse1.writeController(byte: byte)
        case 0x4001:
            self.pulse1.writeSweep(byte: byte)
        case 0x4002:
            self.pulse1.writeTimerLow(byte: byte)
        case 0x4003:
            self.pulse1.writeLengthCounterAndTimerHigh(byte: byte)
        case 0x4004:
            self.pulse2.writeController(byte: byte)
        case 0x4005:
            self.pulse2.writeSweep(byte: byte)
        case 0x4006:
            self.pulse2.writeTimerLow(byte: byte)
        case 0x4007:
            self.pulse2.writeLengthCounterAndTimerHigh(byte: byte)
        case 0x4008:
            self.triangle.writeController(byte: byte)
        case 0x4009:
            // Unused register
            break
        case 0x400A:
            self.triangle.writeTimerLow(byte: byte)
        case 0x400B:
            self.triangle.writeLengthCounterAndTimerHigh(byte: byte)
        case 0x400C:
            self.noise.writeController(byte: byte)
        case 0x400D:
            // Unused register
            break
        case 0x400E:
            self.noise.writeLoopAndPeriod(byte: byte)
        case 0x400F:
            self.noise.writeLengthCounter(byte: byte)
        case 0x4010:
            self.dmc.writeController(byte: byte)
        case 0x4011:
            self.dmc.writeLoadCounter(byte: byte)
        case 0x4012:
            self.dmc.writeSampleAddress(byte: byte)
        case 0x4013:
            self.dmc.writeSampleLength(byte: byte)
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
        self.pulse1.setEnabled(enabled: byte[.pulse1Enabled])
        self.pulse2.setEnabled(enabled: byte[.pulse2Enabled])
        self.triangle.setEnabled(enabled: byte[.triangleEnabled])
        self.noise.setEnabled(enabled: byte[.noiseEnabled])
        self.dmc.enabled = byte[.dmcEnabled]
        self.dmc.irqEnabled = false

        if !self.dmc.enabled {
            self.dmc.currentLength = 0
        } else {
            if self.dmc.currentLength == 0 {
                self.dmc.restart()
            }
        }
    }

    mutating public func updateSequencer(byte: UInt8) {
        // NOTA BENE: The setting of the sequencer mode is _not_ immediate
        // and instead is delayed by 3 or 4 APU cycles, depending on whether
        // the write to 0x4017 took place _during_ an APU cycle or between them,
        // which we approximate below by checking the parity of the current value
        // of cycles. See this wiki article for more details:
        //
        //     https://www.nesdev.org/wiki/APU_Frame_Counter
        self.newSequencerValue = byte
        if self.cycles % 2 == 0 {
            self.newSequencerValueDelay = 3
        } else {
            self.newSequencerValueDelay = 4
        }

        if (byte & 0b0100_0000) > 0 {
            self.frameIrqInhibited = true
            self.frameIrqEnabled = false
        } else {
            self.frameIrqInhibited = false
        }
    }
}

extension APU {
    var shouldSendSample: Bool {
        // NOTA BENE: We can't just use simple modulo arithmetic here
        // because we're dealing with Floats and Doubles and need to avoid
        // truncation errors. For the time being, this is the most
        // reliable way to detect if and when to send a sample.
        let oldSampleNumber = Int(Float(self.cycles - 1) / self.sampleRate)
        let newSampleNumber = Int(Float(self.cycles) / self.sampleRate)
        return newSampleNumber != oldSampleNumber
    }

    // This function needs executes its body of instructions once for every tick
    // of the CPU, unlike for the PPU and mapper tick() functions.
    mutating public func tick() {
        self.maybeUpdateSequencerMode()
        self.cycles += 1

        self.stepSequencer()
        self.stepTimer()

        if self.shouldSendSample {
            self.sendSample()
        }
    }

    mutating private func maybeUpdateSequencerMode() {
        if let frameCountValue = self.newSequencerValue {
            if self.newSequencerValueDelay > 0 {
                self.newSequencerValueDelay -= 1
            } else {
                // If the delay count is zero, then finally
                // update the sequencer mode accordingly.
                self.sequencerCount = 0

                if frameCountValue[.sequencerMode] {
                    self.sequencerMode = .five
                    self.stepEnvelope()
                    self.stepLength()
                    self.stepSweep()
                } else {
                    self.sequencerMode = .four
                }

                self.newSequencerValueDelay = 0
                self.newSequencerValue = nil
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
            self.pulse1.stepTimer()
            self.pulse2.stepTimer()
            self.noise.stepTimer()
            self.dmc.stepTimer()
        }

        self.triangle.stepTimer()
    }

    mutating private func stepSequencer() {
        self.sequencerCount += 1

        // NOTA BENE: Constants used below taken from:
        //
        //     https://github.com/ichirin2501/rgnes/blob/master/nes/apu.go#L16-L19
        //
        // Note that the figures are doubled here because the sequencer clocks
        // at _half_ the rate of the CPU. Also, this is hardcoded to work with
        // NTSC timings.
        switch self.sequencerMode {
        case .four:
            switch self.sequencerCount {
            case 7457: // Step 1
                self.stepEnvelope()
            case 14913: // Step 2
                self.stepEnvelope()
                self.stepLength()
                self.stepSweep()
            case 22371: // Step 3
                self.stepEnvelope()
            case 29828:
                if !self.frameIrqInhibited {
                    self.frameIrqEnabled = true
                    self.generateIRQ()
                }
            case 29829: // Step 4
                self.stepEnvelope()
                self.stepLength()
                self.stepSweep()
                if !self.frameIrqInhibited {
                    self.frameIrqEnabled = true
                    self.generateIRQ()
                }
            case 29830:
                if !self.frameIrqInhibited {
                    self.frameIrqEnabled = true
                    self.generateIRQ()
                }
                self.sequencerCount = 0
            default:
                break
            }
        case .five:
            switch self.sequencerCount {
            case 7457: // Step 1
                self.stepEnvelope()
            case 14913: // Step 2
                self.stepEnvelope()
                self.stepLength()
                self.stepSweep()
            case 22371: // Step 3
                self.stepEnvelope()
            case 29829: // Step 4
                break
            case 37281: // Step 5
                self.stepEnvelope()
                self.stepLength()
                self.stepSweep()
            case 37282:
                self.sequencerCount = 0
            default:
                break
            }
        }
    }

    mutating private func stepEnvelope() {
        self.pulse1.stepEnvelope()
        self.pulse2.stepEnvelope()
        self.triangle.stepLinearCounter()
        self.noise.stepEnvelope()
    }

    mutating private func stepSweep() {
        self.pulse1.stepSweep()
        self.pulse2.stepSweep()
    }

    mutating private func stepLength() {
        self.pulse1.stepLengthCounter()
        self.pulse2.stepLengthCounter()
        self.triangle.stepLengthCounter()
        self.noise.stepLengthCounter()
    }

    mutating private func sendSample() {
        let pulse1Sample = self.pulse1.getSample()
        let pulse2Sample = self.pulse2.getSample()
        let triangleSample = self.triangle.getSample()
        let noiseSample = self.noise.getSample()
        let dmcSample = self.dmc.getSample()

        let signalValue = mix(pulse1: pulse1Sample,
                              pulse2: pulse2Sample,
                              triangle: triangleSample,
                              noise: noiseSample,
                              dmc: dmcSample)

        let filteredSignalValue = self.filterChain.filter(inputValue: signalValue)
        self.buffer.append(value: filteredSignalValue)
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
        if self.status[.frameIrqEnabled] {
            self.bus!.triggerIrq()
        }
    }
}
