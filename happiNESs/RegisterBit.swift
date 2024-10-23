//
//  RegisterBit.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/15/24.
//

enum RegisterBit {
    // CPU status register flags
    case carry
    case zero
    case interrupt
    case decimalMode
    case `break`
    case cpuStatusUnused
    case overflow
    case negative

    // PPU status register flags
    case ppuStatusUnused1
    case ppuStatusUnused2
    case ppuStatusUnused3
    case ppuStatusUnused4
    case ppuStatusUnused5
    case spriteOverflow
    case spriteZeroHit
    case verticalBlankStarted

    // APU status register flags
    case pulse1Enabled
    case pulse2Enabled
    case triangleEnabled
    case noiseEnabled
    case dmcEnabled
    case apuStatusUnused1
    case apuStatusUnused2
    case apuStatusUnused3

    // APU frame counter register flags
    case apuFrameCounterUnused1
    case apuFrameCounterUnused2
    case apuFrameCounterUnused3
    case apuFrameCounterUnused4
    case apuFrameCounterUnused5
    case apuFrameCounterUnused6
    case frameIrqInhibited
    case frameSequencerMode

    var bitIndex: Int {
        switch self {
        case .carry, .ppuStatusUnused1, .pulse1Enabled, .apuFrameCounterUnused1: 0
        case .zero, .ppuStatusUnused2, .pulse2Enabled, .apuFrameCounterUnused2: 1
        case .interrupt, .ppuStatusUnused3, .triangleEnabled, .apuFrameCounterUnused3: 2
        case .decimalMode, .ppuStatusUnused4, .noiseEnabled, .apuFrameCounterUnused4: 3
        case .break, .ppuStatusUnused5, .dmcEnabled, .apuFrameCounterUnused5: 4
        case .cpuStatusUnused, .spriteOverflow, .apuStatusUnused1, .apuFrameCounterUnused6: 5
        case .overflow, .spriteZeroHit, .apuStatusUnused2, .frameIrqInhibited: 6
        case .negative, .verticalBlankStarted, .apuStatusUnused3, .frameSequencerMode: 7
        }
    }
}
