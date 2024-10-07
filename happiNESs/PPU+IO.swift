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

        return result
    }

    mutating public func updateAddress(byte: UInt8) {
        if !self.wRegister {
            self.nextSharedAddress[.highByte] = byte
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

        if !nmiBefore && nmiAfter && self.statusRegister[.verticalBlankStarted] {
            self.nmiInterrupt = 1
        }

        let nametableBits = self.controllerRegister.rawValue & 0b0000_0011
        self.nextSharedAddress[.nametable] = nametableBits
    }

    mutating public func updateMask(byte: UInt8) {
        self.maskRegister.update(byte: byte)
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
        case (_, 0), (.horizontal, 1), (.vertical, 2):
            0
        case (.horizontal, 2), (.vertical, 1), (_, 3):
            0x0400
        default:
            fatalError("Invalid nametable index")
        }

        return actualNametableIndexStart + nameTableOffset
    }

    // NOTA BENE: This method is _only_ used internally by the PPU
    public func readByte(address: UInt16) -> (result: UInt8, shouldBuffer: Bool) {
        let mirroredAddress = address % 0x4000
        switch mirroredAddress {
        case 0x0000 ... 0x1FFF:
            return (self.cartridge!.readChr(address: mirroredAddress), true)
        case 0x2000 ... 0x3EFF:
            return (self.vram[self.vramIndex(from: mirroredAddress)], true)
        case 0x3F00 ... 0x3FFF:
            let basePaletteIndex = Int((mirroredAddress & 0xFF) % 0x20)
            switch basePaletteIndex {
            case 0x10, 0x14, 0x18, 0x1C:
                return (self.paletteTable[basePaletteIndex - 0x10], false)
            default:
                return (self.paletteTable[basePaletteIndex], false)
            }
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
            self.cartridge!.writeChr(address: address, byte: byte)
        case 0x2000 ... 0x3EFF:
            self.vram[self.vramIndex(from: address)] = byte
        case 0x3F00 ... 0x3FFF:
            // TODO: Make a helper function to resolve a palette index from an address
            let basePaletteIndex = Int((address & 0xFF) % 0x20)
            switch basePaletteIndex {
            case 0x10, 0x14, 0x18, 0x1C:
                self.paletteTable[basePaletteIndex - 0x10] = byte
            default:
                self.paletteTable[basePaletteIndex] = byte
            }
        default:
            let message = String(format: "Unexpected access to mirrored space: %04X", address)
            fatalError(message)
        }

        self.incrementVramAddress()
    }
}
