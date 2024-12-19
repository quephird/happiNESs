//
//  AddressingMode.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/14/24.
//

enum AddressingMode {
    case accumulator
    case immediate
    case implicit
    case relative
    case zeroPage
    case zeroPageX
    case zeroPageY
    case absolute
    case absoluteX
    case absoluteXDummyRead
    case absoluteY
    case absoluteYDummyRead
    case indirect
    case indirectX
    case indirectY
    case indirectYDummyRead
}
