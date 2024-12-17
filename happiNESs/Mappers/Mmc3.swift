//
//  Mmc3.swift
//  happiNESs
//
//  Created by Danielle Kefford on 11/28/24.
//

class Mmc3: Mapper {
    public unowned var cartridge: Cartridge

    private var interruptible: Interruptible
    private var prgRomBankMode: UInt8 = 0
    private var chrRomBankMode: UInt8 = 0
    private var registerIndex: Int = 0
    private var registers: [UInt8] = [UInt8](repeating: 0x00, count: 8)
    private var prgOffsets: [Int] = [Int](repeating: 0, count: 4)
    private var chrOffsets: [Int] = [Int](repeating: 0, count: 8)
    private var irqCounter: UInt8 = 0
    private var irqCounterReload: UInt8 = 0
    private var irqEnabled: Bool = false

    init(cartridge: Cartridge, interruptible: Interruptible) {
        self.cartridge = cartridge
        self.interruptible = interruptible

        self.prgOffsets[0] = self.prgBankOffset(index: 0)
        self.prgOffsets[1] = self.prgBankOffset(index: 1)
        self.prgOffsets[2] = self.prgBankOffset(index: -2)
        self.prgOffsets[3] = self.prgBankOffset(index: -1)
    }

    public func readByte(address: UInt16) -> UInt8 {
        switch address {
        case 0x0000 ... 0x1FFF:
            let bank = Int(address / 0x0400)
            let bankOffset = Int(address % 0x0400)
            let memoryIndex = Int(self.chrOffsets[bank]) + bankOffset
            return self.cartridge.chrMemory[memoryIndex]
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            return self.cartridge.sram[index]
        case 0x8000 ... 0xFFFF:
            let addressOffset = address - 0x8000
            let bank = Int(addressOffset / 0x2000)
            let bankOffset = Int(addressOffset % 0x2000)
            let memoryIndex = Int(self.prgOffsets[bank]) + bankOffset
            return self.cartridge.prgMemory[memoryIndex]
        default:
            print("Attempted to read cartridge at address: \(address)")
            return 0x00
        }
    }

    // This tick function is called directly from the PPU tick function,
    // borrowing the PPU so that it can access its state without copying.
    public func tick(ppu: borrowing PPU) {
        if ppu.cycles != 280 {
            return
        }

        if !ppu.isRenderLine {
            return
        }

        if !ppu.isRenderingEnabled {
            return
        }

        self.handleScanLine()
    }

    private func handleScanLine() {
        if self.irqCounter == 0 {
            self.irqCounter = self.irqCounterReload
        } else {
            self.irqCounter -= 1

            if self.irqCounter == 0 && self.irqEnabled {
                self.interruptible.triggerIrq()
            }
        }
    }

