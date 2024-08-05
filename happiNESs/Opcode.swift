//
//  Opcode.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/14/24.
//

enum Opcode: UInt8 {
    case adcImmediate = 0x69
    case adcZeroPage = 0x65
    case adcZeroPageX = 0x75
    case adcAbsolute = 0x6D
    case adcAbsoluteX = 0x7D
    case adcAbsoluteY = 0x79
    case adcIndirectX = 0x61
    case adcIndirectY = 0x71

    case andImmediate = 0x29
    case andZeroPage = 0x25
    case andZeroPageX = 0x35
    case andAbsolute = 0x2D
    case andAbsoluteX = 0x3D
    case andAbsoluteY = 0x39
    case andIndirectX = 0x21
    case andIndirectY = 0x31

    case aslAccumulator = 0x0A
    case aslZeroPage = 0x06
    case aslZeroPageX = 0x16
    case aslAbsolute = 0x0E
    case aslAbsoluteX = 0x1E

    case bcc = 0x90
    case bcs = 0xB0
    case beq = 0xF0

    case bitZeroPage = 0x24
    case bitAbsolute = 0x2C

    case bmi = 0x30
    case bne = 0xD0
    case bpl = 0x10

    case brk = 0x00

    case bvc = 0x50
    case bvs = 0x70

    case clc = 0x18
    case cld = 0xD8
    case cli = 0x58
    case clv = 0xB8

    case cmpImmediate = 0xC9
    case cmpZeroPage = 0xC5
    case cmpZeroPageX = 0xD5
    case cmpAbsolute = 0xCD
    case cmpAbsoluteX = 0xDD
    case cmpAbsoluteY = 0xD9
    case cmpIndirectX = 0xC1
    case cmpIndirectY = 0xD1

    case cpxImmediate = 0xE0
    case cpxZeroPage = 0xE4
    case cpxAbsolute = 0xEC

    case cpyImmediate = 0xC0
    case cpyZeroPage = 0xC4
    case cpyAbsolute = 0xCC

    case decZeroPage = 0xC6
    case decZeroPageX = 0xD6
    case decAbsolute = 0xCE
    case decAbsoluteX = 0xDE

    case dex = 0xCA
    case dey = 0x88

    case eorImmediate = 0x49
    case eorZeroPage = 0x45
    case eorZeroPageX = 0x55
    case eorAbsolute = 0x4D
    case eorAbsoluteX = 0x5D
    case eorAbsoluteY = 0x59
    case eorIndirectX = 0x41
    case eorIndirectY = 0x51

    case incZeroPage = 0xE6
    case incZeroPageX = 0xF6
    case incAbsolute = 0xEE
    case incAbsoluteX = 0xFE

    case inx = 0xE8
    case iny = 0xC8

    case jmpAbsolute = 0x4C
    case jmpIndirect = 0x6C

    case jsr = 0x20

    case laxImmediate = 0xAB
    case laxZeroPage = 0xA7
    case laxZeroPageY = 0xB7
    case laxAbsolute = 0xAF
    case laxAbsoluteY = 0xBF
    case laxIndirectX = 0xA3
    case laxIndirectY = 0xB3

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

    case lsrAccumulator = 0x4A
    case lsrZeroPage = 0x46
    case lsrZeroPageX = 0x56
    case lsrAbsolute = 0x4E
    case lsrAbsoluteX = 0x5E

    case nopImplicit1 = 0x1A
    case nopImplicit2 = 0x3A
    case nopImplicit3 = 0x5A
    case nopImplicit4 = 0x7A
    case nopImplicit5 = 0xDA
    case nopImplicit6 = 0xEA
    case nopImplicit7 = 0xFA
    case nopImmediate1 = 0x80
    case nopImmediate2 = 0x82
    case nopImmediate3 = 0x89
    case nopImmediate4 = 0xC2
    case nopImmediate5 = 0xE2
    case nopAbsolute = 0x0C
    case nopAbsoluteX1 = 0x1C
    case nopAbsoluteX2 = 0x3C
    case nopAbsoluteX3 = 0x5C
    case nopAbsoluteX4 = 0x7C
    case nopAbsoluteX5 = 0xDC
    case nopAbsoluteX6 = 0xFC
    case nopZeroPage1 = 0x04
    case nopZeroPage2 = 0x44
    case nopZeroPage3 = 0x64
    case nopZeroPageX1 = 0x14
    case nopZeroPageX2 = 0x34
    case nopZeroPageX3 = 0x54
    case nopZeroPageX4 = 0x74
    case nopZeroPageX5 = 0xD4
    case nopZeroPageX6 = 0xF4

