//
//  PPU+tracing.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/6/24.
//

extension PPU {
    public func dump() {
        print("cycles: \(cycles), scanline: \(scanline)")
        dumpSprites()
        dumpNametable(vram.prefix(0x0400), labeled: "A")
        dumpNametable(vram.suffix(0x0400), labeled: "B")
    }

    func dumpSprites() {
        print("sprites: ")
        for oamDataIndex in stride(from: 0, to: self.oamData.count, by: 4).reversed() {
            let tileY = Int(self.oamData[oamDataIndex])
            let tileIndex = Int(self.oamData[oamDataIndex + 1])
            let tileAttributes = self.oamData[oamDataIndex + 2]
            let tileX = Int(self.oamData[oamDataIndex + 3])

            let flipVertical = tileAttributes >> 7 & 1 == 1
            let flipHorizontal = tileAttributes >> 6 & 1 == 1
            let isBackground = tileAttributes >> 5 & 1 == 1
            let paletteIndex = Int(tileAttributes & 0b11)

            print("- \(oamDataIndex / 4):", tileIndex, "@ \(tileX),\(tileY)",
                  (flipVertical ? "vflip" : ""), (flipHorizontal ? "hflip" : ""),
                  (isBackground ? "bg" : ""),
                  "colored", paletteIndex)
        }
    }

    func dumpNametable(_ nametable: ArraySlice<UInt8>, labeled: String) {
        print("nametable \(labeled):")

        for row in 0..<30 {
            print("- tiles: ", terminator: "")
            for column in 0..<32 {
                let i = column + row * 32
                let tileIndex = Int(nametable[nametable.startIndex + i])
                print(String(format: "%2x", tileIndex), terminator: " ")
            }
            print()
        }

        for row in 0..<15 {
            print("- attrs: ", terminator: "")
            for column in 0..<16 {
                let i = column + row * 16
                let attrs = Int(nametable[nametable.startIndex + i])
                let topLeft = attrs & 0b11
                let topRight = attrs & 0b1100 >> 2
                print(String(format: "%2x", topLeft), terminator: " ")
                print(String(format: "%2x", topRight), terminator: " ")
            }
            print()

            print("         ", terminator: "")
            for column in 0..<16 {
                let i = column + row * 16
                let attrs = Int(nametable[nametable.startIndex + i])
                let botLeft = attrs & 0b110000 >> 4
                let botRight = attrs & 0b11000000 >> 6
                print(String(format: "%2x", botLeft), terminator: " ")
                print(String(format: "%2x", botRight), terminator: " ")
            }
            print()
        }
    }
}
