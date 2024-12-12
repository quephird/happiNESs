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

    // PPUCTRL register flags
    case nametable1  // These two bits represent the start address of the current nametable:
    case nametable2  // 00: 0x2000, 01: 0x2400, 10: 0x2800, 11: 0x2C00
    case vramAddressIncrement  // 0: add 1, going across; 1: add 32, going down
    case spritePatternBankIndex  // 0: 0x0000; 1: 0x1000; ignored in 8x16 mode
    case backgroundPatternBankIndex  // 0: 0x0000; 1: 0x1000
    case spritesAre8x16  // 0: 8x8 pixels; 1: 8x16 pixels
    case masterSlaveSelect  // 0: read backdrop from EXT pins; 1: output color on EXT pins
    case generateNmi  //0: off; 1: on

    // PPUMASK register flags
    case greyscale
    case showBackgroundLeftmostPixels
    case showSpritesLeftmostPixels
    case showBackground
    case showSprites
    case emphasizeRed
    case emphasizeGreen
    case emphasizeBlue

    // APU status register flags
    case pulse1Enabled
    case pulse2Enabled
    case triangleEnabled
    case noiseEnabled
    case dmcEnabled
    case apuStatusUnused1
    case apuStatusUnused2
    case apuStatusUnused3

    // APU frame sequencer register flags
    case apuFrameCounterUnused1
    case apuFrameCounterUnused2
    case apuFrameCounterUnused3
    case apuFrameCounterUnused4
    case apuFrameCounterUnused5
    case apuFrameCounterUnused6
    case frameIrqInhibited
    case sequencerMode

    var bitIndex: Int {
        switch self {
        case .carry, .ppuStatusUnused1, .nametable1, .greyscale, .pulse1Enabled,
            .apuFrameCounterUnused1:
            0
        case .zero, .ppuStatusUnused2, .nametable2,
            .showBackgroundLeftmostPixels, .pulse2Enabled,
            .apuFrameCounterUnused2:
            1
        case .interrupt, .ppuStatusUnused3, .vramAddressIncrement,
            .showSpritesLeftmostPixels, .triangleEnabled,
            .apuFrameCounterUnused3:
            2
        case .decimalMode, .ppuStatusUnused4, .spritePatternBankIndex,
            .showBackground, .noiseEnabled, .apuFrameCounterUnused4:
            3
        case .break, .ppuStatusUnused5, .backgroundPatternBankIndex,
            .showSprites, .dmcEnabled, .apuFrameCounterUnused5:
            4
        case .cpuStatusUnused, .spriteOverflow, .spritesAre8x16, .emphasizeRed,
            .apuStatusUnused1, .apuFrameCounterUnused6:
            5
        case .overflow, .spriteZeroHit, .masterSlaveSelect, .emphasizeGreen,
            .apuStatusUnused2, .frameIrqInhibited:
            6
        case .negative, .verticalBlankStarted, .generateNmi, .emphasizeBlue,
            .apuStatusUnused3, .sequencerMode:
            7
        }
    }
}
