//
//  PPU+rendering.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/6/24.
//

extension PPU {
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

    private func getCurrentBackgroundTileColor() -> NESColor? {
        let tileData = self.currentTileData
        let pixelData = tileData >> ((7 - self.currentFineX) * 4)
        let colorIndex = Int(pixelData & 0x0F)
        return colorIndex.isMultiple(of: 4) ? nil : NESColor.systemPalette[Int(self.paletteTable[colorIndex])]
    }

    private func getCurrentSpriteColor() -> (color: NESColor, index: Int, backgroundPriority: Bool)? {
        // Note that `currentSprites` is ordered from left to right by the OAM index,
        // with the first (zeroth) element being the so-called sprite zero. Furthermore,
        // the strategy here is to find the first sprite whose pixels intersect with the
        // current X value _and_ which has a non-transparent color. If we find none,
        // then we return a nil tuple.
        for sprite in self.currentSprites {
            let spritePixelX = self.cycles - sprite.tileX
            // Check to see if the current X value is within the current sprite
            if spritePixelX < 0 || spritePixelX > 7 {
                continue
            }

            let nibbleIndex = 7 - spritePixelX
            // NOTA BENE: The sprite palettes occupy the _upper_ 16 bytes of the palette
            // tables, which is why we add 0x10 below.
            let paletteIndex = Int((sprite.data >> (nibbleIndex * 4)) & 0b0000_1111) + 0x10
            if paletteIndex.isMultiple(of: 4) {
                continue
            }

            let color = NESColor.systemPalette[Int(self.paletteTable[paletteIndex])]
            return (color, sprite.index, sprite.backgroundPriority)
        }

        return nil
    }

    mutating private func getCurrentPixelColor() -> NESColor {
        let maybeSpriteColor = self.getCurrentSpriteColor()
        let maybeBackgroundColor = self.getCurrentBackgroundTileColor()

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

    mutating public func renderPixel() {
        let color = self.getCurrentPixelColor()
        let currentPixelIndex = Self.width * self.scanline + self.cycles
        self.screenBuffer[currentPixelIndex] = color
    }

    static public func makeEmptyScreenBuffer() -> [NESColor] {
        [NESColor](repeating: .black, count: Self.width * Self.height)
    }

    // We are double buffering here to maximize performance.
    mutating public func updateScreenBuffer(_ otherBuffer: inout [NESColor]) {
        swap(&self.screenBuffer, &otherBuffer)
    }
}
