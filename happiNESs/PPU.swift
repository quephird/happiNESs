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

    public var controllerRegister: ControllerRegister
    public var maskRegister: MaskRegister
    public var oamRegister: OAMRegister
    public var statusRegister: PPUStatusRegister

    // ACHTUNG! This field is shared between rendering and PPUADDR/PPUDATA when not rendering
    private var nextSharedAddress: Address = 0
    private var currentSharedAddress: Address = 0
    private var ppuaddr: UInt8 = 0x00
    private var ppuscroll: UInt8 = 0x00
    // This register is also shared by PPUADDR/PPUSCROLL
    private var wRegister: Bool = false

    public var cycles: Int
    public var scanline: UInt16
    public var nmiInterrupt: UInt8?

    private var screenBuffer: [NESColor] = [NESColor](repeating: NESColor.black, count: Self.width * Self.height)
    private var spriteIndicesForCurrentScanline: ArraySlice<Int> = []

    private var currentNametableByte: UInt8 = 0
    private var currentPaletteIndex: UInt8 = 0
    private var currentLowTileByte: UInt8 = 0
    private var currentHighTileByte: UInt8 = 0
    private var currentAndNextTileData: UInt64 = 0
    private var currentFineX: UInt8 = 0

    public init() {
        self.internalDataBuffer = 0x00
        self.vram = [UInt8](repeating: 0x00, count: 2048)
        self.paletteTable = [UInt8](repeating: 0x00, count: 32)
        self.controllerRegister = ControllerRegister()
        self.maskRegister = MaskRegister()
        self.oamRegister = OAMRegister()
        self.statusRegister = PPUStatusRegister()

        self.cycles = 0
        self.scanline = 0
        self.nmiInterrupt = nil
    }

    mutating public func reset() {
        self.internalDataBuffer = 0x00
        self.vram = [UInt8](repeating: 0x00, count: 2048)
        self.paletteTable = [UInt8](repeating: 0x00, count: 32)

        self.controllerRegister.reset()
        self.maskRegister.reset()
        self.oamRegister.reset()
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
}

