//
//  PPU+IO.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/6/24.
//

extension PPU {
    // NOTA BENE: Called directly by the tracer, as well as by readStatus()
    public func readPpuStatusWithoutMutating() -> UInt8 {
        self.status
    }

    mutating private func readPpuStatus() -> UInt8 {
        let result = self.readPpuStatusWithoutMutating()
        self.status[.verticalBlankStarted] = false
        self.wRegister = false

        // ACHTUNG! This implementation is taken from a thread on the NESDev forums
        // on the topic of suppression of VBL under certain circumstances:
        //
        //     https://forums.nesdev.org/viewtopic.php?p=120121
        if self.isNmiScanline && self.cycles == 1 {
            self.suppressVerticalBlank = true
        }

        // NOTA BENE: This is Yet Another Hack, this time taken from another NES
        // emulator, and which allows for blargg's 06-suppression test to pass:
        //
        //     https://github.com/donqustix/emunes/blob/master/src/nes/emulator/ppu.h#L204
        if self.isNmiScanline && (self.cycles >= 1 && self.cycles <= 3) {
            self.nmiDelayState = .canceled
        }

        return result
    }

    mutating private func writePpuAddress(byte: UInt8) {
        if !self.wRegister {
            // ACHTUNG! Per the following excerpt in the NESDev wiki for PPUADDR, we
            // need to _explicitly_ reset bit 14 here:
            //
            //     "However, bit 14 of the internal t register that holds the data written
            //     to PPUADDR is forced to 0 when writing the PPUADDR high byte"
            //
            //     https://www.nesdev.org/wiki/PPU_registers#PPUADDR_-_VRAM_address_($2006_write)
            self.nextSharedAddress[.highByte] = byte
            self.nextSharedAddress[.bit14] = 0
        } else {
            self.nextSharedAddress[.lowByte] = byte
            self.currentSharedAddress = self.nextSharedAddress
        }

        self.wRegister.toggle()
    }

    mutating private func writePpuControl(byte: UInt8) {
        let nmiBefore = self.control[.generateNmi]
        self.control = byte
        let nmiAfter = self.control[.generateNmi]

        switch (self.scanline, self.cycles) {
        case (Self.nmiInterruptScanline, 1...3):
            // NOTA BENE: This is a hack to get the last pesky test ROM to pass,
            // namely 08-nmi_timing_off, to pass. Inspired by code that I saw from
            // a Rust NES implementation:
            //
            //     https://github.com/razielgn/nes/blob/master/src/nes/ppu.rs#L697
            if self.isNmiScanline && (self.cycles >= 1 && self.cycles <= 3) {
                if nmiBefore && !nmiAfter {
                    self.nmiDelayState = .canceled
                }
            }
        case (Self.scanlinesPerFrame, 1):
            // NOTA BENE: This is another thing that I gleaned from another NES emulator,
            // to suppress queueing up an NMI if we're at the scanline & cycle at which
            // VBL is cleared.
            //
            //     https://github.com/donqustix/emunes/blob/master/src/nes/emulator/ppu.h#L143
            break
        default:
            // NOTA BENE: Per what is stated in this section on the NESDev wiki,
            // if the NMI enabled flag is toggled when VBL is set, then we need to
            // generate an NMI interrupt.
            //
            //     https://www.nesdev.org/wiki/NMI#Operation
            if !nmiBefore && nmiAfter && self.status[.verticalBlankStarted] {
                self.nmiDelayState.scheduleNmi()
            }
        }

        let nametableBits = self.control & 0b0000_0011
        self.nextSharedAddress[.nametable] = nametableBits
    }

    mutating private func writePpuMask(byte: UInt8) {
        let showBitsBefore = (self.mask[.showBackground], self.mask[.showSprites])
        self.mask = byte
        let showBitsAfter = (self.mask[.showBackground], self.mask[.showSprites])

        // ACHTUNG! This is yet another apparent hack discovered in the thread
        // below which gets the tenth of blargg's PPU test ROMs to pass. I could
        // not find any detailed explanation or theory behind this... but it does
        // indeed work.
        //
        //     https://forums.nesdev.org/viewtopic.php?p=208409#p208409
        if showBitsAfter != showBitsBefore {
            if self.isPreRenderLine && self.isJustBeforeLastCycle && self.isOddFrame {
                self.cycles = self.isRenderingEnabled ? 338 : 340
            }
        }
    }

