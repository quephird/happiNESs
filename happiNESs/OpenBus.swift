//
//  OpenBus.swift
//  happiNESs
//
//  Created by Danielle Kefford on 12/17/24.
//

public struct OpenBus {
    // Technically, this isn't _quite_ right as each bit supposedly
    // independently decays, but for the time being we're modeling
    // the open bus as byte that decays all at once. The number of
    // cycles that the byte "lasts" without refreshing is computed
    // from the results of experiments done by enthusiasts, who have
    // measure the amount of time to be about 600 milliseconds.
    // This amount of time translates to the number of PPU cycles in
    // in the following manner:
    //
    // .6 sec / (1000/60 frames/sec) = 36 frames
    // 1 frame = 341*262 = 89342 PPU cycles
    // 36 frames * 89342 cycles/frame = 3216312 cycles
    static let resetDecayCycles: Int = 3_216_312

    public var value: Register = 0x00
    private var decayCycles: Int = Self.resetDecayCycles
}

extension OpenBus {
    mutating public func refreshDecayCycles() {
        self.decayCycles = Self.resetDecayCycles
    }

    mutating public func tick() {
        if self.decayCycles > 0 {
            self.decayCycles -= 1
        }

        if self.decayCycles == 0 {
            self.value = 0
        }
    }
}
