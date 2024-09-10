//
//  PPU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/6/24.
//

public struct PPU {
    public static let width = 256
    public static let height = 240

    public static let scanlinesPerFrame = 262
    public static let ppuCyclesPerScanline = 341
    public static let nmiInterruptScanline = 241

    public static let attributeTableOffset = 0x03C0

    public var chrRom: [UInt8]?
    public var mirroring: Mirroring?

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
    public var paletteTable: [UInt8]
    public var vram: [UInt8]
    public var internalDataBuffer: UInt8

    public var addressRegister: AddressRegister
    public var controllerRegister: ControllerRegister
    public var maskRegister: MaskRegister
    public var oamRegister: OAMRegister
    public var scrollRegister: ScrollRegister
    public var statusRegister: PPUStatusRegister

    public var cycles: Int
    public var scanline: UInt16
    public var nmiInterrupt: UInt8?

    public init() {
        self.internalDataBuffer = 0x00
        self.vram = [UInt8](repeating: 0x00, count: 2048)
        self.paletteTable = [UInt8](repeating: 0x00, count: 32)
        self.addressRegister = AddressRegister()
        self.controllerRegister = ControllerRegister()
        self.maskRegister = MaskRegister()
        self.oamRegister = OAMRegister()
        self.scrollRegister = ScrollRegister()
        self.statusRegister = PPUStatusRegister()

        self.cycles = 0
        self.scanline = 0
        self.nmiInterrupt = nil
    }

    mutating public func loadRom(chrRom: [UInt8], mirroring: Mirroring) {
        self.chrRom = chrRom
        self.mirroring = mirroring
    }
}

extension PPU {
    // NOTA BENE: Called directly by the tracer, as well as by readStatus()
    public func readStatusWithoutMutating() -> UInt8 {
        self.statusRegister.rawValue
    }

    mutating public func readStatus() -> UInt8 {
        let result = self.readStatusWithoutMutating()
        self.statusRegister[.verticalBlankStarted] = false
        self.addressRegister.resetLatch()
        self.scrollRegister.resetLatch()

        return result
    }

    mutating public func updateAddress(byte: UInt8) {
        self.addressRegister.updateAddress(byte: byte)
    }

    mutating public func updateController(byte: UInt8) {
        let nmiBefore = self.controllerRegister[.generateNmi]
        self.controllerRegister.update(byte: byte)
        let nmiAfter = self.controllerRegister[.generateNmi]

        if !nmiBefore && nmiAfter && self.statusRegister[.verticalBlankStarted] {
            self.nmiInterrupt = 1
        }
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
        self.scrollRegister.writeByte(byte: byte)
    }
}

extension PPU {
    mutating public func incrementVramAddress() {
        let increment = self.controllerRegister.vramAddressIncrement()
        self.addressRegister.incrementAddress(value: increment)
    }

    // Horizontal:
    //   [ A ] [ a ]
    //   [ B ] [ b ]

    // Vertical:
    //   [ A ] [ B ]
    //   [ a ] [ b ]
    public func mirrorVramAddress(address: UInt16) -> UInt16 {
        // Mirror down 0x3000-0x3EFF to 0x2000-0x2EFF
        let mirroredVram = address & 0b0010_1111_1111_1111

        // To VRAM vector
        let vramIndex = mirroredVram - 0x2000

        // To the name table index
        let nameTable = vramIndex / 0x0400

        return switch (self.mirroring!, nameTable) {
        case (Mirroring.vertical, 2), (Mirroring.vertical, 3):
            vramIndex - 0x0800
        case (Mirroring.horizontal, 2):
            vramIndex - 0x0400
        case (Mirroring.horizontal, 1):
            vramIndex - 0x0400
        case (Mirroring.horizontal, 3):
            vramIndex - 0x0800
        default:
            vramIndex
        }
    }

