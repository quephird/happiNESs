//
//  NESColor.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/29/24.
//

public enum NESColor {
    case black
    case white
    case grey
    case red
    case green
    case blue
    case magenta
    case yellow
    case cyan

    init(byte: UInt8) {
        switch byte {
        case 0: self = .black
        case 1: self = .white
        case 2, 9: self = .grey
        case 3, 10: self = .red
        case 4, 11: self = .green
        case 5, 12: self = .blue
        case 6, 13: self = .magenta
        case 7, 14: self = .yellow
        default: self = .cyan
        }
    }
}