    mutating private func writeOamAddress(byte: UInt8) {
        self.oamRegister.updateAddress(byte: byte)
    }

    private func readOamData() -> UInt8 {
        self.oamRegister.readByte()
    }

    mutating private func writeOamData(byte: UInt8) {
        self.oamRegister.writeByte(byte: byte)
    }

    mutating public func writeOamDma(buffer: [UInt8]) {
        for byte in buffer {
            self.oamRegister.writeByte(byte: byte)
        }
    }

    mutating private func writePpuScroll(byte: UInt8) {
        let coarseBits = byte >> 3
        let fineBits = byte & 0b0000_0111
        if !self.wRegister {
            self.nextSharedAddress[.coarseX] = coarseBits
            self.currentFineX = fineBits
        } else {
            self.nextSharedAddress[.coarseY] = coarseBits
            self.nextSharedAddress[.fineY] = fineBits
        }

        self.wRegister.toggle()
    }

    mutating private func incrementVramAddress() {
        let increment = self.control[.vramAddressIncrement] ? 32 : 1
        self.currentSharedAddress = (self.currentSharedAddress &+ UInt16(increment)) & 0x3FFF
    }

    private func vramIndex(from address: UInt16) -> Int {
        // Mirror down 0x3000-0x3EFF to 0x2000-0x2EFF
        let addressOffset = Int(address - Self.ppuAddressSpaceStart) % 0x1000
        let inboundNametableIndex = addressOffset / Self.nametableSize
        let nametableOffset = addressOffset % Self.nametableSize
        let actualNametable = self.cartridge!.mirroring.actualNametable(for: inboundNametableIndex)
        return actualNametable.rawValue + nametableOffset
    }

    private func paletteIndex(from address: Address) -> Int {
        // The palette table is mapped to addresses in the following manner:
        //
        // +-----------------+--------------------------------------+
        // | 0x3F00          | Universal background color           |
        // +-----------------+--------------------------------------+
        // | 0x3F01 – 0x3F03 | Background palette 0                 |
        // +-----------------+--------------------------------------+
        // | 0x3F04          | Unused color 1                       |
        // +-----------------+--------------------------------------+
        // | 0x3F05 – 0x3F07 | Background palette 1                 |
        // +-----------------+--------------------------------------+
        // | 0x3F08          | Unused color 2                       |
        // +-----------------+--------------------------------------+
        // | 0x3F09 – 0x3F0B | Background palette 2                 |
        // +-----------------+--------------------------------------+
        // | 0x3F0C          | Unused color 3                       |
        // +-----------------+--------------------------------------+
        // | 0x3F0D – 0x3F0F | Background palette 3                 |
        // +-----------------+--------------------------------------+
        // | 0x3F10          | Mirror of universal background color |
        // +-----------------+--------------------------------------+
        // | 0x3F11 – 0x3F13 | Sprite palette 0                     |
        // +-----------------+--------------------------------------+
        // | 0x3F14          | Mirror of unused color 1             |
        // +-----------------+--------------------------------------+
        // | 0x3F15 – 0x3F17 | Sprite palette 1                     |
        // +-----------------+--------------------------------------+
        // | 0x3F18          | Mirror of unused color 2             |
        // +-----------------+--------------------------------------+
        // | 0x3F19 – 0x3F1B | Sprite palette 2                     |
        // +-----------------+--------------------------------------+
        // | 0x3F1C          | Mirror of unused color 3             |
        // +-----------------+--------------------------------------+
        // | 0x3F1D – 0x3F1F | Sprite palette 3                     |
        // +-----------------+--------------------------------------+
        // | 0x3F20 – 0x3FFF | Mirrors of first 32 bytes            |
        // +-----------------+--------------------------------------+
        let basePaletteIndex = Int((address & 0xFF) % 0x20)

        return switch basePaletteIndex {
        case 0x10, 0x14, 0x18, 0x1C:
            basePaletteIndex - 0x10
        default:
            basePaletteIndex
        }
    }

