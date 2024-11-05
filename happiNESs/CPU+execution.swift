//
//  CPU+execution.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/6/24.
//

public enum StopCondition {
    case instructions(Int)
    case nextFrame
}

extension CPU {
    // NOTA BENE: This method is only ever called from unit tests.
    public func executeInstructions(stoppingAfter: Int) {
        executeInstructions(stoppingAfter: .instructions(stoppingAfter))
    }

    public func executeInstructions(stoppingAfter: StopCondition) {
        switch stoppingAfter {
        case .instructions(let count):
            (0..<count).forEach { i in
                let _ = self.executeInstruction()
            }

        case .nextFrame:
            // We keep calling executeInstruction() until it returns
            // `true`, in which case the screen needs redrawing.
            while !executeInstruction() {
            }
        }
    }

    // This method returns the value from the call to Bus.tick()
    // which represents whether or not the screen needs to be redrawn
    func executeInstruction() -> Bool {
        if self.stall > 0 {
            self.stall -= 1
            return self.bus.tick(cycles: 1)
        }

        switch self.interrupt {
        case .nmi:
            self.handleNmi()
            self.interrupt = .none
        case .irq:
            self.handleIrq()
            self.interrupt = .none
        default:
            break
        }

        if self.tracingOn {
            print(happiNESs.trace(cpu: self))
        }

        let byte = self.readByte(address: self.programCounter);
        if let opcode = Opcode(rawValue: byte) {
            self.programCounter += 1;

            let (programCounterMutated, extraCycles) = switch opcode {
            case .adcImmediate, .adcZeroPage, .adcZeroPageX, .adcAbsolute, .adcAbsoluteX, .adcAbsoluteY, .adcIndirectX, .adcIndirectY:
                self.adc(addressingMode: opcode.addressingMode)
            case .andImmediate, .andZeroPage, .andZeroPageX, .andAbsolute, .andAbsoluteX, .andAbsoluteY, .andIndirectX, .andIndirectY:
                self.and(addressingMode: opcode.addressingMode)
            case .aslAccumulator, .aslZeroPage, .aslZeroPageX, .aslAbsolute, .aslAbsoluteX:
                self.asl(addressingMode: opcode.addressingMode)
            case .bcc:
                self.bcc()
            case .bcs:
                self.bcs()
            case .beq:
                self.beq()
            case .bitZeroPage, .bitAbsolute:
                self.bit(addressingMode: opcode.addressingMode)
            case .bmi:
                self.bmi()
            case .bne:
                self.bne()
            case .bpl:
                self.bpl()
            case .brk:
                self.brk()
            case .bvc:
                self.bvc()
            case .bvs:
                self.bvs()
            case .clc:
                self.clc()
            case .cld:
                self.cld()
            case .cli:
                self.cli()
            case .clv:
                self.clv()
            case .cmpImmediate, .cmpZeroPage, .cmpZeroPageX, .cmpAbsolute, .cmpAbsoluteX, .cmpAbsoluteY, .cmpIndirectX, .cmpIndirectY:
                self.cmp(addressingMode: opcode.addressingMode)
            case .cpxImmediate, .cpxZeroPage, .cpxAbsolute:
                self.cpx(addressingMode: opcode.addressingMode)
            case .cpyImmediate, .cpyZeroPage, .cpyAbsolute:
                self.cpy(addressingMode: opcode.addressingMode)
            case .dcpAbsolute, .dcpAbsoluteX, .dcpAbsoluteY, .dcpZeroPage, .dcpZeroPageX, .dcpIndirectX, .dcpIndirectY:
                self.dcp(addressingMode: opcode.addressingMode)
            case .decZeroPage, .decZeroPageX, .decAbsolute, .decAbsoluteX:
                self.dec(addressingMode: opcode.addressingMode)
            case .dex:
                self.dex()
            case .dey:
                self.dey()
            case .eorImmediate, .eorZeroPage, .eorZeroPageX, .eorAbsolute, .eorAbsoluteX, .eorAbsoluteY, .eorIndirectX, .eorIndirectY:
                self.eor(addressingMode: opcode.addressingMode)
            case .incZeroPage, .incZeroPageX, .incAbsolute, .incAbsoluteX:
                self.inc(addressingMode: opcode.addressingMode)
            case .inx:
                self.inx()
            case .iny:
                self.iny()
            case .isbAbsolute, .isbAbsoluteX, .isbAbsoluteY, .isbZeroPage, .isbZeroPageX, .isbIndirectX, .isbIndirectY:
                self.isb(addressingMode: opcode.addressingMode)
            case .jmpAbsolute, .jmpIndirect:
                self.jmp(addressingMode: opcode.addressingMode)
            case .jsr:
                self.jsr()
            case .laxImmediate, .laxZeroPage, .laxZeroPageY, .laxAbsolute, .laxAbsoluteY, .laxIndirectX, .laxIndirectY:
                self.lax(addressingMode: opcode.addressingMode)
            case .ldaImmediate, .ldaZeroPage, .ldaZeroPageX, .ldaAbsolute, .ldaAbsoluteX, .ldaAbsoluteY, .ldaIndirectX, .ldaIndirectY:
                self.lda(addressingMode: opcode.addressingMode)
            case .ldxImmediate, .ldxZeroPage, .ldxZeroPageY, .ldxAbsolute, .ldxAbsoluteY:
                self.ldx(addressingMode: opcode.addressingMode)
            case .ldyImmediate, .ldyZeroPage, .ldyZeroPageX, .ldyAbsolute, .ldyAbsoluteX:
                self.ldy(addressingMode: opcode.addressingMode)
            case .lsrAccumulator, .lsrZeroPage, .lsrZeroPageX, .lsrAbsolute, .lsrAbsoluteX:
                self.lsr(addressingMode: opcode.addressingMode)
            case .nopImplicit1, .nopImplicit2, .nopImplicit3, .nopImplicit4, .nopImplicit5, .nopImplicit6, .nopImplicit7,
                    .nopImmediate1, .nopImmediate2, .nopImmediate3, .nopImmediate4, .nopImmediate5,
                    .nopAbsolute,
                    .nopAbsoluteX1, .nopAbsoluteX2, .nopAbsoluteX3, .nopAbsoluteX4, .nopAbsoluteX5, .nopAbsoluteX6,
                    .nopZeroPage1, .nopZeroPage2, .nopZeroPage3,
                    .nopZeroPageX1, .nopZeroPageX2, .nopZeroPageX3, .nopZeroPageX4, .nopZeroPageX5, .nopZeroPageX6:
                self.nop(addressingMode: opcode.addressingMode)
            case .oraImmediate, .oraZeroPage, .oraZeroPageX, .oraAbsolute, .oraAbsoluteX, .oraAbsoluteY, .oraIndirectX, .oraIndirectY:
                self.ora(addressingMode: opcode.addressingMode)
            case .pha:
                self.pha()
            case .php:
                self.php()
            case .pla:
                self.pla()
            case .plp:
                self.plp()
            case .rlaAbsolute, .rlaAbsoluteX, .rlaAbsoluteY, .rlaZeroPage, .rlaZeroPageX, .rlaIndirectX, .rlaIndirectY:
                self.rla(addressingMode: opcode.addressingMode)
            case .rolAccumulator, .rolZeroPage, .rolZeroPageX, .rolAbsolute, .rolAbsoluteX:
                self.rol(addressingMode: opcode.addressingMode)
            case .rorAccumulator, .rorZeroPage, .rorZeroPageX, .rorAbsolute, .rorAbsoluteX:
                self.ror(addressingMode: opcode.addressingMode)
            case .rraAbsolute, .rraAbsoluteX, .rraAbsoluteY, .rraZeroPage, .rraZeroPageX, .rraIndirectX, .rraIndirectY:
                self.rra(addressingMode: opcode.addressingMode)
            case .rti:
                self.rti()
            case .rts:
                self.rts()
            case .saxZeroPage, .saxZeroPageY, .saxAbsolute, .saxIndirectX:
                self.sax(addressingMode: opcode.addressingMode)
            case .sbcImmediate1, .sbcImmediate2, .sbcZeroPage, .sbcZeroPageX, .sbcAbsolute, .sbcAbsoluteX, .sbcAbsoluteY, .sbcIndirectX, .sbcIndirectY:
                self.sbc(addressingMode: opcode.addressingMode)
            case .sec:
                self.sec()
            case .sed:
                self.sed()
            case .sei:
                self.sei()
            case .shaAbsoluteY, .shaIndirectY:
                self.sha(addressingMode: opcode.addressingMode)
            case .sloAbsolute, .sloAbsoluteX, .sloAbsoluteY, .sloZeroPage, .sloZeroPageX, .sloIndirectX, .sloIndirectY:
                self.slo(addressingMode: opcode.addressingMode)
            case .sreAbsolute, .sreAbsoluteX, .sreAbsoluteY, .sreZeroPage, .sreZeroPageX, .sreIndirectX, .sreIndirectY:
                self.sre(addressingMode: opcode.addressingMode)
            case .staZeroPage, .staZeroPageX, .staAbsolute, .staAbsoluteX, .staAbsoluteY, .staIndirectX, .staIndirectY:
                self.sta(addressingMode: opcode.addressingMode)
            case .stxZeroPage, .stxZeroPageY, .stxAbsolute:
                self.stx(addressingMode: opcode.addressingMode)
            case .styZeroPage, .styZeroPageY, .styAbsolute:
                self.sty(addressingMode: opcode.addressingMode)
            case .tax:
                self.tax()
            case .tay:
                self.tay()
            case .tsx:
                self.tsx()
            case .txa:
                self.txa()
            case .txs:
                self.txs()
            case .tya:
                self.tya()
            }

            let totalCycles = opcode.cycles + extraCycles
            let result = self.bus.tick(cycles: totalCycles)

            if !programCounterMutated {
                self.programCounter += UInt16(opcode.instructionLength - 1)
            }

            return result
        } else {
            fatalError("Whoops! Instruction \(byte) at \(programCounter) not recognized!!!")
        }
    }
}
