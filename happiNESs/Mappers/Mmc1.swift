//
//  Mmc1.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/29/24.
//

struct Mmc1: Mapper {
    public var cartridge: Cartridge

    private var prgRomBankMode: Int = 0
    private var chrRomBankMode: Int = 0
    private var prgBank: UInt8 = 0
    private var chrBank0: UInt8 = 0
    private var chrBank1: UInt8 = 0
    private var prgOffsets: [Int] = [Int](repeating: 0, count: 2)
    private var chrOffsets: [Int] = [Int](repeating: 0, count: 2)
    private var shiftRegister: UInt8 = 0x10
    private var controlRegister: UInt8 = 0x00

    init(cartridge: Cartridge) {
        self.cartridge = cartridge
        self.prgOffsets[1] = self.prgBankOffset(index: -1)
    }

    public func readByte(address: UInt16) -> UInt8 {
        switch address {
        case 0x0000 ... 0x1FFF:
            let bank = Int(address / 0x1000)
            let bankOffset = Int(address % 0x1000)
            let memoryIndex = Int(self.chrOffsets[bank]) + bankOffset
            return self.cartridge.chrMemory[memoryIndex]
        case 0x8000 ... 0xFFFF:
            let addressOffset = address - 0x8000
            let bank = Int(addressOffset / 0x4000)
            let bankOffset = Int(addressOffset % 0x4000)
            let memoryIndex = Int(self.prgOffsets[bank]) + bankOffset
            return self.cartridge.prgMemory[memoryIndex]
        default:
            print("Attempted to read cartridge at address: \(address)")
            return 0x00
        }
    }

    mutating public func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case 0x0000 ... 0x1FFF:
            let bank = Int(address / 0x1000)
            let bankOffset = Int(address % 0x1000)
            let memoryIndex = Int(self.chrOffsets[bank]) + bankOffset
            self.cartridge.chrMemory[memoryIndex] = byte
        case 0x8000 ... 0xFFFF:
            self.updateRegisters(address: address, byte: byte)
        default:
            print("Attempted to write to cartridge at address: \(address)")
        }
    }

    mutating private func updateRegisters(address: UInt16, byte: UInt8) {
        if byte & 0x80 == 0x80 {
            self.shiftRegister = 0x10
            self.updateControlRegister(byte: self.controlRegister | 0x0C)
            self.updateOffsets()
        } else {
            let writeComplete = (self.shiftRegister & 0x01) == 0x01
            self.shiftRegister >>= 1
            self.shiftRegister |= ((byte & 0x01) << 4)

            if writeComplete {
                self.updateOtherThings(address: address, byte: self.shiftRegister)
                self.shiftRegister = 0x10
                self.updateOffsets()
            }
        }
    }

    mutating private func updateOtherThings(address: UInt16, byte: UInt8) {
        switch address {
        case 0x0000 ... 0x9FFF:
            self.updateControlRegister(byte: byte)
        case 0xA000 ... 0xBFFF:
            self.chrBank0 = byte
        case 0xC000 ... 0xDFFF:
            self.chrBank1 = byte
        default:
            self.prgBank = byte & 0x0F
        }
    }

    mutating private func updateControlRegister(byte: UInt8) {
        self.controlRegister = byte

        let mirroringBits = self.controlRegister & 0b0000_0011
        switch mirroringBits {
        case 0:
            self.cartridge.mirroring = .singleScreen0
        case 1:
            self.cartridge.mirroring = .singleScreen1
        case 2:
            self.cartridge.mirroring = .vertical
        case 3:
            self.cartridge.mirroring = .horizontal
        default:
            break
        }

        self.prgRomBankMode = Int((self.controlRegister & 0b0000_1100) >> 2)
        self.chrRomBankMode = Int((self.controlRegister & 0b0001_0000) >> 4)
    }

    mutating private func updateOffsets() {
        switch self.prgRomBankMode {
        case 0, 1:
            self.prgOffsets[0] = self.prgBankOffset(index: Int(self.prgBank & 0xFE))
            self.prgOffsets[1] = self.prgBankOffset(index: Int(self.prgBank | 0x01))
        case 2:
            self.prgOffsets[0] = 0
            self.prgOffsets[1] = self.prgBankOffset(index: Int(self.prgBank))
        case 3:
            self.prgOffsets[0] = self.prgBankOffset(index: Int(self.prgBank))
            self.prgOffsets[1] = self.prgBankOffset(index: -1)
        default:
            break
        }

        switch self.chrRomBankMode {
        case 0:
            self.chrOffsets[0] = self.chrBankOffset(index: Int(self.chrBank0 & 0xFE))
            self.chrOffsets[1] = self.chrBankOffset(index: Int(self.chrBank0 | 0x01))
        case 1:
            self.chrOffsets[0] = self.chrBankOffset(index: Int(self.chrBank0))
            self.chrOffsets[1] = self.chrBankOffset(index: Int(self.chrBank1))
        default:
            break
        }
    }

    private func prgBankOffset(index: Int) -> Int {
        var copyIndex = index
        if copyIndex >= 0x80 {
            copyIndex -= 0x100
        }

        copyIndex %= self.cartridge.prgMemory.count / 0x4000

        var offset = copyIndex * 0x4000
        if offset < 0 {
            offset += self.cartridge.prgMemory.count
        }

        return offset
    }

    private func chrBankOffset(index: Int) -> Int {
        var copyIndex = index
        if copyIndex >= 0x80 {
            copyIndex -= 0x100
        }

        copyIndex %= self.cartridge.chrMemory.count / 0x1000

        var offset = copyIndex * 0x1000
        if offset < 0 {
            offset += self.cartridge.chrMemory.count
        }

        return offset
    }
}