    case oraImmediate = 0x09
    case oraZeroPage = 0x05
    case oraZeroPageX = 0x15
    case oraAbsolute = 0x0D
    case oraAbsoluteX = 0x1D
    case oraAbsoluteY = 0x19
    case oraIndirectX = 0x01
    case oraIndirectY = 0x11

    case pha = 0x48
    case php = 0x08
    case pla = 0x68
    case plp = 0x28

    case rolAccumulator = 0x2A
    case rolZeroPage = 0x26
    case rolZeroPageX = 0x36
    case rolAbsolute = 0x2E
    case rolAbsoluteX = 0x3E

    case rorAccumulator = 0x6A
    case rorZeroPage = 0x66
    case rorZeroPageX = 0x76
    case rorAbsolute = 0x6E
    case rorAbsoluteX = 0x7E

    case rti = 0x40
    case rts = 0x60

    case sbcImmediate = 0xE9
    case sbcZeroPage = 0xE5
    case sbcZeroPageX = 0xF5
    case sbcAbsolute = 0xED
    case sbcAbsoluteX = 0xFD
    case sbcAbsoluteY = 0xF9
    case sbcIndirectX = 0xE1
    case sbcIndirectY = 0xF1

    case sec = 0x38
    case sed = 0xF8
    case sei = 0x78

    case staZeroPage = 0x85
    case staZeroPageX = 0x95
    case staAbsolute = 0x8D
    case staAbsoluteX = 0x9D
    case staAbsoluteY = 0x99
    case staIndirectX = 0x81
    case staIndirectY = 0x91

    case stxZeroPage = 0x86
    case stxZeroPageY = 0x96
    case stxAbsolute = 0x8E

    case styZeroPage = 0x84
    case styZeroPageY = 0x94
    case styAbsolute = 0x8C

    case tax = 0xAA
    case tay = 0xA8
    case tsx = 0xBA
    case txa = 0x8A
    case txs = 0x9A
    case tya = 0x98
}

