//
//  Opcode.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/14/24.
//

enum Opcode: UInt8 {
    case andImmediate = 0x29
    case andZeroPage = 0x25
    case andZeroPageX = 0x35
    case andAbsolute = 0x2D
    case andAbsoluteX = 0x3D
    case andAbsoluteY = 0x39
    case andIndirectX = 0x21
    case andIndirectY = 0x31

    case aslAccumlator = 0x0A
    case aslZeroPage = 0x06
    case aslZeroPageX = 0x16
    case aslAbsolute = 0x0E
    case aslAbsoluteX = 0x1E

    case `break` = 0x00

    case eorImmediate = 0x49
    case eorZeroPage = 0x45
    case eorZeroPageX = 0x55
    case eorAbsolute = 0x4D
    case eorAbsoluteX = 0x5D
    case eorAbsoluteY = 0x59
    case eorIndirectX = 0x41
    case eorIndirectY = 0x51

    case inx = 0xE8

    case ldaImmediate = 0xA9
    case ldaZeroPage = 0xA5
    case ldaZeroPageX = 0xB5
    case ldaAbsolute = 0xAD
    case ldaAbsoluteX = 0xBD
    case ldaAbsoluteY = 0xB9
    case ldaIndirectX = 0xA1
    case ldaIndirectY = 0xB1

    case ldxImmediate = 0xA2
    case ldxZeroPage = 0xA6
    case ldxZeroPageY = 0xB6
    case ldxAbsolute = 0xAE
    case ldxAbsoluteY = 0xBE

    case ldyImmediate = 0xA0
    case ldyZeroPage = 0xA4
    case ldyZeroPageX = 0xB4
    case ldyAbsolute = 0xAC
    case ldyAbsoluteX = 0xBC

    case lsrAccumlator = 0x4A
    case lsrZeroPage = 0x46
    case lsrZeroPageX = 0x56
    case lsrAbsolute = 0x4E
    case lsrAbsoluteX = 0x5E

    case oraImmediate = 0x09
    case oraZeroPage = 0x05
    case oraZeroPageX = 0x15
    case oraAbsolute = 0x0D
    case oraAbsoluteX = 0x1D
    case oraAbsoluteY = 0x19
    case oraIndirectX = 0x01
    case oraIndirectY = 0x11

    case rolAccumlator = 0x2A
    case rolZeroPage = 0x26
    case rolZeroPageX = 0x36
    case rolAbsolute = 0x2E
    case rolAbsoluteX = 0x3E

    case rorAccumlator = 0x6A
    case rorZeroPage = 0x66
    case rorZeroPageX = 0x76
    case rorAbsolute = 0x6E
    case rorAbsoluteX = 0x7E

    case staZeroPage = 0x85
    case staZeroPageX = 0x95
    case staAbsolute = 0x8D
    case staAbsoluteX = 0x9D
    case staAbsoluteY = 0x99
    case staIndirectX = 0x81
    case staIndirectY = 0x91

    case tax = 0xAA
}