    public func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case 0x0000 ... 0x1FFF:
            let bank = Int(address / 0x0400)
            let bankOffset = Int(address % 0x0400)
            let memoryIndex = Int(self.chrOffsets[bank]) + bankOffset
            self.cartridge.chrMemory[memoryIndex] = byte
        case 0x6000 ... 0x7FFF:
            let index = Int(address - 0x6000)
            self.cartridge.sram[index] = byte
        case 0x8000 ... 0xFFFF:
            self.writeRegister(address: address, byte: byte)
        default:
            print("Attempted to write to cartridge at address: \(address)")
        }
    }

    private func writeRegister(address: UInt16, byte: UInt8) {
        switch address {
        case 0x0000 ... 0x9FFF:
            switch address%2 == 0 {
            case true:
                self.writeBankSelect(byte: byte)
            case false:
                self.writeBankData(byte: byte)
            }
        case 0xA000 ... 0xBFFF:
            switch address%2 == 0 {
            case true:
                self.writeMirror(byte: byte)
            case false:
                self.writeProtect(byte: byte)
            }
        case 0xC000 ... 0xDFFF:
            switch address%2 == 0 {
            case true:
                self.writeIrqLatch(byte: byte)
            case false:
                self.writeIrqReload(byte: byte)
            }
        default:
            switch address%2 == 0 {
            case true:
                self.writeIrqDisable(byte: byte)
            case false:
                self.writeIrqEnable(byte: byte)
            }
        }
    }


    private func writeBankData(byte: UInt8) {
        self.registers[self.registerIndex] = byte
        self.updateOffsets()
    }

    private func writeBankSelect(byte: UInt8) {
        self.prgRomBankMode = (byte >> 6) & 1
        self.chrRomBankMode = (byte >> 7) & 1
        self.registerIndex = Int(byte & 7)
        self.updateOffsets()
    }

    private func writeProtect(byte: UInt8) {
        // No-op
    }

    private func writeMirror(byte: UInt8) {
        switch byte & 1 {
        case 0:
            self.cartridge.mirroring = .vertical
        default:
            self.cartridge.mirroring = .horizontal
        }
    }

    private func writeIrqReload(byte: UInt8) {
        self.irqCounter = 0
    }

    private func writeIrqLatch(byte: UInt8) {
        self.irqCounterReload = byte
    }

    private func writeIrqEnable(byte: UInt8) {
        // Note that the input is ignored
        self.irqEnabled = true
    }

    private func writeIrqDisable(byte: UInt8) {
        // Note that the input is ignored
        self.irqEnabled = false
    }

    private func prgBankOffset(index: Int) -> Int {
        var copyIndex = index
        if copyIndex >= 0x80 {
            copyIndex -= 0x100
        }

        copyIndex %= self.cartridge.prgMemory.count / 0x2000

        var offset = copyIndex * 0x2000
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

        copyIndex %= self.cartridge.chrMemory.count / 0x0400

        var offset = copyIndex * 0x0400
        if offset < 0 {
            offset += self.cartridge.chrMemory.count
        }

        return offset
    }

    private func updateOffsets() {
        switch self.prgRomBankMode {
        case 0:
            self.prgOffsets[0] = self.prgBankOffset(index: Int(self.registers[6]))
            self.prgOffsets[1] = self.prgBankOffset(index: Int(self.registers[7]))
            self.prgOffsets[2] = self.prgBankOffset(index: -2)
            self.prgOffsets[3] = self.prgBankOffset(index: -1)
        case 1:
            self.prgOffsets[0] = self.prgBankOffset(index: -2)
            self.prgOffsets[1] = self.prgBankOffset(index: Int(self.registers[7]))
            self.prgOffsets[2] = self.prgBankOffset(index: Int(self.registers[6]))
            self.prgOffsets[3] = self.prgBankOffset(index: -1)
        default:
            break
        }

        switch self.chrRomBankMode {
        case 0:
            self.chrOffsets[0] = self.chrBankOffset(index: Int(self.registers[0] & 0xFE))
            self.chrOffsets[1] = self.chrBankOffset(index: Int(self.registers[0] | 0x01))
            self.chrOffsets[2] = self.chrBankOffset(index: Int(self.registers[1] & 0xFE))
            self.chrOffsets[3] = self.chrBankOffset(index: Int(self.registers[1] | 0x01))
            self.chrOffsets[4] = self.chrBankOffset(index: Int(self.registers[2]))
            self.chrOffsets[5] = self.chrBankOffset(index: Int(self.registers[3]))
            self.chrOffsets[6] = self.chrBankOffset(index: Int(self.registers[4]))
            self.chrOffsets[7] = self.chrBankOffset(index: Int(self.registers[5]))
        case 1:
            self.chrOffsets[0] = self.chrBankOffset(index: Int(self.registers[2]))
            self.chrOffsets[1] = self.chrBankOffset(index: Int(self.registers[3]))
            self.chrOffsets[2] = self.chrBankOffset(index: Int(self.registers[4]))
            self.chrOffsets[3] = self.chrBankOffset(index: Int(self.registers[5]))
            self.chrOffsets[4] = self.chrBankOffset(index: Int(self.registers[0] & 0xFE))
            self.chrOffsets[5] = self.chrBankOffset(index: Int(self.registers[0] | 0x01))
            self.chrOffsets[6] = self.chrBankOffset(index: Int(self.registers[1] & 0xFE))
            self.chrOffsets[7] = self.chrBankOffset(index: Int(self.registers[1] | 0x01))
        default:
            break
        }
    }
}