extension PPU {
    mutating public func incrementVramAddress() {
        let increment = self.controllerRegister.vramAddressIncrement()
        self.currentSharedAddress = (self.currentSharedAddress &+ UInt16(increment)) & 0x3FFF
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

    private func readByte(address: UInt16) -> (result: UInt8, shouldBuffer: Bool) {
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

extension PPU {
    static public func makeEmptyScreenBuffer() -> [NESColor] {
        [NESColor](repeating: .black, count: Self.width * Self.height)
    }

    // We effectively are doing double buffering here to maximize performance.
    mutating public func updateScreenBuffer(_ otherBuffer: inout [NESColor]) {
        swap(&self.screenBuffer, &otherBuffer)
    }

    private func bytesForTileAt(bankIndex: Int,
                                tileIndex: Int) -> ArraySlice<UInt8> {
        let bankAddressStart = UInt16(bankIndex * 0x1000)
        let startAddress = bankAddressStart + UInt16(tileIndex * 16)
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

    private func getTileColorIndex(bankIndex: Int,
                                   tileIndex: Int,
                                   tilePixelX: Int,
                                   tilePixelY: Int) -> Int {
        let tileBytes = self.bytesForTileAt(bankIndex: bankIndex,
                                            tileIndex: tileIndex)
        let firstByte = tileBytes[tileBytes.startIndex + tilePixelY]
        let secondByte = tileBytes[tileBytes.startIndex + tilePixelY + 8]
        let bitMask: UInt8 = 0b1000_0000 >> tilePixelX
        let firstBit = firstByte & bitMask > 0 ? 0b01 : 0b00
        let secondBit = secondByte & bitMask > 0 ? 0b10 : 0b00
        return secondBit | firstBit
    }

    private func getBackgroundTileColor(x: Int, y: Int) -> NESColor? {
        let tileData = self.currentTileData
        let pixelData = tileData >> ((7 - self.currentFineX) * 4)
        let colorIndex = Int(pixelData & 0x0F)
        return colorIndex.isMultiple(of: 4) ? nil : NESColor.systemPalette[Int(self.paletteTable[colorIndex])]
    }

    private func getSpritePalette(paletteIndex: Int, colorIndex: Int) -> NESColor? {
        // NOTA BENE: The sprite palettes occupy the _upper_ 16 bytes
        // of the palette table, which is why the offset below is 0x10
        // and not 0x00.
        let paletteStartIndex = Int(0x10 + (paletteIndex * 4))
        return getColorFromPalette(baseIndex: paletteStartIndex, entryIndex: colorIndex)
    }

    var tileWidth: Int { 8 }
    var tileHeight: Int { 8 }
    var spriteWidth: Int { tileWidth }
    var spriteHeight: Int { self.controllerRegister[.spritesAre8x16] ? tileHeight * 2 : tileHeight }

    var tileAddress: UInt16 { 0x2000 | (0x0FFF & self.currentSharedAddress) }
    var backgroundPatternBaseAddress: UInt16 { self.controllerRegister[.backgroundPatternBankIndex] ? 0x1000 : 0x0000 }
    var currentAttributeAddress: UInt16 {
        // The attribute table byte associated with any one tile is actually
        // shared with all sixteen tiles for that tile's metatile block. The
        // attribute table bytes start at byte 960 (or 0x03C0) after the current
        // nametable beginning, further indexed by the metatile block index along
        // Y and the metatile block index along X.
        //
        // The following shows how the tile //address maps to its attribute address:
        // the first six bytes of each are the same; the top three bits of the
        // coarse Y value (YYY) and the the top three bits of coarse X (XXX) designate
        // the metatile block indices for each axis, and form the last six bits of
        // the attribute address. The offset 0x03C0 corresponds with the middle four bits,
        // all turned on.
        //
        //    Tile address            Attribute address
        // 0010 NNYY YyyX XXxx  -->  0010 NN11 11YY YXXX
        //
        // You may be wondering if it is possible for these two addresses to be the
        // same... and it turns out that they are never so! The reason is that
        // the visible screen is 32 x 30 tiles. That means that the final tile address
        // for a given nametable, correspondent with the 960th tile is:
        //
        // 0010 NN11 1011 1111
        //
        // ... where YYYyy is 11110 and XXXxx is 11111. However, the _first_ attribute
        // tile address, correspondent with the 0th tile is:
        //
        // 0010 0011 1100 0000
        //
        // ... where YYY is 000 and XXX is 000. Quite ingenious!
        return 0x23C0 |
               UInt16(self.currentSharedAddress[.nametable]) << 10 |
               UInt16(self.currentSharedAddress[.coarseY] / 4) << 3 |
               UInt16(self.currentSharedAddress[.coarseX] / 4)
    }
    var currentTileData: UInt32 {
        UInt32(self.currentAndNextTileData >> 32)
    }

    private static func makeChrTileAddress(bankIndex: Bool, tileIndex: UInt8, bitPlaneIndex: Bool, fineY: UInt8) -> UInt16 {
        // The stucture of CHR pattern tile addresses is the following:
        //
        // 000b tttt tttt pyyy
        //    | |||| |||| ||||
        //    | |||| |||| |+++-- fine y offset within the tile
        //    | |||| |||| |
        //    | |||| |||| +----- bit plane index: 0 is low, 1 is high
        //    | |||| ||||
        //    | ++++-++++------- tile index
        //    |
        //    +----------------- bank index
        return (bankIndex ? 0x1000 : 0x0000) |
               UInt16(tileIndex) << 4 |
               (bitPlaneIndex ? 0b1000 : 0b0000) |
               UInt16(fineY)
    }

    mutating private func cacheNametableByte() {
        let address = 0x2000 | (self.currentSharedAddress & 0x0FFF)
        self.currentNametableByte = self.readByte(address: address).result
    }

    mutating private func cachePaletteIndex() {
        // ACHTUNG! Think about what Becca said about this, but for now,
        // we're gonna keep this implementation.
        //
        // Ultimately, the goal of this function is to compute and cache an
        // index into the background palette for the currently cached values of
        // coarse X and coarse Y.
        //
        // In the NES, a single attribute table byte is used to manage the palettes
        // of a group of 4x4 tiles arranged in what is called a metatile block.
        // Within that block, they are further subdivided into 2x2 blocks called
        // metatiles. Each tile in the metatile block is effectively associated with a
        // pair of bits that are used to index into the corresponding attribute table
        // byte. The diagram below illustrates how those bit indices are associated
        // with each tile in a metatile block:
        //
        //                   coarse X
        //               0    1    2    3   ...
        //             +----+----+----+----+
        //          0  | 00 | 00 | 10 | 10 |
        //             +----+----|----+----|
        //          1  | 00 | 00 | 10 | 10 |
        // coarse Y    +----+----|----+----|
        //          2  | 01 | 01 | 11 | 11 |
        //             +----+----|----+----|
        //          3  | 01 | 01 | 11 | 11 |
        //             +----+----+----+----|
        //          .
        //          .
        //          .
        //
        // ... and below shows how those indices need to map to pairs of bits in the
        // attribute table byte
        //
        // +----+----+----+----+
        // | 11 | 01 | 10 | 00 |
        // +----+----+----+----+

        // First we need to grab the current coarse X and coarse Y values...
        let coarseX = self.currentSharedAddress[.coarseX]
        let coarseY = self.currentSharedAddress[.coarseY]

        // ... then we need to convert them into a shift index into the corresponding
        // attribute table byte. We do this by first doing modulo division on each
        // by four to get the X and Y indices _within the given metatile block_, then
        // dividing again by two to get the _metatile index within the 4x4 block_ ...
        let metatileBlockIndexX = (coarseX % 4) / 2
        let metatileBlockIndexY = (coarseY % 4) / 2

        // We need to index into the corresponding attribute table byte and pluck out
        // the two bits starting there, and so we need to map the metatile (X, Y) pairs
        // to the attribute byte indices like below:
        //
        // (0, 0) -> 0
        // (1, 0) -> 2
        // (0, 1) -> 4
        // (1, 1) -> 6
        //
        // To do this mapping, we form a two bit number by taking metatile block index Y as
        // the two's bit and metatile block index X as the one's bit. Then we need
        // to multiply that number by two because we need to index in _steps of two_,
        // not one.
        let paletteIndexShift = (metatileBlockIndexY << 1 | metatileBlockIndexX) * 2

        // ... now actually grab the palette byte using the current attribute address...
        let paletteByte = self.readByte(address: self.currentAttributeAddress).result

        // ... finally, pluck out and cache the two bits representing the palette index
        self.currentPaletteIndex = (paletteByte >> paletteIndexShift) & 0b0000_0011
    }

    mutating private func cacheLowTileByte() {
        let address = Self.makeChrTileAddress(bankIndex: self.controllerRegister[.backgroundPatternBankIndex],
                                              tileIndex: self.currentNametableByte,
                                              bitPlaneIndex: false,
                                              fineY: self.currentSharedAddress[.fineY])

        self.currentLowTileByte = self.readByte(address: address).result
    }

    mutating private func cacheHighTileByte() {
        let address = Self.makeChrTileAddress(bankIndex: self.controllerRegister[.backgroundPatternBankIndex],
                                              tileIndex: self.currentNametableByte,
                                              bitPlaneIndex: true,
                                              fineY: self.currentSharedAddress[.fineY])

        self.currentHighTileByte = self.readByte(address: address).result
    }

    mutating private func cacheTileData() {
        // This function builds a new 32-bit integer which will contain 8 nibbles,
        // each of which contains data for a pixel within the current tile.
        // It will be structured like the following:
        //
        //   0    1    2    3    4    5    6    7
        // pphl pphl pphl pphl pphl pphl pphl pphl
        //
        // ... where pp is the two bits for the palette index, h is the high tile bit,
        // and l is the low tile bit, all associated with each pixel in the
        // current tile.
        //
        // Once the new tile data are assembled, it is ORed onto the 64-bit cache,
        // which has data for both the current _and_ next tiles.
        var newTileData: UInt32 = 0
        for _ in 0 ..< 8 {
            let lowBit = (self.currentLowTileByte & 0b1000_0000) >> 7
            let highBit = (self.currentHighTileByte & 0b1000_0000) >> 6
            let paletteBits = self.currentPaletteIndex << 2
            let newTileDataNibble = paletteBits | highBit | lowBit
            newTileData <<= 4
            newTileData |= UInt32(newTileDataNibble)
            self.currentLowTileByte <<= 1
            self.currentHighTileByte <<= 1
        }
        self.currentAndNextTileData |= UInt64(newTileData)
    }

    mutating private func copyX() {
        self.currentSharedAddress[.coarseX] = self.nextSharedAddress[.coarseX]
        self.currentSharedAddress[.nametableX] = self.nextSharedAddress[.nametableX]
    }

    mutating private func copyY() {
        self.currentSharedAddress[.coarseY] = self.nextSharedAddress[.coarseY]
        self.currentSharedAddress[.fineY] = self.nextSharedAddress[.fineY]
        self.currentSharedAddress[.nametableY] = self.nextSharedAddress[.nametableY]
    }

    mutating private func incrementX() {
        if self.currentSharedAddress[.coarseX] == 0b1_1111 {
            // Reset coarse X
            self.currentSharedAddress[.coarseX] = 0b0_0000
            // Toggle horizontal nametable
            self.currentSharedAddress[.nametable] ^= 0b01
        } else {
            // Just increment coarse X
            self.currentSharedAddress[.coarseX] += 0b0_0001
        }
    }

    mutating private func incrementY() {
        if self.currentSharedAddress[.fineY] == 0b111 {
            // Reset fine Y
            self.currentSharedAddress[.fineY] = 0b000

            if self.currentSharedAddress[.coarseY] == 0b1_1101 {
                // Reset coarse Y
                self.currentSharedAddress[.coarseY] = 0b0_0000
                // Toggle vertical nametable
                self.currentSharedAddress[.nametable] ^= 0b10
            } else if self.currentSharedAddress[.coarseY] == 0b1_1111 {
                // ACHTUNG! How would we ever get to this branch?
                //
                // Reset coarse Y
                self.currentSharedAddress[.coarseY] = 0b0_0000
            } else {
                // Just increment coarse Y
                self.currentSharedAddress[.coarseY] += 0b0_0001
            }
        } else {
            // Just increment fine Y
            self.currentSharedAddress[.fineY] += 0b001
        }
    }

    private func getSpriteColor(spriteIndex: Int,
                                x: Int,
                                y: Int) -> NESColor? {
        let tileAttributes = self.oamRegister.data[spriteIndex + 2]
        let tileX = Int(self.oamRegister.data[spriteIndex + 3])
        // Determine if the x coordinate falls inside the sprite
        guard x >= tileX && x <= tileX + self.spriteWidth - 1 else {
            return nil
        }
        let tileY = Int(self.oamRegister.data[spriteIndex])

        let flipVertical = tileAttributes >> 7 & 1 == 1
        let flipHorizontal = tileAttributes >> 6 & 1 == 1
        let paletteIndex = Int(tileAttributes & 0b11)

        let deltaX = x - tileX
        let deltaY = y - tileY
        guard deltaX >= 0 && deltaY >= 0 else {
            // Sprite is at least partially off screen
            return nil
        }

        let spritePixelX = flipHorizontal ? (spriteWidth - 1) - deltaX % spriteWidth : deltaX % spriteWidth
        let spritePixelY = flipVertical ? (spriteHeight - 1) - deltaY % spriteHeight : deltaY % spriteHeight

        let tileIndexByte = self.oamRegister.data[spriteIndex + 1]
        let topTileIndex: Int
        let bankIndex: Int
        if self.controllerRegister[.spritesAre8x16] {
            // The bits in the tile index byte are arranged like 'tttttttb'.
            // The first seven bits form the base for the tile index, where the
            // top half of the sprite has tile index ttttttt0, and the bottom
            // half has index ttttttt1. The last bit indicates which tile bank
            // to use to fetch the tile; 0 means the starting address should be
            // 0x0000, 1 means 0x1000. See the following for more details:
            //
            //     https://www.nesdev.org/wiki/PPU_OAM#Byte_1
            bankIndex = Int(tileIndexByte & 0b0000_0001)
            topTileIndex = Int(tileIndexByte & 0b1111_1110)
        } else {
            bankIndex = self.controllerRegister[.spritePatternBankIndex] ? 1 : 0
            topTileIndex = Int(tileIndexByte)
        }

        let colorIndex: Int
        // The following test effectively checks to see if we're sampling
        // from the top tile or the the bottom tile for an 8x16 sprite.
        // If the sprite's y value is larger than the height of a tile, then
        // we know that we're dealing with the bottom tile; otherwise, we're
        // still in the top tile. If we're handling an 8x8 sprite, then it's
        // as if we're handling the top tile of an 8x16 sprite.
        if spritePixelY < tileHeight {
            colorIndex = self.getTileColorIndex(bankIndex: bankIndex,
                                                tileIndex: topTileIndex,
                                                tilePixelX: spritePixelX,
                                                tilePixelY: spritePixelY)
        } else {
            // If we're here, then we know that we're handling the bottom tile
            // in which case its index is one more than that for the top tile.
            // Also, the tile's y coordinate needs to be adjusted to fall inside
            // the tile.
            colorIndex = self.getTileColorIndex(bankIndex: bankIndex,
                                                tileIndex: topTileIndex + 1,
                                                tilePixelX: spritePixelX,
                                                tilePixelY: spritePixelY % tileHeight)
        }

        let color = self.getSpritePalette(paletteIndex: paletteIndex, colorIndex: colorIndex)
        return color
    }

    private func getSpriteColor(x: Int, y: Int) -> (color: NESColor, index: Int, backgroundPriority: Bool)? {
        for index in self.spriteIndicesForCurrentScanline {
            if let color = self.getSpriteColor(spriteIndex: index,
                                               x: x,
                                               y: y) {
                let tileAttributes = self.oamRegister.data[index + 2]
                let backgroundPriority = tileAttributes >> 5 & 1 == 1
                return (color, index, backgroundPriority)
            }
        }

        return nil
    }

    mutating private func computeColorAt(x: Int, y: Int) -> NESColor {
        let maybeSpriteColor = self.getSpriteColor(x: x, y: y)
        let maybeBackgroundColor = self.getBackgroundTileColor(x: x, y: y)

        switch (maybeSpriteColor, maybeBackgroundColor) {
        case (.some((let spriteColor, let spriteIndex, let backgroundPriority)), .some(let backgroundColor)):
            // NOTA BENE: The following is commented out for the time being because
            // we need to fix some fundamental things first before this will work.
            // If we enabled it, Super Mario Bros. will eventually hang due to a bug
            // somewhere in our computation of the background tile color.
            //
            // if spriteIndex == 0 {
            //     self.statusRegister[.spriteZeroHit] = true
            // }

            switch backgroundPriority {
            case true:
                return backgroundColor
            case false:
                return spriteColor
            }
        case (.some((let spriteColor, _, _)), nil):
            return spriteColor
        case (nil, .some(let backgroundColor)):
            return backgroundColor
        case (nil, nil):
            return NESColor.systemPalette[Int(self.paletteTable[0])]
        }
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
        self.spriteIndicesForCurrentScanline = allSpriteIndices.filter({ oamIndex in
            let tileY = Int(self.oamRegister.data[oamIndex])

            // The sprite height property takes into account whether or not
            // it is 8x8 or 8x16, and so we need to test to see if the current
            // scanline intersects it anywhere vertically.
            let deltaY = self.spriteHeight - 1
            if self.scanline >= tileY && self.scanline <= tileY + deltaY {
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

    var isRenderingEnabled: Bool {
        self.maskRegister[.showBackground] || self.maskRegister[.showSprites]
    }
    var isVisibleLine: Bool {
        self.scanline < Self.height
    }
    var isPreLine: Bool {
        self.scanline == Self.scanlinesPerFrame
    }
    var isRenderLine: Bool {
        self.isVisibleLine || self.isPreLine
    }
    var isVisibleCycle: Bool {
        self.cycles >= 0 && self.cycles < Self.width
    }
    var isPrefetchCycle: Bool {
        self.cycles >= 320 && self.cycles <= 335
    }
    var isFetchCycle: Bool {
        self.isVisibleCycle || self.isPrefetchCycle
    }

    mutating private func updateCaches() {
        if self.isRenderLine && self.isFetchCycle {
            self.currentAndNextTileData <<= 4

            // TODO: Why do I have an off-by-one issue here?
            switch (self.cycles+1) % 8 {
            case 1:
                self.cacheNametableByte()
            case 3:
                self.cachePaletteIndex()
            case 5:
                self.cacheLowTileByte()
            case 7:
                self.cacheHighTileByte()
            case 0:
                self.incrementX()
                self.cacheTileData()
            default:
                break
            }
        }

        if self.isPreLine && self.cycles >= 280 && self.cycles <= 304 {
            self.copyY()
        }

        if self.isRenderLine {
            if self.cycles == 256 {
                self.incrementY()
            }

            if self.cycles == 257 {
                self.copyX()
            }
        }
    }

    // The return value below ultimately reflects whether or not
    // we need to redraw the screen.
    mutating func tick(cpuCycles: Int) -> Bool {
        var redrawScreen = false

        for _ in 0 ..< cpuCycles * 3 {
            if self.cycles == 0 {
                self.cacheSpriteIndices()
            }

            if self.isVisibleLine && self.isVisibleCycle {
                self.renderPixel(x: self.cycles, y: Int(self.scanline))
            }

            if self.isRenderingEnabled {
                self.updateCaches()
            }

            self.cycles += 1

            if self.cycles >= Self.ppuCyclesPerScanline {
                if self.isSpriteZeroHit(cycles: self.cycles) {
                    self.statusRegister[.spriteZeroHit] = true
                }

                self.cycles = 0
                self.scanline += 1

                if self.scanline == Self.nmiInterruptScanline {
                    self.statusRegister[.verticalBlankStarted] = true

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