extension Opcode {
    var addressingMode: AddressingMode {
        switch self {
        case .adcImmediate: .immediate
        case .adcZeroPage: .zeroPage
        case .adcZeroPageX: .zeroPageX
        case .adcAbsolute: .absolute
        case .adcAbsoluteX: .absoluteX
        case .adcAbsoluteY: .absoluteY
        case .adcIndirectX: .indirectX
        case .adcIndirectY: .indirectY

        case .andImmediate: .immediate
        case .andZeroPage: .zeroPage
        case .andZeroPageX: .zeroPageX
        case .andAbsolute: .absolute
        case .andAbsoluteX: .absoluteX
        case .andAbsoluteY: .absoluteY
        case .andIndirectX: .indirectX
        case .andIndirectY: .indirectY

        case .aslAccumulator: .accumulator
        case .aslZeroPage: .zeroPage
        case .aslZeroPageX: .zeroPageX
        case .aslAbsolute: .absolute
        case .aslAbsoluteX: .absoluteX

        case .bcc: .relative
        case .bcs: .relative
        case .beq: .relative

        case .bitZeroPage: .zeroPage
        case .bitAbsolute: .absolute

        case .bmi: .relative
        case .bne: .relative
        case .bpl: .relative

        case .brk: .implicit

        case .bvc: .relative
        case .bvs: .relative

        case .clc: .implicit
        case .cld: .implicit
        case .cli: .implicit
        case .clv: .implicit

        case .cmpImmediate: .immediate
        case .cmpZeroPage: .zeroPage
        case .cmpZeroPageX: .zeroPageX
        case .cmpAbsolute: .absolute
        case .cmpAbsoluteX: .absoluteX
        case .cmpAbsoluteY: .absoluteY
        case .cmpIndirectX: .indirectX
        case .cmpIndirectY: .indirectY

        case .cpxImmediate: .immediate
        case .cpxZeroPage: .zeroPage
        case .cpxAbsolute: .absolute

        case .cpyImmediate: .immediate
        case .cpyZeroPage: .zeroPage
        case .cpyAbsolute: .absolute

        case .decZeroPage: .zeroPage
        case .decZeroPageX: .zeroPageX
        case .decAbsolute: .absolute
        case .decAbsoluteX: .absoluteX

        case .dex: .implicit
        case .dey: .implicit

        case .eorImmediate: .immediate
        case .eorZeroPage: .zeroPage
        case .eorZeroPageX: .zeroPageX
        case .eorAbsolute: .absolute
        case .eorAbsoluteX: .absoluteX
        case .eorAbsoluteY: .absoluteY
        case .eorIndirectX: .indirectX
        case .eorIndirectY: .indirectY

        case .incZeroPage: .zeroPage
        case .incZeroPageX: .zeroPageX
        case .incAbsolute: .absolute
        case .incAbsoluteX: .absoluteX

        case .inx: .implicit
        case .iny: .implicit

        case .jmpAbsolute: .absolute
        case .jmpIndirect: .indirect

        case .jsr: .absolute

        case .laxImmediate: .immediate
        case .laxZeroPage: .zeroPage
        case .laxZeroPageY: .zeroPageY
        case .laxAbsolute: .absolute
        case .laxAbsoluteY: .absoluteY
        case .laxIndirectX: .indirectX
        case .laxIndirectY: .indirectY

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

        case .lsrAccumulator: .accumulator
        case .lsrZeroPage: .zeroPage
        case .lsrZeroPageX: .zeroPageX
        case .lsrAbsolute: .absolute
        case .lsrAbsoluteX: .absoluteX

        case .nopImplicit1: .implicit
        case .nopImplicit2: .implicit
        case .nopImplicit3: .implicit
        case .nopImplicit4: .implicit
        case .nopImplicit5: .implicit
        case .nopImplicit6: .implicit
        case .nopImplicit7: .implicit
        case .nopImmediate1: .immediate
        case .nopImmediate2: .immediate
        case .nopImmediate3: .immediate
        case .nopImmediate4: .immediate
        case .nopImmediate5: .immediate
        case .nopAbsolute: .absolute
        case .nopAbsoluteX1: .absoluteX
        case .nopAbsoluteX2: .absoluteX
        case .nopAbsoluteX3: .absoluteX
        case .nopAbsoluteX4: .absoluteX
        case .nopAbsoluteX5: .absoluteX
        case .nopAbsoluteX6: .absoluteX
        case .nopZeroPage1: .zeroPage
        case .nopZeroPage2: .zeroPage
        case .nopZeroPage3: .zeroPage
        case .nopZeroPageX1: .zeroPageX
        case .nopZeroPageX2: .zeroPageX
        case .nopZeroPageX3: .zeroPageX
        case .nopZeroPageX4: .zeroPageX
        case .nopZeroPageX5: .zeroPageX
        case .nopZeroPageX6: .zeroPageX

        case .oraImmediate: .immediate
        case .oraZeroPage: .zeroPage
        case .oraZeroPageX: .zeroPageX
        case .oraAbsolute: .absolute
        case .oraAbsoluteX: .absoluteX
        case .oraAbsoluteY: .absoluteY
        case .oraIndirectX: .indirectX
        case .oraIndirectY: .indirectY

        case .pha: .implicit
        case .php: .implicit
        case .pla: .implicit
        case .plp: .implicit

        case .rolAccumulator: .accumulator
        case .rolZeroPage: .zeroPage
        case .rolZeroPageX: .zeroPageX
        case .rolAbsolute: .absolute
        case .rolAbsoluteX: .absoluteX

        case .rorAccumulator: .accumulator
        case .rorZeroPage: .zeroPage
        case .rorZeroPageX: .zeroPageX
        case .rorAbsolute: .absolute
        case .rorAbsoluteX: .absoluteX

        case .rti: .implicit
        case .rts: .implicit

        case .sbcImmediate: .immediate
        case .sbcZeroPage: .zeroPage
        case .sbcZeroPageX: .zeroPageX
        case .sbcAbsolute: .absolute
        case .sbcAbsoluteX: .absoluteX
        case .sbcAbsoluteY: .absoluteY
        case .sbcIndirectX: .indirectX
        case .sbcIndirectY: .indirectY

        case .sec: .implicit
        case .sed: .implicit
        case .sei: .implicit

        case .staZeroPage: .zeroPage
        case .staZeroPageX: .zeroPageX
        case .staAbsolute: .absolute
        case .staAbsoluteX: .absoluteX
        case .staAbsoluteY: .absoluteY
        case .staIndirectX: .indirectX
        case .staIndirectY: .indirectY

        case .stxZeroPage: .zeroPage
        case .stxZeroPageY: .zeroPageY
        case .stxAbsolute: .absolute

        case .styZeroPage: .zeroPage
        case .styZeroPageY: .zeroPageX
        case .styAbsolute: .absolute

        case .tax: .implicit
        case .tay: .implicit
        case .tsx: .implicit
        case .txa: .implicit
        case .txs: .implicit
        case .tya: .implicit
        }
    }

