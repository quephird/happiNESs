//
//  MapperNumber.swift
//  happiNESs
//
//  Created by Danielle Kefford on 9/20/24.
//

public enum MapperNumber: UInt8 {
    case nrom = 0
    case uxrom = 2
    case cnrom = 3
    case axrom = 7

    public func makeMapper() -> Mapper {
        switch self {
        case .nrom:
            return Nrom()
        case .uxrom:
            return Uxrom()
        case .cnrom:
            return Cnrom()
        case .axrom:
            return Axrom()
        }
    }
}
