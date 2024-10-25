//
//  RegisterBitMask.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/16/24.
//

enum RegisterBitMask: Register {
    case apuStatus

    case triangleControlFlag
    case triangleLinearCounterReload

    case triangleLengthCounter
    case triangleTimerHigh

    case noiseControlFlag
    case noiseConstantVolumeFlag
    case noiseVolume

    case noiseMode
    case noisePeriod

    case noiseLengthCounter

    case pulseSweepEnabled
    case pulsePeriod
    case pulseNegate
    case pulseShift

    var maskValue: UInt8 {
        switch self {
        case .apuStatus:                   0b0001_1111

        case .triangleControlFlag:         0b1000_0000
        case .triangleLinearCounterReload: 0b0111_1111

        case .triangleLengthCounter:       0b1111_1000
        case .triangleTimerHigh:           0b0000_0111

        case .noiseControlFlag:            0b0010_0000
        case .noiseConstantVolumeFlag:     0b0001_0000
        case .noiseVolume:                 0b0000_1111

        case .noiseMode:                   0b1000_0000
        case .noisePeriod:                 0b0000_1111

        case .noiseLengthCounter:          0b1111_1000

        case .pulseSweepEnabled:           0b1000_0000
        case .pulsePeriod:                 0b0111_0000
        case .pulseNegate:                 0b0000_1000
        case .pulseShift:                  0b0000_0111
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