    var instructionLength: Int {
        switch self {
        case .adcImmediate: 2
        case .adcZeroPage: 2
        case .adcZeroPageX: 2
        case .adcAbsolute: 3
        case .adcAbsoluteX: 3
        case .adcAbsoluteY: 3
        case .adcIndirectX: 2
        case .adcIndirectY: 2

        case .andImmediate: 2
        case .andZeroPage: 2
        case .andZeroPageX: 2
        case .andAbsolute: 3
        case .andAbsoluteX: 3
        case .andAbsoluteY: 3
        case .andIndirectX: 2
        case .andIndirectY: 2

        case .aslAccumulator: 1
        case .aslZeroPage: 2
        case .aslZeroPageX: 2
        case .aslAbsolute: 3
        case .aslAbsoluteX: 3

        case .bcc: 2
        case .bcs: 2
        case .beq: 2

        case .bitZeroPage: 2
        case .bitAbsolute: 3

        case .bmi: 2
        case .bne: 2
        case .bpl: 2

        case .brk: 1

        case .bvc: 2
        case .bvs: 2

        case .clc: 1
        case .cld: 1
        case .cli: 1
        case .clv: 1

        case .cmpImmediate: 2
        case .cmpZeroPage: 2
        case .cmpZeroPageX: 2
        case .cmpAbsolute: 3
        case .cmpAbsoluteX: 3
        case .cmpAbsoluteY: 3
        case .cmpIndirectX: 2
        case .cmpIndirectY: 2

        case .cpxImmediate: 2
        case .cpxZeroPage: 2
        case .cpxAbsolute: 3

        case .cpyImmediate: 2
        case .cpyZeroPage: 2
        case .cpyAbsolute: 3

        case .decZeroPage: 2
        case .decZeroPageX: 2
        case .decAbsolute: 3
        case .decAbsoluteX: 3

        case .dex: 1
        case .dey: 1

        case .eorImmediate: 2
        case .eorZeroPage: 2
        case .eorZeroPageX: 2
        case .eorAbsolute: 3
        case .eorAbsoluteX: 3
        case .eorAbsoluteY: 3
        case .eorIndirectX: 2
        case .eorIndirectY: 2

        case .incZeroPage: 2
        case .incZeroPageX: 2
        case .incAbsolute: 3
        case .incAbsoluteX: 3

        case .inx: 1
        case .iny: 1

        case .jmpAbsolute: 3
        case .jmpIndirect: 3

        case .jsr: 3

        case .laxImmediate: 2
        case .laxZeroPage: 2
        case .laxZeroPageY: 2
        case .laxAbsolute: 3
        case .laxAbsoluteY: 3
        case .laxIndirectX: 2
        case .laxIndirectY: 2

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

        case .lsrAccumulator: 1
        case .lsrZeroPage: 2
        case .lsrZeroPageX: 2
        case .lsrAbsolute: 3
        case .lsrAbsoluteX: 3

        case .nopImplicit1: 1
        case .nopImplicit2: 1
        case .nopImplicit3: 1
        case .nopImplicit4: 1
        case .nopImplicit5: 1
        case .nopImplicit6: 1
        case .nopImplicit7: 1
        case .nopImmediate1: 2
        case .nopImmediate2: 2
        case .nopImmediate3: 2
        case .nopImmediate4: 2
        case .nopImmediate5: 2
        case .nopAbsolute: 3
        case .nopAbsoluteX1: 3
        case .nopAbsoluteX2: 3
        case .nopAbsoluteX3: 3
        case .nopAbsoluteX4: 3
        case .nopAbsoluteX5: 3
        case .nopAbsoluteX6: 3
        case .nopZeroPage1: 2
        case .nopZeroPage2: 2
        case .nopZeroPage3: 2
        case .nopZeroPageX1: 2
        case .nopZeroPageX2: 2
        case .nopZeroPageX3: 2
        case .nopZeroPageX4: 2
        case .nopZeroPageX5: 2
        case .nopZeroPageX6: 2

        case .oraImmediate: 2
        case .oraZeroPage: 2
        case .oraZeroPageX: 2
        case .oraAbsolute: 3
        case .oraAbsoluteX: 3
        case .oraAbsoluteY: 3
        case .oraIndirectX: 2
        case .oraIndirectY: 2

        case .pha: 1
        case .php: 1
        case .pla: 1
        case .plp: 1

        case .rolAccumulator: 1
        case .rolZeroPage: 2
        case .rolZeroPageX: 2
        case .rolAbsolute: 3
        case .rolAbsoluteX: 3

        case .rorAccumulator: 1
        case .rorZeroPage: 2
        case .rorZeroPageX: 2
        case .rorAbsolute: 3
        case .rorAbsoluteX: 3

        case .rti: 1
        case .rts: 1

        case .sbcImmediate: 2
        case .sbcZeroPage: 2
        case .sbcZeroPageX: 2
        case .sbcAbsolute: 3
        case .sbcAbsoluteX: 3
        case .sbcAbsoluteY: 3
        case .sbcIndirectX: 2
        case .sbcIndirectY: 2

        case .sec: 1
        case .sed: 1
        case .sei: 1

        case .staZeroPage: 2
        case .staZeroPageX: 2
        case .staAbsolute: 3
        case .staAbsoluteX: 3
        case .staAbsoluteY: 3
        case .staIndirectX: 2
        case .staIndirectY: 2

        case .stxZeroPage: 2
        case .stxZeroPageY: 2
        case .stxAbsolute: 3

        case .styZeroPage: 2
        case .styZeroPageY: 2
        case .styAbsolute: 3

        case .tax: 1
        case .tay: 1
        case .tsx: 1
        case .txa: 1
        case .txs: 1
        case .tya: 1
        }
    }
}

extension Opcode {
    var mnemonic: String {
        let opcodeString = String(describing: self)
        let endIndex = opcodeString.index(opcodeString.startIndex, offsetBy: 2)
        return opcodeString[opcodeString.startIndex ... endIndex].uppercased()
    }
}

extension Opcode {
    var isDocumented: Bool {
        switch self {
        case .nopImplicit1, .nopImplicit2, .nopImplicit3, .nopImplicit4, .nopImplicit5, .nopImplicit7,
                .nopImmediate1, .nopImmediate2, .nopImmediate3, .nopImmediate4, .nopImmediate5,
                .nopAbsolute,
                .nopAbsoluteX1, .nopAbsoluteX2, .nopAbsoluteX3, .nopAbsoluteX4, .nopAbsoluteX5, .nopAbsoluteX6,
                .nopZeroPage1, .nopZeroPage2, .nopZeroPage3,
                .nopZeroPageX1, .nopZeroPageX2, .nopZeroPageX3, .nopZeroPageX4, .nopZeroPageX5, .nopZeroPageX6,
                .laxImmediate, .laxZeroPage, .laxZeroPageY, .laxAbsolute, .laxAbsoluteY, .laxIndirectX, .laxIndirectY:
            return false
        default:
            return true
        }
    }
}
