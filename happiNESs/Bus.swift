//
//  Bus.swift
//  happiNESs
//
//  Created by Danielle Kefford on 7/4/24.
//

public struct Bus {
    static let ramMirrorsBegin: UInt16 = 0x0000;
    static let ramMirrorsEnd: UInt16 = 0x1FFF;
    static let ppuRegistersMirrorsBegin: UInt16 = 0x2000;
    static let ppuRegistersMirrorsEnd: UInt16 = 0x3FFF;

    var ppu: PPU
    var vram: [UInt8]
    var prgRom: [UInt8]
    var cycles: Int
    var joypad: Joypad

    public init(rom: Rom) {
        let ppu = PPU(chrRom: rom.chrRom, mirroring: rom.mirroring)

        self.ppu = ppu
        self.vram = [UInt8](repeating: 0x00, count: 2048)
        self.prgRom = rom.prgRom
        self.cycles = 0
        self.joypad = Joypad()
    }
}

extension Bus {
    private func readPrgRom(address: UInt16) -> UInt8 {
        var addressOffset = address - 0x8000

        // Mirror if needed
        if self.prgRom.count == 0x4000 && addressOffset >= 0x4000 {
            addressOffset = addressOffset % 0x4000
        }

        return self.prgRom[Int(addressOffset)]
    }

    // NOTA BENE: Called directly by the tracer, as well as by readByte()
    func readByteWithoutMutating(address: UInt16) -> UInt8 {
        switch address {
        case Self.ramMirrorsBegin ... Self.ramMirrorsEnd:
            let vramAddress = Int(address & 0b0000_0111_1111_1111)
            return self.vram[vramAddress]
        case 0x2000, 0x2001, 0x2003, 0x2005, 0x2006, 0x4014:
            // Reads from these addresses should not happen as they are write-only,
            // but we return 0x00 nonetheless.
            return 0x00
        case 0x2002:
            return self.ppu.readStatusWithoutMutating()
        case 0x2007:
            return self.ppu.readByteWithoutMutating().result
        case 0x2008...Self.ppuRegistersMirrorsEnd:
            let mirrorDownAddress = address & 0b0010_0000_0000_0111
            return self.readByteWithoutMutating(address: mirrorDownAddress)
        case 0x4016:
            return self.joypad.readByteWithoutMutating()
        case 0x8000 ... 0xFFFF:
            return self.readPrgRom(address: address)
        default:
            // TODO: Implement memory reading from these addresses?
            return 0x00
        }
    }

    mutating func readByte(address: UInt16) -> UInt8 {
        switch address {
        case 0x2002:
            return self.ppu.readStatus()
        case 0x2004:
            return self.ppu.readOAMData()
        case 0x2007:
            return self.ppu.readByte()
        case 0x2008...Self.ppuRegistersMirrorsEnd:
            let mirrorDownAddress = address & 0b0010_0000_0000_0111
            return self.readByte(address: mirrorDownAddress)
        case 0x4016:
            return self.joypad.readByte()
        default:
            return self.readByteWithoutMutating(address: address)
        }
    }

    mutating func writeByte(address: UInt16, byte: UInt8) {
        switch address {
        case Self.ramMirrorsBegin ... Self.ramMirrorsEnd:
            let vramAddress = Int(address & 0b0000_0111_1111_1111)
            self.vram[vramAddress] = byte
        case 0x2000:
            self.ppu.updateController(byte: byte)
        case 0x2001:
            self.ppu.updateMask(byte: byte)
        case 0x2003:
            self.ppu.updateOAMAddress(byte: byte)
        case 0x2004:
            self.ppu.writeOAMData(byte: byte)
        case 0x2005:
            self.ppu.writeScrollByte(byte: byte)
        case 0x2006:
            self.ppu.updateAddress(byte: byte)
        case 0x2007:
            self.ppu.writeByte(byte: byte)
        case 0x2008...Self.ppuRegistersMirrorsEnd:
            let mirrorDownAddr = address & 0b0010_0000_0000_0111
            self.writeByte(address: mirrorDownAddr, byte: byte)
        case 0x4014:
            var buffer: [UInt8] = [UInt8](repeating: 0, count: 256)
            let baseAddress: UInt16 = UInt16(byte) << 8

            for index in 0 ..< 256 {
                buffer[index] = self.readByte(address: baseAddress + UInt16(index))
            }
            self.ppu.writeOamBuffer(buffer: buffer)
        case 0x4016:
            self.joypad.writeByte(byte: byte)
        case 0x8000 ... 0xFFFF:
            fatalError("Attempt to write to cartridge ROM space")
        default:
            // TODO: Implement memory writing to these addresses?
            break
        }
    }
}

extension Bus {
    mutating func tick(cycles: Int) -> Bool {
        self.cycles += cycles

        return self.ppu.tick(cpuCycles: cycles)
    }

    mutating func pollNmiStatus() -> UInt8? {
        return self.ppu.pollNMIInterrupt()
    }
}
