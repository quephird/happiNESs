//
//  OpenBus.swift
//  happiNESs
//
//  Created by Danielle Kefford on 12/17/24.
//

public struct OpenBus {
    static let resetDecayCycles: Int = 4_288_392

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
