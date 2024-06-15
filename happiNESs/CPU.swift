//
//  CPU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/14/24.
//

let RESET_VECTOR_ADDRESS: UInt16 = 0xFFFC;

public struct CPU {
    public var accumulator: UInt8
    public var statusRegister: UInt8
    public var xRegister: UInt8
    public var yRegister: UInt8
    public var programCounter: UInt16
    public var memory: [UInt8]

    init() {
        self.accumulator = 0x00
        self.statusRegister = 0x00
        self.xRegister = 0x00
        self.yRegister = 0x00
        self.programCounter = 0x0000
        self.memory = [UInt8](repeating: 0x00, count: 0xFFFF)
    }
}

extension CPU {
    mutating func and(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator &= value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func inx() {
        self.xRegister = self.xRegister &+ 1
        self.updateZeroAndNegativeFlags(result: self.xRegister)
    }

    mutating func lda(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.accumulator = value;
        self.updateZeroAndNegativeFlags(result: self.accumulator)
    }

    mutating func ldx(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.xRegister = value;
        self.updateZeroAndNegativeFlags(result: self.xRegister)
    }

    mutating func ldy(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        let value = self.readByte(address: address);
        self.yRegister = value;
        self.updateZeroAndNegativeFlags(result: self.yRegister)
    }

    mutating func sta(addressingMode: AddressingMode) {
        let address = self.getOperandAddress(addressingMode: addressingMode);
        self.writeByte(address: address, byte: self.accumulator);
    }

    mutating func tax() {
        self.xRegister = self.accumulator;
        self.updateZeroAndNegativeFlags(result: self.xRegister)
    }

    mutating func updateZeroAndNegativeFlags(result: UInt8) {
        if result == 0 {
            self.statusRegister |= 0b0000_0010;
        } else {
            self.statusRegister &= 0b1111_1101;
        }

        if (result & 0b1000_0000) != 0 {
            self.statusRegister |= 0b1000_0000;
        } else {
            self.statusRegister &= 0b0111_1111;
        }
    }
}

extension CPU {
    mutating func loadAndRun(program: [UInt8]) {
        self.load(program: program);
        self.reset();
        self.run();
    }

    mutating func load(program: [UInt8]) {
        self.memory.replaceSubrange(0x8000 ... 0x8000+program.count, with: program)
        self.writeWord(address: RESET_VECTOR_ADDRESS, word: 0x8000);
    }

    mutating func reset() {
        self.accumulator = 0x00;
        self.xRegister = 0x00;
        self.yRegister = 0x00;
        self.statusRegister = 0x00;
        self.programCounter = self.readWord(address: RESET_VECTOR_ADDRESS);
    }

    mutating func run() {
        while true {
            let byte = self.readByte(address: self.programCounter);
            if let opcode = Opcode(rawValue: byte) {
                self.programCounter += 1;
                switch byte {
                case 0x29, 0x25, 0x35, 0x2D, 0x3D, 0x39, 0x21, 0x31:
                    self.and(addressingMode: opcode.addressingMode);
                case 0x00:
                    return;
                case 0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xA1, 0xB1:
                    self.lda(addressingMode: opcode.addressingMode);
                case 0xA2, 0xA6, 0xB6, 0xAE, 0xBE:
                    self.ldx(addressingMode: opcode.addressingMode);
                case 0xA0, 0xA4, 0xB4, 0xAC, 0xBC:
                    self.ldy(addressingMode: opcode.addressingMode);
                case 0x85, 0x95, 0x8D, 0x9D, 0x99, 0x81, 0x91:
                    self.sta(addressingMode: opcode.addressingMode);
                case 0xAA:
                    self.tax()
                case 0xE8:
                    self.inx()
                default:
                    fatalError("Implement other opcodes!!!")
                }

                self.programCounter += UInt16(opcode.instructionLength - 1)
            } else {
                fatalError("Whoops! Instruction \(byte) not recognized!!!")
            }
        }
    }

    func getOperandAddress(addressingMode: AddressingMode) -> UInt16 {
        switch addressingMode {
        case .immediate:
            return self.programCounter
        case .zeroPage:
            return UInt16(self.readByte(address: self.programCounter))
        case .zeroPageX:
            let baseAddress = self.readByte(address: self.programCounter)
            return UInt16(baseAddress &+ self.xRegister)
        case .zeroPageY:
            let baseAddress = self.readByte(address: self.programCounter)
            return UInt16(baseAddress &+ self.yRegister)
        case .absolute:
            return self.readWord(address: self.programCounter)
        case .absoluteX:
            let baseAddress = self.readWord(address: self.programCounter)
            return baseAddress &+ UInt16(self.xRegister)
        case .absoluteY:
            let baseAddress = self.readWord(address: self.programCounter)
            return baseAddress &+ UInt16(self.yRegister)
        case .indirectX:
            // operand_ptr = *(void **)(constant_byte + x_register)
            let baseAddress = self.readByte(address: self.programCounter)
            let indirectAddress = baseAddress &+ self.xRegister

            let lowByte = self.readByte(address: UInt16(indirectAddress))
            let highByte = self.readByte(address: UInt16(indirectAddress &+ 1))

            return UInt16(highByte) << 8 | UInt16(lowByte)
        case .indirectY:
            // operand_ptr = *((void **)constant_byte) + y_register
            let baseAddress = self.readByte(address: self.programCounter)

            let lowByte = self.readByte(address: UInt16(baseAddress))
            let highByte = self.readByte(address: UInt16(baseAddress &+ 1))

            let indirectAddress = UInt16(highByte) << 8 | UInt16(lowByte)
            return indirectAddress &+ UInt16(self.yRegister)
        default:
            fatalError("Addressing mode not supported!")
        }
    }

    func readWord(address: UInt16) -> UInt16 {
        let lowByte = self.readByte(address: address)
        let highByte = self.readByte(address: address + 1)
        return UInt16(highByte) << 8 | UInt16(lowByte)
    }

    mutating func writeWord(address: UInt16, word: UInt16) {
        let lowByte = UInt8(word & 0xFF)
        let highByte = UInt8(word >> 8)
        self.writeByte(address: address, byte: lowByte);
        self.writeByte(address: address + 1, byte: highByte);
    }

    func readByte(address: UInt16) -> UInt8 {
        self.memory[Int(address)]
    }

    mutating func writeByte(address: UInt16, byte: UInt8) {
        self.memory[Int(address)] = byte
    }
}
