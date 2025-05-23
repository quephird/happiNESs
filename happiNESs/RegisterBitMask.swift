//
//  RegisterBitMask.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/16/24.
//

enum RegisterBitMask: Register {
    case apuStatus

    case triangleControlFlag
    case triangleLinearCounterPeriod

    case triangleLengthCounter
    case triangleTimerHigh

    case noiseControlFlag
    case noiseConstantVolumeFlag
    case noiseVolume

    case noiseMode
    case noisePeriod

    case noiseLengthCounter

    case pulseDutyMode
    case pulseControlFlag
    case pulseConstantVolumeFlag
    case pulseVolume

    case pulseSweepEnabled
    case pulseSweepPeriod
    case pulseSweepNegated
    case pulseSweepShift

    case pulseLengthCounter
    case pulseTimerHigh

    case dmcIrqEnabled
    case dmcLoopEnabled
    case dmcPeriod

    case dmcLoadCounter

    var maskValue: UInt8 {
        switch self {
        case .apuStatus:                   0b0001_1111

        case .triangleControlFlag:         0b1000_0000
        case .triangleLinearCounterPeriod: 0b0111_1111

        case .triangleLengthCounter:       0b1111_1000
        case .triangleTimerHigh:           0b0000_0111

        case .noiseControlFlag:            0b0010_0000
        case .noiseConstantVolumeFlag:     0b0001_0000
        case .noiseVolume:                 0b0000_1111

        case .noiseMode:                   0b1000_0000
        case .noisePeriod:                 0b0000_1111

        case .noiseLengthCounter:          0b1111_1000

        case .pulseDutyMode:               0b1100_0000
        case .pulseControlFlag:            0b0010_0000
        case .pulseConstantVolumeFlag:     0b0001_0000
        case .pulseVolume:                 0b0000_1111

        case .pulseSweepEnabled:           0b1000_0000
        case .pulseSweepPeriod:            0b0111_0000
        case .pulseSweepNegated:           0b0000_1000
        case .pulseSweepShift:             0b0000_0111

        case .pulseLengthCounter:          0b1111_1000
        case .pulseTimerHigh:              0b0000_0111

        case .dmcIrqEnabled:               0b1000_0000
        case .dmcLoopEnabled:              0b0100_0000
        case .dmcPeriod:                   0b0000_1111

        case .dmcLoadCounter:              0b0111_1111
        }
    }
}

extension Register {
    private func getBits(using bitMask: RegisterBitMask) -> UInt8 {
        UInt8((self & bitMask.maskValue) >> bitMask.maskValue.trailingZeroBitCount)
    }

    mutating private func setBits(using bitMask: RegisterBitMask, bits: UInt8) {
        let shiftAmount = bitMask.maskValue.trailingZeroBitCount
        let maskedBits = (Self(bits) << shiftAmount) & bitMask.maskValue
        self = (self & ~(bitMask.maskValue)) | maskedBits
    }

    subscript(_ index: RegisterBitMask) -> UInt8 {
        get {
            self.getBits(using: index)
        }
        set {
            self.setBits(using: index, bits: newValue)
        }
    }
}
