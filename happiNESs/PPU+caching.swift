//
//  PPU+caching.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/6/24.
//

extension PPU {
    var tileAddress: UInt16 {
        0x2000 | (0x0FFF & self.currentSharedAddress)
    }
    var backgroundPatternBaseAddress: UInt16 {
        self.controllerRegister[.backgroundPatternBankIndex] ? 0x1000 : 0x0000
    }
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

    private static func makeChrTileAddress(bankIndex: Bool,
                                           tileIndex: UInt8,
                                           bitPlaneIndex: Bool,
                                           fineY: UInt8) -> UInt16 {
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

    private func getSpriteData(for oamIndex: Int) -> UInt32 {
        let tileY = Int(self.oamRegister.data[oamIndex])
        let attributeByte = self.oamRegister.data[oamIndex + 2]

        let flipVertical = ((attributeByte >> 7) & 1) == 1
        let flipHorizontal = ((attributeByte >> 6) & 1) == 1

        var bankIndex = self.controllerRegister[.spritePatternBankIndex]
        var tileIndex = self.oamRegister.data[oamIndex + 1]
        var spritePixelY: Int = self.scanline - tileY
        if self.controllerRegister[.spritesAre8x16] {
            if flipVertical {
                spritePixelY = 15 - spritePixelY
            }

            // The bits in the tile index byte are arranged like 'tttttttb'.
            // The first seven bits form the base for the tile index, where the
            // top half of the sprite has tile index ttttttt0, and the bottom
            // half has index ttttttt1. The last bit indicates which tile bank
            // to use to fetch the tile; 0 means the starting address should be
            // 0x0000, 1 means 0x1000. See the following for more details:
            //
            //     https://www.nesdev.org/wiki/PPU_OAM#Byte_1
            bankIndex = tileIndex & 1 == 1
            tileIndex &= 0b1111_1110

            // The following test effectively checks to see if we're sampling
            // from the top tile or the the bottom tile for an 8x16 sprite.
            // If the sprite's pixel Y value is larger than the height of a tile, then
            // we know that we're dealing with the bottom tile; otherwise, we're
            // still in the top tile, and nothing else needs to be adjusted.
            if spritePixelY > 7 {
                // If we're here, then we know that we're handling the bottom tile
                // of the sprite, in which case its tile index is one more than that for
                // the top tile, and we need adjust the spritePixelY value such that
                // it falls inside the tile.
                tileIndex += 1
                spritePixelY -= 8
            }
        } else {
            if flipVertical {
                spritePixelY = 7 - spritePixelY
            }
        }

        let lowTileAddress = Self.makeChrTileAddress(bankIndex: bankIndex,
                                                     tileIndex: tileIndex,
                                                     bitPlaneIndex: false,
                                                     fineY: UInt8(spritePixelY))
        let highTileAddress = Self.makeChrTileAddress(bankIndex: bankIndex,
                                                      tileIndex: tileIndex,
                                                      bitPlaneIndex: true,
                                                      fineY: UInt8(spritePixelY))
        var lowTileByte = self.readByte(address: lowTileAddress).result
        var highTileByte = self.readByte(address: highTileAddress).result
        let paletteBits = (attributeByte & 0b11) << 2

        // Here we're caching the palette information for the current sprite.
        // We store the nibbles in one direction if there is no horizontal flip
        // or in the other direction if there is. We accomplish this by either
        // shifting the source bits from lowTileByte and highTileByte right or left.
        var data: UInt32 = 0
        for _ in 0 ..< 8 {
            var lowTileBit, highTileBit: UInt8
            if flipHorizontal {
                lowTileBit = lowTileByte & 1
                highTileBit = (highTileByte & 1) << 1
                lowTileByte >>= 1
                highTileByte >>= 1
            } else {
                lowTileBit = (lowTileByte & 0b1000_0000) >> 7
                highTileBit = (highTileByte & 0b1000_0000) >> 6
                lowTileByte <<= 1
                highTileByte <<= 1
            }
            data <<= 4
            let newDataNibble = paletteBits | highTileBit | lowTileBit
            data |= UInt32(newDataNibble)
        }

        return data
    }

    mutating public func cacheSprites() {
        var newCachedSprites: [CachedSprite] = []

        // Note that each sprite takes _four consecutive bytes_ in the OAM
        for oamIndex in stride(from: 0, to: self.oamRegister.data.count, by: 4) {
            // ACHTUNG! Note that the value in OAM is one less than the actual Y value!
            //
            //    https://www.nesdev.org/wiki/PPU_OAM#Byte_0
            let tileY = Int(self.oamRegister.data[oamIndex])

            let spritePixelY = self.scanline - tileY
            // The sprite height property takes into account whether or not all
            // sprites are 8x8 or 8x16, and so we need to test to see if the current
            // scanline intersects it anywhere vertically.
            if spritePixelY < 0 || spritePixelY >= self.spriteHeight {
                continue
            }

            let data = self.getSpriteData(for: oamIndex)
            let tileX = Int(self.oamRegister.data[oamIndex + 3])
            let backgroundPriority = ((self.oamRegister.data[oamIndex + 2] >> 5) & 0b0000_0001) == 1
            let newSprite = CachedSprite(data: data,
                                         tileX: tileX,
                                         backgroundPriority: backgroundPriority,
                                         index: oamIndex)
            newCachedSprites.append(newSprite)

            if newCachedSprites.count == 8 {
                break
            }
        }

        self.currentSprites = newCachedSprites
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
            self.currentSharedAddress[.nametableX] ^= 0b1
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
                self.currentSharedAddress[.nametableY] ^= 0b1
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

    mutating public func cacheBackgroundTiles() {
        if self.isRenderLine && self.isFetchCycle {
            self.currentAndNextTileData <<= 4

            // NOTA BENE: Since we're starting to render at cycle 0 for each line
            // we need to update caches every eighth line beginning at the _first_
            // cycle.
            switch (self.cycles) % 8 {
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

        if self.isPreRenderLine && self.isCopyVerticalScrollCycle {
            self.copyY()
        }

        if self.isRenderLine {
            if self.isIncrementVerticalScrollCycle {
                self.incrementY()
            }

            if self.isCopyHorizontalScrollCycle {
                self.copyX()
            }
        }
    }
}