    // NOTA BENE: Called directly by the tracer, as well as by readByte()
    public func readByteWithoutMutating() -> (result: UInt8, newInternalDataBuffer: UInt8?) {
        let address = self.addressRegister.getAddress()

        switch address {
        case 0 ... 0x1FFF:
            // TODO: Again... I'm concerned about the magnitude of `address` here and how large `chrRom` is
            return (self.internalDataBuffer, self.chrRom![Int(address)])
        case 0x2000 ... 0x2FFF:
            // TODO: Same same concern as above
            return (internalDataBuffer, self.vram[Int(self.mirrorVramAddress(address: address))])
        case 0x3000 ... 0x3EFF:
            let message = String(format: "address space 0x3000..0x3eff is not expected to be used, requested = %04X", address)
            fatalError(message)
        case 0x3F00 ... 0x3FFF:
            let basePaletteIndex = Int((address & 0xFF) % 0x20)
            switch basePaletteIndex {
            case 0x10, 0x14, 0x18, 0x1C:
                return (self.paletteTable[basePaletteIndex - 0x10], nil)
            default:
                return (self.paletteTable[basePaletteIndex], nil)
            }
        default:
            let message = String(format: "Unexpected access to mirrored space %04X", address)
            fatalError(message)
        }
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
        let address = self.addressRegister.getAddress()

        switch address {
        case 0 ... 0x1FFF:
            let message = String(format: "Attempt to write to chr rom space: %04X", address)
            print(message)
        case 0x2000 ... 0x2FFF:
            self.vram[Int(self.mirrorVramAddress(address: address))] = byte
        case 0x3000 ... 0x3EFF:
            let message = String(format: "Address shouldn't be used in reality: %04X", address)
            fatalError(message)
        case 0x3F00 ... 0x3FFF:
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

extension PPU {
    mutating func pollNMIInterrupt() -> UInt8? {
        let result = self.nmiInterrupt
        self.nmiInterrupt = nil
        return result
    }

    mutating func isSpriteZeroHit(cycles: Int) -> Bool {
        let y = self.oamRegister.data[0]
        let x = self.oamRegister.data[3]
        return (y == self.scanline) && x <= cycles && self.maskRegister[.showSprites]
    }

    // The return value below ultimately reflects whether or not
    // we need to redraw the screen.
    mutating func tick(cpuCycles: Int) -> Bool {
        self.cycles += cpuCycles * 3

        if self.cycles >= Self.ppuCyclesPerScanline {
            if self.isSpriteZeroHit(cycles: self.cycles) {
                self.statusRegister[.spriteZeroHit] = true
            }

            self.cycles -= Self.ppuCyclesPerScanline
            self.scanline += 1

            if self.scanline == Self.nmiInterruptScanline {
                self.statusRegister[.verticalBlankStarted] = true
                self.statusRegister[.spriteZeroHit] = false

                if self.controllerRegister[.generateNmi] {
                    self.nmiInterrupt = 1
                }
            }

            if self.scanline >= Self.scanlinesPerFrame {
                self.scanline = 0
                self.nmiInterrupt = nil
                self.statusRegister[.verticalBlankStarted] = false
                self.statusRegister[.spriteZeroHit] = false

                return true
            }
        }

        return false
    }
}

extension PPU {
    private func bytesForTileAt(bankIndex: Int, tileIndex: Int) -> ArraySlice<UInt8> {
        let startIndex = (bankIndex * 0x1000) + tileIndex * 16
        return self.chrRom![startIndex ..< startIndex + 16]
    }

    private func getBackgroundPalette(tileX: Int, tileY: Int) -> [NESColor] {
        let attributeTableIndex = ((tileY / 4) * 8) + (tileX / 4)
        let attributeByte = self.vram[Self.attributeTableOffset + attributeTableIndex]

        let paletteIndex = switch ((tileX % 4) / 2, (tileY % 4) / 2) {
        case (0, 0):
            attributeByte & 0b0000_0011
        case (1, 0):
            (attributeByte >> 2) & 0b0000_0011
        case (0, 1):
            (attributeByte >> 4) & 0b0000_0011
        case (1, 1):
            (attributeByte >> 6) & 0b0000_0011
        default:
            fatalError("Whoops! We should never get here!")
        }

        let paletteStartIndex = Int((paletteIndex * 4) + 1)
        return [
            0,
            paletteStartIndex,
            paletteStartIndex + 1,
            paletteStartIndex + 2,
        ].map { index in
            NESColor.systemPalette[Int(self.paletteTable[index])]
        }
    }

    private func drawBackgroundTile(to screenBuffer: inout [NESColor],
                          bankIndex: Int,
                          tileIndex: Int,
                          tileX: Int,
                          tileY: Int) {
        let tileBytes = bytesForTileAt(bankIndex: bankIndex, tileIndex: tileIndex)
        let backgroundPalette = self.getBackgroundPalette(tileX: tileX, tileY: tileY)

        for (y, var (firstByte, secondByte)) in zip(tileBytes.prefix(8), tileBytes.suffix(8)).enumerated() {
            for x in (0 ... 7).reversed() {
                let backgroundColorIndex = Int((secondByte & 0x01) << 1 | (firstByte & 0x01))
                firstByte >>= 1
                secondByte >>= 1

                let backgroundColor = backgroundPalette[backgroundColorIndex]
                screenBuffer[Self.width * (tileY * 8 + y) + (tileX * 8 + x)] = backgroundColor
            }
        }
    }

    public func drawBackground(to screenBuffer: inout [NESColor]) {
        let bankIndex = self.controllerRegister[.backgroundPatternBankIndex] ? 1 : 0
        for i in 0 ..< Self.attributeTableOffset {
            let tileIndex = Int(self.vram[i])
            let tileX = (i % 32)
            let tileY = (i / 32)

            self.drawBackgroundTile(to: &screenBuffer, bankIndex: bankIndex, tileIndex: tileIndex, tileX: tileX, tileY: tileY)
        }
    }

    private func getSpritePalette(paletteIndex: Int) -> [NESColor] {
        // NOTA BENE: The sprite palettes occupy the _upper_ 16 bytes
        // of the palette table, which is why the offset below is 0x11
        // and not 0x01.
        let paletteStartIndex = Int(0x11 + (paletteIndex * 4))
        return [
            0,
            paletteStartIndex,
            paletteStartIndex + 1,
            paletteStartIndex + 2,
        ].map { index in
            NESColor.systemPalette[Int(self.paletteTable[index])]
        }
    }

    private func drawSprites(to screenBuffer: inout [NESColor]) {
        for oamDataIndex in stride(from: 0, to: self.oamRegister.data.count, by: 4).reversed() {
            let tileY = Int(self.oamRegister.data[oamDataIndex])
            let tileIndex = Int(self.oamRegister.data[oamDataIndex + 1])
            let tileAttributes = self.oamRegister.data[oamDataIndex + 2]
            let tileX = Int(self.oamRegister.data[oamDataIndex + 3])

            let flipVertical = tileAttributes >> 7 & 1 == 1
            let flipHorizontal = tileAttributes >> 6 & 1 == 1
            let paletteIndex = Int(tileAttributes & 0b11)

            let spritePalette = self.getSpritePalette(paletteIndex: paletteIndex)
            let bankIndex = self.controllerRegister[.spritePatternBankIndex] ? 1 : 0
            let tileBytes = self.bytesForTileAt(bankIndex: bankIndex, tileIndex: tileIndex)

            for (y, var (firstByte, secondByte)) in zip(tileBytes.prefix(8), tileBytes.suffix(8)).enumerated() {
                for x in (0 ... 7).reversed() {
                    let spriteColorIndex = Int((secondByte & 0x01) << 1 | (firstByte & 0x01))
                    firstByte >>= 1
                    secondByte >>= 1

                    if spriteColorIndex == 0 {
                        // Transparent pixel!
                        continue
                    }

                    let spriteColor = spritePalette[spriteColorIndex]
                    let (screenX, screenY) = switch (flipHorizontal, flipVertical) {
                    case (false, false):
                        (tileX + x, tileY + y)
                    case (true, false):
                        (tileX + 7 - x, tileY + y)
                    case (false, true):
                        (tileX + x, tileY + 7 - y)
                    case (true, true):
                        (tileX + 7 - x, tileY + 7 - y)
                    }

                    let bufferIndex = Self.width * screenY + screenX
                    if screenX >= 0 && screenX < Self.width && screenY >= 0 && screenY < Self.height {
                        screenBuffer[bufferIndex] = spriteColor
                    }
                }
            }
        }
    }

    // We pass screenBuffer as a mutable parameter to avoid copying
    // and to maximize performance.
    public func updateScreenBuffer(_ screenBuffer: inout [NESColor]) {
        self.drawBackground(to: &screenBuffer)
        self.drawSprites(to: &screenBuffer)
    }

    static public func makeEmptyScreenBuffer() -> [NESColor] {
        [NESColor](repeating: .black, count: Self.width * Self.height)
    }
}
