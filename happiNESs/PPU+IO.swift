//
//  PPU+IO.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/6/24.
//

extension PPU {
    // NOTA BENE: Called directly by the tracer, as well as by readStatus()
    public func readStatusWithoutMutating() -> UInt8 {
        self.statusRegister.rawValue
    }

    mutating public func readStatus() -> UInt8 {
        let result = self.readStatusWithoutMutating()
        self.statusRegister[.verticalBlankStarted] = false
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

    mutating public func updateAddress(byte: UInt8) {
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

    mutating public func updateController(byte: UInt8) {
        let nmiBefore = self.controllerRegister[.generateNmi]
        self.controllerRegister.update(byte: byte)
        let nmiAfter = self.controllerRegister[.generateNmi]

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
            if !nmiBefore && nmiAfter && self.statusRegister[.verticalBlankStarted] {
                self.nmiDelayState.scheduleNmi()
            }
        }

        let nametableBits = self.controllerRegister.rawValue & 0b0000_0011
        self.nextSharedAddress[.nametable] = nametableBits
    }

    mutating public func updateMask(byte: UInt8) {
        let showBitsBefore = (self.maskRegister[.showBackground], self.maskRegister[.showSprites])
        self.maskRegister.update(byte: byte)
        let showBitsAfter = (self.maskRegister[.showBackground], self.maskRegister[.showSprites])

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

    mutating public func updateOAMAddress(byte: UInt8) {
        self.oamRegister.updateAddress(byte: byte)
    }

    public func readOAMData() -> UInt8 {
        self.oamRegister.readByte()
    }

    mutating public func writeOAMData(byte: UInt8) {
        self.oamRegister.writeByte(byte: byte)
    }

    mutating public func writeOamBuffer(buffer: [UInt8]) {
        for byte in buffer {
            self.oamRegister.writeByte(byte: byte)
        }
    }

    mutating public func writeScrollByte(byte: UInt8) {
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
        let increment = self.controllerRegister.vramAddressIncrement()
        self.currentSharedAddress = (self.currentSharedAddress &+ UInt16(increment)) & 0x3FFF
    }

    private func vramIndex(from address: UInt16) -> Int {
        // Mirror down 0x3000-0x3EFF to 0x2000-0x2EFF
        let mirroredVramAddress = address & 0b0010_1111_1111_1111

        let addressOffset = Int(mirroredVramAddress - Self.ppuAddressSpaceStart)
        let nameTableIndex = addressOffset / Self.nametableSize
        let nameTableOffset = addressOffset % Self.nametableSize

        // The actual "physical" layout of the nametables in the PPU VRAM is
        // the following:
        //
        //     [ A ] [ B ]
        //
        // where A is the primary nametable and B is the secondary nametable,
        // each with 32 x 30 = 960 bytes. (The next 64 bytes for each is reserved
        // for the pattern tables.)
        //
        // However, the way PPU memory addresses map to the nametables depends on
        // the mirroring strategy hardcoded into the ROM, and thus set in the PPU.
        // In PPU address space, there are virtually _four_ nametables, two of which
        // are mirrors of the other two:
        //
        //     [ 0 ] [ 1 ]
        //     [ 2 ] [ 3 ]
        //
        // And so, we need to map the requested memory address to the correct index
        // of the PPU VRAM array. For vertical mirroring, virtual nametable indices 0 and 2
        // need to map to actual nametable A, whereas indices 1 and 3 need to map to
        // B:
        //
        //     [ A ] [ B ]
        //     [ A ] [ B ]
        //
        // For horizontal mirroring, virtual nametable indices 0 and 1 need to map to
        // actual nametable A, whereas indices 2 and 3 need to map to B:
        //
        //     [ A ] [ A ]
        //     [ B ] [ B ]
        //
        // And so, the `let` statement below maps the tuple of mirroring strategy
        // and virtual nametable index to the beginning "physical" nametable address.
        // From there, we can add the nametable offset to get the actual address.
        // (For now, this emulator only handles vertical and horizontal mirroring.)
        let actualNametableIndexStart = switch (self.cartridge!.mirroring, nameTableIndex) {
        case (_, 0), (.horizontal, 1), (.vertical, 2), (.singleScreen0, _):
            0x0000
        case (.horizontal, 2), (.vertical, 1), (_, 3), (.singleScreen1, _):
            0x0400
        default:
            fatalError("Invalid nametable index")
        }

        return actualNametableIndexStart + nameTableOffset
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
    public func readByte(address: UInt16) -> (result: UInt8, shouldBuffer: Bool) {
        let mirroredAddress = address % 0x4000
        switch mirroredAddress {
        case 0x0000 ... 0x1FFF:
            return (self.cartridge!.readByte(address: mirroredAddress), true)
        case 0x2000 ... 0x3EFF:
            return (self.vram[self.vramIndex(from: mirroredAddress)], true)
        case 0x3F00 ... 0x3FFF:
            return (self.paletteTable[self.paletteIndex(from: mirroredAddress)], false)
        default:
            let message = String(format: "Unexpected access to mirrored space %04X", address)
            fatalError(message)
        }
    }

    // NOTA BENE: Called directly by the tracer, as well as by readByte()
    public func readByteWithoutMutating() -> (result: UInt8, newInternalDataBuffer: UInt8?) {
        let address = self.currentSharedAddress

        let (result, shouldBuffer) = self.readByte(address: address)
        if shouldBuffer {
            return (self.internalDataBuffer, result)
        }

        return (result, nil)
    }

    mutating public func readByte() -> UInt8 {
        let (result, newInternalDataBuffer) = self.readByteWithoutMutating()

        self.incrementVramAddress()
        if let newInternalDataBuffer {
            self.internalDataBuffer = newInternalDataBuffer
        }

        return result
    }

    mutating public func writeByte(byte: UInt8) {
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
}
