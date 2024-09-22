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

    public static let ppuAddressSpaceStart: UInt16 = 0x2000
    public static let nametableSize: Int = 0x0400
    public static let attributeTableOffset = 0x03C0

    public var cartridge: Cartridge?

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

    private var screenBuffer: [NESColor] = [NESColor](repeating: NESColor.black, count: Self.width * Self.height)
    private var spriteIndicesForCurrentScanline: ArraySlice<Int> = []

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

    mutating public func reset() {
        self.internalDataBuffer = 0x00
        self.vram = [UInt8](repeating: 0x00, count: 2048)
        self.paletteTable = [UInt8](repeating: 0x00, count: 32)

        self.addressRegister.reset()
        self.controllerRegister.reset()
        self.maskRegister.reset()
        self.oamRegister.reset()
        self.scrollRegister.reset()
        self.statusRegister.reset()

        self.cycles = 0
        self.scanline = 0
        self.nmiInterrupt = nil
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

    public func vramIndex(from address: UInt16) -> Int {
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

    // NOTA BENE: Called directly by the tracer, as well as by readByte()
    public func readByteWithoutMutating() -> (result: UInt8, newInternalDataBuffer: UInt8?) {
        let address = self.addressRegister.getAddress()

        switch address {
        case 0x0000 ... 0x1FFF:
            // TODO: Again... I'm concerned about the magnitude of `address` here and how large `chrRom` is
            return (self.internalDataBuffer, self.cartridge!.readChr(address: address))
        case 0x2000 ... 0x2FFF:
            // TODO: Same same concern as above
            return (internalDataBuffer, self.vram[self.vramIndex(from: address)])
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
        case 0x0000 ... 0x1FFF:
            self.cartridge!.writeChr(address: address, byte: byte)
        case 0x2000 ... 0x2FFF:
            self.vram[self.vramIndex(from: address)] = byte
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
    static public func makeEmptyScreenBuffer() -> [NESColor] {
        [NESColor](repeating: .black, count: Self.width * Self.height)
    }

    // We effectively are doing double buffering here to maximize performance.
    mutating public func updateScreenBuffer(_ otherBuffer: inout [NESColor]) {
        swap(&self.screenBuffer, &otherBuffer)
    }

    private func bytesForTileAt(bankIndex: Int, tileIndex: Int) -> ArraySlice<UInt8> {
        let startAddress = UInt16((bankIndex * 0x1000) + tileIndex * 16)
        return self.cartridge!.readTileFromChr(startAddress: startAddress)
    }

    mutating private func setColorAt(x: Int, y: Int, to color: NESColor) {
        self.screenBuffer[Self.width * y + x] = color
    }

    private func getColorFromPalette(baseIndex: Int, entryIndex: Int) -> NESColor? {
        guard entryIndex != 0 else {
            return nil
        }

        let paletteIndex = baseIndex + entryIndex
        return NESColor.systemPalette[Int(self.paletteTable[paletteIndex])]
    }

    private func getBackgroundPaletteColor(attributeTable: ArraySlice<UInt8>,
                                           colorIndex: Int,
                                           tileX: Int,
                                           tileY: Int) -> NESColor? {
        let attributeTableIndex = ((tileY / 4) * 8) + (tileX / 4)
        let attributeByte = attributeTable[attributeTable.startIndex + attributeTableIndex]

        let paletteIndexBase = switch ((tileX % 4) / 2, (tileY % 4) / 2) {
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

        return getColorFromPalette(baseIndex: Int((paletteIndexBase * 4)), entryIndex: colorIndex)
    }

    private func getBackgroundTileColor(x: Int, y: Int) -> NESColor? {
        let scrollX = Int(self.scrollRegister.scrollX)
        let scrollY = Int(self.scrollRegister.scrollY)

        let shiftX = x + scrollX
        let shiftY = y + scrollY

        let startAddressOffset: UInt16 = switch (shiftX < Self.width, shiftY < Self.height) {
        case (true, true):
            0x0000
        case (false, true):
            0x0400
        case (true, false):
            0x0800
        case (false, false):
            0x0C00
        }
        let startAddress = self.controllerRegister.nametableAddress() + startAddressOffset
        let startIndex = self.vramIndex(from: startAddress)
        let nametable = self.vram[startIndex ..< startIndex + 0x0400]

        let attributeTable = nametable[(nametable.startIndex + Self.attributeTableOffset)...]

        let nametableX = shiftX % Self.width
        let nametableY = shiftY % Self.height
        let nametableColumn = nametableX/8
        let nametableRow = nametableY/8
        let nametableIndex = 32 * nametableRow + nametableColumn
        let tileIndex = Int(nametable[nametable.startIndex + nametableIndex])

        let bankIndex = self.controllerRegister[.backgroundPatternBankIndex] ? 1 : 0

        let tilePixelX = nametableX % 8
        let tilePixelY = nametableY % 8

        let tileBytes = self.bytesForTileAt(bankIndex: bankIndex, tileIndex: tileIndex)
        let firstByte = tileBytes[tileBytes.startIndex + tilePixelY]
        let secondByte = tileBytes[tileBytes.startIndex + tilePixelY + 8]
        let bitMask: UInt8 = 0b1000_0000 >> tilePixelX
        let firstBit = firstByte & bitMask > 0 ? 0b01 : 0b00
        let secondBit = secondByte & bitMask > 0 ? 0b10 : 0b00
        let colorIndex = secondBit | firstBit

        return self.getBackgroundPaletteColor(attributeTable: attributeTable,
                                              colorIndex: colorIndex,
                                              tileX: nametableColumn,
                                              tileY: nametableRow)
    }

    private func getSpritePalette(paletteIndex: Int, colorIndex: Int) -> NESColor? {
        // NOTA BENE: The sprite palettes occupy the _upper_ 16 bytes
        // of the palette table, which is why the offset below is 0x10
        // and not 0x00.
        let paletteStartIndex = Int(0x10 + (paletteIndex * 4))
        return getColorFromPalette(baseIndex: paletteStartIndex, entryIndex: colorIndex)
    }

    private func getSpriteColor(backgroundPriority: Bool, x: Int, y: Int) -> NESColor? {
        for spriteIndex in self.spriteIndicesForCurrentScanline {
            // Determine if the sprite priority matches
            let tileAttributes = self.oamRegister.data[spriteIndex + 2]
            let spriteBackgroundPriority = tileAttributes >> 5 & 1 == 1
            if spriteBackgroundPriority != backgroundPriority {
                continue
            }

            // Determine if the (x, y) coordinates fall inside the sprite
            let tileX = Int(self.oamRegister.data[spriteIndex + 3])
            guard x >= tileX && x <= tileX + 7 else {
                continue
            }
            let tileY = Int(self.oamRegister.data[spriteIndex])

            let flipVertical = tileAttributes >> 7 & 1 == 1
            let flipHorizontal = tileAttributes >> 6 & 1 == 1
            let paletteIndex = Int(tileAttributes & 0b11)

            let bankIndex = self.controllerRegister[.spritePatternBankIndex] ? 1 : 0
            let tileIndex = Int(self.oamRegister.data[spriteIndex + 1])

            let deltaX = x - tileX
            let deltaY = y - tileY
            guard deltaX >= 0 && deltaY >= 0 else {
                // Sprite is at least partially off screen
                continue
            }

            let (tilePixelX, tilePixelY) = switch (flipHorizontal, flipVertical) {
            case (false, false):
                (deltaX % 8, deltaY % 8)
            case (true, false):
                (7 - deltaX % 8, deltaY % 8)
            case (false, true):
                (deltaX % 8, 7 - deltaY % 8)
            case (true, true):
                (7 - deltaX % 8, 7 - deltaY % 8)
            }

            let tileBytes = self.bytesForTileAt(bankIndex: bankIndex, tileIndex: tileIndex)
            let firstByte = tileBytes[tileBytes.startIndex + tilePixelY]
            let secondByte = tileBytes[tileBytes.startIndex + tilePixelY + 8]
            let bitMask: UInt8 = 0b1000_0000 >> tilePixelX
            let firstBit = firstByte & bitMask > 0 ? 0b01 : 0b00
            let secondBit = secondByte & bitMask > 0 ? 0b10 : 0b00
            let colorIndex = secondBit | firstBit

            guard let spriteColor = self.getSpritePalette(paletteIndex: paletteIndex, colorIndex: colorIndex) else {
                continue
            }

            return spriteColor
        }

        return nil
    }

    private func computeColorAt(x: Int, y: Int) -> NESColor {
        if let color = self.getSpriteColor(backgroundPriority: false, x: x, y: y) {
            return color
        }

        if let color = self.getBackgroundTileColor(x: x, y: y) {
            return color
        }

        if let color = self.getSpriteColor(backgroundPriority: true, x: x, y: y) {
            return color
        }

        return NESColor.systemPalette[Int(self.paletteTable[0])]
    }

    mutating private func renderPixel(x: Int, y: Int) {
        let color = self.computeColorAt(x: x, y: y)
        setColorAt(x: x, y: y, to: color)
    }

    // This is partly a performance optimization and partly an emulation
    // of what happens in the NES, whereby we cache the first eight sprites
    // that lie on the current scanline.
    mutating private func cacheSpriteIndices() {
        let allSpriteIndices = stride(from: 0, to: self.oamRegister.data.count, by: 4)
        self.spriteIndicesForCurrentScanline = allSpriteIndices.filter({
            oamIndex in
                // Cache only the sprites residing on this scanline
                let tileY = Int(self.oamRegister.data[oamIndex])
                if self.scanline >= tileY && self.scanline <= tileY + 7 {
                    return true
                }

                return false
        }).prefix(8)
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
        var redrawScreen = false
        if self.cycles == 0 {
            self.cacheSpriteIndices()
        }

        for _ in 0 ..< cpuCycles * 3 {
            if self.cycles < Self.width && self.scanline < Self.height {
                self.renderPixel(x: self.cycles, y: Int(self.scanline))
            }

            self.cycles += 1

            if self.cycles >= Self.ppuCyclesPerScanline {
                if self.isSpriteZeroHit(cycles: self.cycles) {
                    self.statusRegister[.spriteZeroHit] = true
                }

                self.cycles = 0
                self.scanline += 1
                self.cacheSpriteIndices()

                if self.scanline == Self.nmiInterruptScanline {
                    self.statusRegister[.verticalBlankStarted] = true
                    self.statusRegister[.spriteZeroHit] = false

                    if self.controllerRegister[.generateNmi] {
                        self.nmiInterrupt = 1
                    }

                    redrawScreen = true
                }

                if self.scanline >= Self.scanlinesPerFrame {
                    self.scanline = 0
                    self.nmiInterrupt = nil
                    self.statusRegister[.verticalBlankStarted] = false
                    self.statusRegister[.spriteZeroHit] = false
                }
            }
        }

        return redrawScreen
    }
}

extension PPU {
    public func dump() {
        print("cycles: \(cycles), scanline: \(scanline)")
        dumpSprites()
        dumpNametable(vram.prefix(2048), labeled: "A")
        dumpNametable(vram.suffix(2048), labeled: "B")
    }

    func dumpSprites() {
        print("sprites: ")
        for oamDataIndex in stride(from: 0, to: self.oamRegister.data.count, by: 4).reversed() {
            let tileY = Int(self.oamRegister.data[oamDataIndex])
            let tileIndex = Int(self.oamRegister.data[oamDataIndex + 1])
            let tileAttributes = self.oamRegister.data[oamDataIndex + 2]
            let tileX = Int(self.oamRegister.data[oamDataIndex + 3])

            let flipVertical = tileAttributes >> 7 & 1 == 1
            let flipHorizontal = tileAttributes >> 6 & 1 == 1
            let paletteIndex = Int(tileAttributes & 0b11)

            print("- \(oamDataIndex / 4):", tileIndex, "@ \(tileX),\(tileY)",
                  (flipVertical ? "vflip" : ""), (flipHorizontal ? "hflip" : ""),
                  "colored", paletteIndex)
        }
    }

    func dumpNametable(_ nametable: ArraySlice<UInt8>, labeled: String) {
        print("nametable \(labeled):")

        for row in 0..<30 {
            print("- tiles: ", terminator: "")
            for column in 0..<32 {
                let i = column + row * 32
                let tileIndex = Int(nametable[i])
                print(String(format: "%2x", tileIndex), terminator: " ")
            }
            print()
        }

        for row in 0..<15 {
            print("- attrs: ", terminator: "")
            for column in 0..<16 {
                let i = column + row * 16
                let attrs = Int(nametable[i])
                let topLeft = attrs & 0b11
                let topRight = attrs & 0b1100 >> 2
                print(String(format: "%2x", topLeft), terminator: " ")
                print(String(format: "%2x", topRight), terminator: " ")
            }
            print()

            print("         ", terminator: "")
            for column in 0..<16 {
                let i = column + row * 16
                let attrs = Int(nametable[i])
                let botLeft = attrs & 0b110000 >> 4
                let botRight = attrs & 0b11000000 >> 6
                print(String(format: "%2x", botLeft), terminator: " ")
                print(String(format: "%2x", botRight), terminator: " ")
            }
            print()
        }
    }
}
