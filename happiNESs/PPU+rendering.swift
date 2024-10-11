//
//  PPU+rendering.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/6/24.
//

extension PPU {
    private func bytesForTileAt(bankIndex: Int,
                                tileIndex: Int) -> ArraySlice<UInt8> {
        let bankAddressStart = UInt16(bankIndex * 0x1000)
        let startAddress = bankAddressStart + UInt16(tileIndex * 16)
        return self.cartridge!.readTileFromChr(startAddress: startAddress)
    }

    private func getColorFromPalette(baseIndex: Int, entryIndex: Int) -> NESColor? {
        guard !entryIndex.isMultiple(of: 4) else {
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

    var tileWidth: Int {
        8
    }
    var tileHeight: Int {
        8
    }
    var spriteWidth: Int {
        tileWidth
    }
    var spriteHeight: Int {
        self.controllerRegister[.spritesAre8x16] ? tileHeight * 2 : tileHeight
    }

    private func getSpriteColor(spriteIndex: Int,
                                x: Int,
                                y: Int) -> NESColor? {
        let tileAttributes = self.oamRegister.data[spriteIndex + 2]
        let tileX = Int(self.oamRegister.data[spriteIndex + 3])
        // Determine if the x coordinate falls inside the sprite
        guard x >= tileX && x < tileX + self.spriteWidth else {
            return nil
        }
        // ACHTUNG! Note that the value in OAM is one less than the actual Y value!
        //
        //    https://www.nesdev.org/wiki/PPU_OAM#Byte_0
        let tileY = Int(self.oamRegister.data[spriteIndex]) + 1

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
             if spriteIndex == 0 {
                 self.statusRegister[.spriteZeroHit] = true
             }

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

    mutating private func setColorAt(x: Int, y: Int, to color: NESColor) {
        self.screenBuffer[Self.width * y + x] = color
    }

    mutating public func renderPixel(x: Int, y: Int) {
        let color = self.computeColorAt(x: x, y: y)
        setColorAt(x: x, y: y, to: color)
    }

    static public func makeEmptyScreenBuffer() -> [NESColor] {
        [NESColor](repeating: .black, count: Self.width * Self.height)
    }

    // We are double buffering here to maximize performance.
    mutating public func updateScreenBuffer(_ otherBuffer: inout [NESColor]) {
        swap(&self.screenBuffer, &otherBuffer)
    }
}
