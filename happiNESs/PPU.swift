//
//  PPU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/6/24.
//

public struct PPU {
    public var internalDataBuffer: UInt8
    public var chrRom: [UInt8]
    public var paletteTable: [UInt8]
    public var vram: [UInt8]
    public var oamData: [UInt8]
    public var mirroring: Mirroring
    public var addressRegister: AddressRegister
    public var controllerRegister: ControllerRegister

    public init(chrRom: [UInt8], mirroring: Mirroring) {
        self.internalDataBuffer = 0x00
        self.chrRom = chrRom
        self.mirroring = mirroring
        self.vram = [UInt8](repeating: 0x00, count: 2048)
        self.oamData = [UInt8](repeating: 0x00, count: 64*4)
        self.paletteTable = [UInt8](repeating: 0x00, count: 32)
        self.addressRegister = AddressRegister()
        self.controllerRegister = ControllerRegister()
    }
}

extension PPU {
    mutating public func updateAddress(byte: UInt8) {
        self.addressRegister.updateAddress(byte: byte)
    }

    mutating public func updateController(byte: UInt8) {
        self.controllerRegister.update(byte: byte)
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
