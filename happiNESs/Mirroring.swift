//
//  Mirroring.swift
//  happiNESs
//
//  Created by Danielle Kefford on 7/4/24.
//

public enum Mirroring: Int {
    // The actual "physical" layout of the nametables in the PPU VRAM is
    // the following:
    //
    //     [ A ] [ B ]
    //
    // where A is the primary nametable and B is the secondary nametable,
    // each with 1024 byte, the first of which allocated for 32 x 30 = 960
    // tiles, and next 64 bytes which is reserved for the pattern tables.
    //
    // However, the way PPU memory addresses map to the nametables depends on
    // the current mirroring strategy of the cartridge. In PPU address space,
    // there are virtually _four_ nametables, two of which are mirrors of the
    // other two:
    //
    //     [ 0 ] [ 1 ]
    //     [ 2 ] [ 3 ]
    //
    // And so, we need to map the inbound nametable to the actual one in PPU VRAM.
    // For example, with vertical mirroring, virtual nametable indices 0 and 2
    // need to map to actual nametable A, whereas indices 1 and 3 need to map to
    // B:
    //
    //     [ A ] [ B ]
    //     [ A ] [ B ]
    //
    // For horizontal mirroring, virtual nametable indices 0 and 1 need to map to
    // actual nametable A, whereas indices 2 and 3 need to map to B:
    //
    //     [ A ] [ A ]
    //     [ B ] [ B ]
    //
    // The two-dimensional array below encapsulates these mappings, with the
    // raw value of the mirroring strategy as the first index, and the inbound
    // nametable index as the second index.
    static let nametableIndexLookup: [[Int]] = [
        [0, 0, 1, 1],
        [0, 1, 0, 1],
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 1, 2, 3],
    ]

    case horizontal = 0
    case vertical = 1
    case singleScreen0 = 2
    case singleScreen1 = 3
    case fourScreen = 4

    public func actualNametableIndex(for nametableIndex: Int) -> Int {
        Self.nametableIndexLookup[self.rawValue][nametableIndex]
    }
}
