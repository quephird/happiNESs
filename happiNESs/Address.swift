//
//  Address.swift
//  happiNESs
//
//  Created by Danielle Kefford on 9/29/24.
//

typealias Address = UInt16

// During the rendering phase, the shared address field in the PPU
// has the following structure:
//
// 0yyy nnYY YYYX XXXX
//  ||| |||| |||| ||||
//  ||| |||| |||+-++++-- coarse x, or the x coordinate of the current tile
//  ||| |||| |||
//  ||| ||++-+++-------- course y, or the y coordinate of the current tile
//  ||| ||
//  ||| ++-------------- nametable index
//  |||
//  +++----------------- fine y of the current tile
//
// The subscript function in Address plucks out the desired bits (as a UInt8)
// based on the bit mask passed in.
enum AddressBitMask: Address {
    case fineY     = 0b0111_0000_0000_0000
    case nametable = 0b0000_1100_0000_0000
    case coarseY   = 0b0000_0011_1110_0000
    case coarseX   = 0b0000_0000_0001_1111

    case highByte  = 0b0011_1111_0000_0000
    case lowByte   = 0b0000_0000_1111_1111
}

extension Address {
    private func getBits(using bitMask: AddressBitMask) -> UInt8 {
        UInt8((self & bitMask.rawValue) >> bitMask.rawValue.trailingZeroBitCount)
    }

    mutating private func setBits(using bitMask: AddressBitMask, bits: UInt8) {
        let shiftAmount = bitMask.rawValue.trailingZeroBitCount
        let maskedBits = (Self(bits) << shiftAmount) & bitMask.rawValue
        self = (self & ~(bitMask.rawValue)) | maskedBits
    }

    subscript(index: AddressBitMask) -> UInt8 {
        get {
            self.getBits(using: index)
        }
        set {
            self.setBits(using: index, bits: newValue)
        }
    }
}