extension Opcode {
    var addressingMode: AddressingMode {
        switch self {
        case .andImmediate: .immediate
        case .andZeroPage: .zeroPage
        case .andZeroPageX: .zeroPageX
        case .andAbsolute: .absolute
        case .andAbsoluteX: .absoluteX
        case .andAbsoluteY: .absoluteY
        case .andIndirectX: .indirectX
        case .andIndirectY: .indirectY

        case .aslAccumlator: .accumulator
        case .aslZeroPage: .zeroPage
        case .aslZeroPageX: .zeroPageX
        case .aslAbsolute: .absolute
        case .aslAbsoluteX: .absoluteX

        case .`break`: .implicit

        case .eorImmediate: .immediate
        case .eorZeroPage: .zeroPage
        case .eorZeroPageX: .zeroPageX
        case .eorAbsolute: .absolute
        case .eorAbsoluteX: .absoluteX
        case .eorAbsoluteY: .absoluteY
        case .eorIndirectX: .indirectX
        case .eorIndirectY: .indirectY

        case .inx: .implicit

        case .ldaImmediate: .immediate
        case .ldaZeroPage: .zeroPage
        case .ldaZeroPageX: .zeroPageX
        case .ldaAbsolute: .absolute
        case .ldaAbsoluteX: .absoluteX
        case .ldaAbsoluteY: .absoluteY
        case .ldaIndirectX: .indirectX
        case .ldaIndirectY: .indirectY

        case .ldxImmediate: .immediate
        case .ldxZeroPage: .zeroPage
        case .ldxZeroPageY: .zeroPageY
        case .ldxAbsolute: .absolute
        case .ldxAbsoluteY: .absoluteY

        case .ldyImmediate: .immediate
        case .ldyZeroPage: .zeroPage
        case .ldyZeroPageX: .zeroPageX
        case .ldyAbsolute: .absolute
        case .ldyAbsoluteX: .absoluteX

        case .lsrAccumlator: .accumulator
        case .lsrZeroPage: .zeroPage
        case .lsrZeroPageX: .zeroPageX
        case .lsrAbsolute: .absolute
        case .lsrAbsoluteX: .absoluteX

        case .oraImmediate: .immediate
        case .oraZeroPage: .zeroPage
        case .oraZeroPageX: .zeroPageX
        case .oraAbsolute: .absolute
        case .oraAbsoluteX: .absoluteX
        case .oraAbsoluteY: .absoluteY
        case .oraIndirectX: .indirectX
        case .oraIndirectY: .indirectY

        case .rolAccumlator: .accumulator
        case .rolZeroPage: .zeroPage
        case .rolZeroPageX: .zeroPageX
        case .rolAbsolute: .absolute
        case .rolAbsoluteX: .absoluteX

        case .rorAccumlator: .accumulator
        case .rorZeroPage: .zeroPage
        case .rorZeroPageX: .zeroPageX
        case .rorAbsolute: .absolute
        case .rorAbsoluteX: .absoluteX

        case .staZeroPage: .zeroPage
        case .staZeroPageX: .zeroPageX
        case .staAbsolute: .absolute
        case .staAbsoluteX: .absoluteX
        case .staAbsoluteY: .absoluteY
        case .staIndirectX: .indirectX
        case .staIndirectY: .indirectY

        case .tax: .implicit
        }
    }

    var instructionLength: Int {
        switch self {
        case .andImmediate: 2
        case .andZeroPage: 2
        case .andZeroPageX: 2
        case .andAbsolute: 3
        case .andAbsoluteX: 3
        case .andAbsoluteY: 3
        case .andIndirectX: 2
        case .andIndirectY: 2

        case .aslAccumlator: 1
        case .aslZeroPage: 2
        case .aslZeroPageX: 2
        case .aslAbsolute: 3
        case .aslAbsoluteX: 3

        case .break: 1

        case .eorImmediate: 2
        case .eorZeroPage: 2
        case .eorZeroPageX: 2
        case .eorAbsolute: 3
        case .eorAbsoluteX: 3
        case .eorAbsoluteY: 3
        case .eorIndirectX: 2
        case .eorIndirectY: 2

        case .inx: 1

        case .ldaImmediate: 2
        case .ldaZeroPage: 2
        case .ldaZeroPageX: 2
        case .ldaAbsolute: 3
        case .ldaAbsoluteX: 3
        case .ldaAbsoluteY: 3
        case .ldaIndirectX: 2
        case .ldaIndirectY: 2

        case .ldxImmediate: 2
        case .ldxZeroPage: 2
        case .ldxZeroPageY: 2
        case .ldxAbsolute: 3
        case .ldxAbsoluteY: 3

        case .ldyImmediate: 2
        case .ldyZeroPage: 2
        case .ldyZeroPageX: 2
        case .ldyAbsolute: 3
        case .ldyAbsoluteX: 3

        case .lsrAccumlator: 1
        case .lsrZeroPage: 2
        case .lsrZeroPageX: 2
        case .lsrAbsolute: 3
        case .lsrAbsoluteX: 3

        case .oraImmediate: 2
        case .oraZeroPage: 2
        case .oraZeroPageX: 2
        case .oraAbsolute: 3
        case .oraAbsoluteX: 3
        case .oraAbsoluteY: 3
        case .oraIndirectX: 2
        case .oraIndirectY: 2

        case .rolAccumlator: 1
        case .rolZeroPage: 2
        case .rolZeroPageX: 2
        case .rolAbsolute: 3
        case .rolAbsoluteX: 3

        case .rorAccumlator: 1
        case .rorZeroPage: 2
        case .rorZeroPageX: 2
        case .rorAbsolute: 3
        case .rorAbsoluteX: 3

        case .staZeroPage: 2
        case .staZeroPageX: 2
        case .staAbsolute: 3
        case .staAbsoluteX: 3
        case .staAbsoluteY: 3
        case .staIndirectX: 2
        case .staIndirectY: 2

        case .tax: 1
        }
    }
}
