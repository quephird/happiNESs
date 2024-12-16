//
//  MapperNumber.swift
//  happiNESs
//
//  Created by Danielle Kefford on 9/20/24.
//

public enum MapperNumber: UInt16 {
    case nrom = 0
    case mmc1 = 1
    case uxrom = 2
    case cnrom = 3
    case mmc3 = 4
    case axrom = 7

    public func makeMapper(cartridge: Cartridge, interruptible: Interruptible) -> Mapper {
        switch self {
        case .nrom:
            return Nrom(cartridge: cartridge)
        case .mmc1:
            return Mmc1(cartridge: cartridge)
        case .uxrom:
            return Uxrom(cartridge: cartridge)
        case .cnrom:
            return Cnrom(cartridge: cartridge)
        case .mmc3:
            return Mmc3(cartridge: cartridge, interruptible: interruptible)
        case .axrom:
            return Axrom(cartridge: cartridge)
        }
    }
}
