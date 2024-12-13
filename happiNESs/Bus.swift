//
//  Bus.swift
//  happiNESs
//
//  Created by Danielle Kefford on 7/4/24.
//

public class Bus {
    static let ramMirrorsBegin: UInt16 = 0x0000;
    static let ramMirrorsEnd: UInt16 = 0x1FFF;
    static let ppuRegistersMirrorsBegin: UInt16 = 0x2000;
    static let ppuRegistersMirrorsEnd: UInt16 = 0x3FFF;

    public var cpu: CPU? = nil
    public var ppu: PPU
    public var apu: APU
    public var cartridge: Cartridge?
    var vram: [UInt8]
    var joypad: Joypad

    public init() {
        self.ppu = PPU()
        // TODO: Need to explain this!!!
        self.apu = APU(sampleRate: Float(CPU.frequency) / APU.audioSampleRate)

        self.vram = [UInt8](repeating: 0x00, count: 2048)
        self.joypad = Joypad()

        // NOTA BENE: We need to do this because there needs to be
        // bidirectional communication between the bus and both
        // the PPU and APU.
        self.ppu.bus = self
        self.apu.dmc.bus = self
        self.apu.bus = self
    }

    public func loadCartridge(cartridge: Cartridge) {
        self.cartridge = cartridge
        self.ppu.cartridge = cartridge
    }

    public func reset() {
        self.ppu.reset()
        self.apu.reset()
    }
}

extension Bus {
    // NOTA BENE: Called directly by the tracer, as well as by readByte()
    func readByteWithoutMutating(address: UInt16) -> UInt8 {
        switch address {
        case 0x0000 ... 0x1FFF:
            let vramAddress = Int(address & 0b0000_0111_1111_1111)
            return self.vram[vramAddress]
        case 0x2000 ... 0x3FFF:
            return self.ppu.readByteWithoutMutating(address: address)
        case 0x4015:
            return self.apu.readByte(address: address)
        case 0x4016:
            return self.joypad.readByteWithoutMutating()
        case 0x6000 ... 0xFFFF:
            return self.cartridge!.readByte(address: address)
        default:
            return 0x00
        }
    }

    func readByte(address: UInt16) -> UInt8 {
        switch address {
        case 0x2000 ... 0x3FFF:
            return self.ppu.readByte(address: address)
        case 0x4016:
            return self.joypad.readByte()
        default:
            return self.readByteWithoutMutating(address: address)
        }
    }

    func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case 0x0000 ... 0x1FFF:
            let vramAddress = Int(address & 0b0000_0111_1111_1111)
            self.vram[vramAddress] = byte
        case 0x2000 ... 0x3FFF:
            self.ppu.writeByte(address: address, byte: byte)
        case 0x4014:
            var buffer: [UInt8] = [UInt8](repeating: 0, count: 256)
            let baseAddress: UInt16 = UInt16(byte) << 8

            for index in 0 ..< 256 {
                buffer[index] = self.readByte(address: baseAddress + UInt16(index))
            }
            self.ppu.writeOamDma(buffer: buffer)

            self.cpu!.stall += 513
            if self.cpu!.cycles%2 == 1 {
                self.cpu!.stall += 1
            }
        case 0x4000 ... 0x4008, 0x400A ... 0x400C, 0x400E ... 0x4013, 0x4015, 0x4017:
            self.apu.writeByte(address: address, byte: byte)
        case 0x4016:
            self.joypad.writeByte(byte: byte)
        case 0x6000 ... 0xFFFF:
            self.cartridge!.writeByte(address: address, byte: byte)
        default:
            break
        }
    }
}

extension Bus {
    public func triggerNmi() {
        self.cpu!.interrupt = .nmi
    }

    public func triggerIrq() {
        if !self.cpu!.status[.interruptsDisabled] {
            self.cpu!.interrupt = .irq
        }
    }
}