    // NOTA BENE: This method is _only_ used internally by the PPU
    public func readByteInternal(address: UInt16) -> UInt8 {
        let mirroredAddress = address % 0x4000
        switch mirroredAddress {
        case 0x0000 ... 0x1FFF:
            return self.cartridge!.readByte(address: mirroredAddress)
        case 0x2000 ... 0x3EFF:
            return self.vram[self.vramIndex(from: mirroredAddress)]
        case 0x3F00 ... 0x3FFF:
            return self.paletteTable[self.paletteIndex(from: mirroredAddress)]
        default:
            let message = String(format: "Unexpected access to mirrored space %04X", address)
            fatalError(message)
        }
    }

    // NOTA BENE: Called indirectly by the tracer
    public func readPpuDataWithoutMutating() -> UInt8 {
        let address = self.currentSharedAddress
        let mirroredAddress = address % 0x4000

        switch mirroredAddress {
        case 0x0000 ... 0x3EFF:
            return self.internalDataBuffer
        case 0x3F00 ... 0x3FFF:
            return self.readByteInternal(address: mirroredAddress)
        default:
            fatalError("We should never get here")
        }
    }

    mutating private func readPpuData() -> UInt8 {
        let address = self.currentSharedAddress
        let byte = self.readByteInternal(address: address)

        self.incrementVramAddress()

        let mirroredAddress = address % 0x4000
        switch mirroredAddress {
        case 0x0000 ... 0x3EFF:
            let bufferedByte = self.internalDataBuffer
            self.internalDataBuffer = byte
            return bufferedByte
        case 0x3F00 ... 0x3FFF:
            let otherByte = self.readByteInternal(address: mirroredAddress - 0x1000)
            self.internalDataBuffer = otherByte
            return byte
        default:
            fatalError("We should never get here")
        }
    }

    mutating private func writePpuData(byte: UInt8) {
        let address = self.currentSharedAddress % 0x4000

        switch address {
        case 0x0000 ... 0x1FFF:
            self.cartridge!.writeByte(address: address, byte: byte)
        case 0x2000 ... 0x3EFF:
            self.vram[self.vramIndex(from: address)] = byte
        case 0x3F00 ... 0x3FFF:
            self.paletteTable[self.paletteIndex(from: address)] = byte
        default:
            let message = String(format: "Unexpected access to mirrored space: %04X", address)
            fatalError(message)
        }

        self.incrementVramAddress()
    }

    // NOTA BENE: This method is called externally from the Bus
    mutating public func readByteWithoutMutating(address: Address) -> UInt8 {
        let mirroredAddress = address & 0b0010_0000_0000_0111

        switch mirroredAddress {
        case 0x2000, 0x2001, 0x2003, 0x2005, 0x2006:
            // Reads from these addresses should not happen as they are write-only,
            // but we return 0x00 nonetheless.
            return 0x00
        case 0x2002:
            return self.readPpuStatusWithoutMutating()
        case 0x2004:
            return self.readOamData()
        case 0x2007:
            return self.readPpuDataWithoutMutating()
        default:
            fatalError("We should not have gotten here in PPU.readByteWithoutMutating()")
        }
    }

    // NOTA BENE: This method is called externally from the Bus
    mutating public func readByte(address: Address) -> UInt8 {
        let mirroredAddress = address & 0b0010_0000_0000_0111

        switch mirroredAddress {
        case 0x2000, 0x2001, 0x2003, 0x2005, 0x2006:
            // Reads from these addresses should not happen as they are write-only,
            // but we return 0x00 nonetheless.
            return 0x00
        case 0x2002:
            return self.readPpuStatus()
        case 0x2004:
            return self.readOamData()
        case 0x2007:
            return self.readPpuData()
        default:
            fatalError("We should not have gotten here in PPU.readByte()")
        }
    }

    // NOTA BENE: This method is called externally from the Bus
    mutating public func writeByte(address: Address, byte: UInt8) {
        let mirrorDownAddr = address & 0b0010_0000_0000_0111

        switch mirrorDownAddr {
        case 0x2000:
            self.writePpuControl(byte: byte)
        case 0x2001:
            self.writePpuMask(byte: byte)
        case 0x2003:
            self.writeOamAddress(byte: byte)
        case 0x2004:
            self.writeOamData(byte: byte)
        case 0x2005:
            self.writePpuScroll(byte: byte)
        case 0x2006:
            self.writePpuAddress(byte: byte)
        case 0x2007:
            self.writePpuData(byte: byte)
        default:
            break
        }
    }
}
