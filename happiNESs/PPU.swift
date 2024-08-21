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

    public var internalDataBuffer: UInt8
    public var chrRom: [UInt8]
    public var paletteTable: [UInt8]
    public var vram: [UInt8]
    public var mirroring: Mirroring

    public var addressRegister: AddressRegister
    public var controllerRegister: ControllerRegister
    public var maskRegister: MaskRegister
    public var oamRegister: OAMRegister
    public var scrollRegister: ScrollRegister
    public var statusRegister: PPUStatusRegister

    public var cycles: Int
    public var scanline: UInt16
    public var nmiInterrupt: UInt8?

    public init(chrRom: [UInt8], mirroring: Mirroring) {
        self.internalDataBuffer = 0x00
        self.chrRom = chrRom
        self.mirroring = mirroring
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
}

extension PPU {
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
        self.controllerRegister.update(byte: byte)
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

        return switch (self.mirroring, nameTable) {
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

    public func readByteWithoutMutating() -> (result: UInt8, newInternalDataBuffer: UInt8?) {
        let address = self.addressRegister.getAddress()

        switch address {
        case 0...0x1FFF:
            // TODO: Again... I'm concerned about the magnitude of `address` here and how large `chrRom` is
            return (self.internalDataBuffer, self.chrRom[Int(address)])
        case 0x2000...0x2FFF:
            // TODO: Same same concern as above
            return (internalDataBuffer, self.vram[Int(self.mirrorVramAddress(address: address))])
        case 0x3000...0x3EFF:
            let message = String(format: "address space 0x3000..0x3eff is not expected to be used, requested = %04X", address)
            fatalError(message)
        case 0x3F00...0x3FFF:
            // TODO: The range of the index below is 0-127; isn't it possible for this to cause a crash
            // since the palette table is only 32 bytes long?!
            return (self.paletteTable[Int(address - 0x3F00)], nil)
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
        // Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C
        case 0x3F10, 0x3F14, 0x3F18, 0x3F1C:
            let mirroredAddress = address - 0x0010
            self.paletteTable[Int(mirroredAddress - 0x3F00)] = byte
        case 0x3f00 ... 0x3FFF:
            self.paletteTable[Int(address - 0x3F00)] = byte
        default:
            let message = String(format: "unexpected access to mirrored spacU: %04X", address)
            fatalError(message)
        }

        self.incrementVramAddress()
    }
}

extension PPU {
    mutating func tick(cpuCycles: Int) -> Bool {
        self.cycles += cpuCycles * 3

        if self.cycles >= Self.ppuCyclesPerScanline {
            self.cycles -= Self.ppuCyclesPerScanline
            self.scanline += 1

            if self.scanline == Self.nmiInterruptScanline {
                if self.controllerRegister[.generateNmi] {
                    self.statusRegister[.verticalBlankStarted] = true
                    // TODO: Need to trigger NMI interrupt!
                }
            }

            if self.scanline >= Self.scanlinesPerFrame {
                self.scanline = 0
                self.statusRegister[.verticalBlankStarted] = false

                return true
            }
        }

        return false
    }
}

extension PPU {
    func bytesForTileAt(bank: Int, tileNumber: Int) -> ArraySlice<UInt8> {
        let startIndex = (bank * 0x1000) + tileNumber * 16
        return self.chrRom[startIndex..<startIndex + 16]
    }

    static public func makeEmptyScreenBuffer() -> [NESColor] {
        [NESColor](repeating: .black, count: Self.width * Self.height)
    }

    public func makeScreenBuffer() -> [NESColor] {
        var screenBuffer = Self.makeEmptyScreenBuffer()

        for tileNumber in 0..<256 {
            let screenY = (tileNumber / 20) * 10 + 2
            let screenX = (tileNumber % 20) * 10 + 2
            self.drawTile(to: &screenBuffer, bank: 0, tileNumber: tileNumber, screenX: screenX, screenY: screenY)
        }

        return screenBuffer
    }

    public func drawTile(to screenBuffer: inout [NESColor],
                         bank: Int,
                         tileNumber: Int,
                         screenX: Int,
                         screenY: Int) {
        let tileBytes = bytesForTileAt(bank: bank, tileNumber: tileNumber)

        for (tileY, var (upperByte, lowerByte)) in zip(tileBytes.prefix(8), tileBytes.suffix(8)).enumerated() {
            for tileX in (0 ... 7).reversed() {
                let colorIndex = (upperByte & 0x01) << 1 | (lowerByte & 0x01)
                upperByte >>= 1
                lowerByte >>= 1

                let color = switch colorIndex {
                case 0: NESColor.systemPalette[0x01]
                case 1: NESColor.systemPalette[0x23]
                case 2: NESColor.systemPalette[0x27]
                case 3: NESColor.systemPalette[0x30]
                default: fatalError("can't be")
                }

                screenBuffer[Self.width * (screenY + tileY) + (screenX + tileX)] = color
            }
        }
    }
}
