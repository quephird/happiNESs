//
//  PPU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/6/24.
//

public struct PPU {
    public var bus: Bus? = nil
    public static let width = 256
    public static let height = 240

    public static let scanlinesPerFrame = 261
    public static let ppuCyclesPerScanline = 340
    public static let nmiInterruptScanline = 241

    public static let ppuAddressSpaceStart: UInt16 = 0x2000
    public static let nametableSize: Int = 0x0400
    public static let attributeTableOffset = 0x03C0

    public var cartridge: Cartridge?

    public var paletteTable: [UInt8]
    public var vram: [UInt8]
    public var internalDataBuffer: UInt8

    // TODO: Think about replacing these with simple UInt8's
    public var controllerRegister: ControllerRegister
    public var maskRegister: MaskRegister
    public var oamRegister: OAMRegister
    public var statusRegister: PPUStatusRegister

    // ACHTUNG! This field is shared between rendering and PPUADDR/PPUDATA when not rendering
    public var nextSharedAddress: Address = 0
    public var currentSharedAddress: Address = 0
    // This register is also shared by PPUADDR/PPUSCROLL
    public var wRegister: Bool = false

    public var isEvenFrame: Bool = true
    public var nmiDelay: Int = 0
    public var cycles: Int
    public var scanline: Int

    public var screenBuffer: [UInt8] = [UInt8](repeating: 0x00, count: Self.width * Self.height * 3)

    // These are all cached values that are refreshed during various stages
    // of the rendering cycle.
    public var currentNametableByte: UInt8 = 0
    public var currentPaletteIndex: UInt8 = 0
    public var currentLowTileByte: UInt8 = 0
    public var currentHighTileByte: UInt8 = 0
    public var currentAndNextTileData: UInt64 = 0
    public var currentFineX: UInt8 = 0
    public var currentSprites: [CachedSprite] = []

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
        self.nmiDelay = 0

        self.nextSharedAddress = 0x0000
        self.currentSharedAddress = 0x0000
        self.wRegister = false
    }

    // Various computed properties used across multiple concerns
    var isRenderingEnabled: Bool {
        self.maskRegister[.showBackground] || self.maskRegister[.showSprites]
    }
    var isVisibleLine: Bool {
        self.scanline < Self.height
    }
    var isNmiScanline: Bool {
        self.scanline == Self.nmiInterruptScanline
    }
    var isPreRenderLine: Bool {
        self.scanline == Self.scanlinesPerFrame
    }
    var isPastPreRenderLine: Bool {
        self.scanline > Self.scanlinesPerFrame
    }
    var isRenderLine: Bool {
        self.isVisibleLine || self.isPreRenderLine
    }
    var isVisibleCycle: Bool {
        self.cycles >= 0 && self.cycles < Self.width
    }
    var isIncrementVerticalScrollCycle: Bool {
        self.cycles == Self.width
    }
    var isCopyHorizontalScrollCycle: Bool {
        self.cycles == Self.width + 1
    }
    var isCopyVerticalScrollCycle: Bool {
        self.cycles >= 280 && self.cycles <= 304
    }
    var isPrefetchCycle: Bool {
        self.cycles >= 320 && self.cycles <= 335
    }
    var isFetchCycle: Bool {
        self.isVisibleCycle || self.isPrefetchCycle
    }
    var isOnLastCycle: Bool {
        self.cycles == Self.ppuCyclesPerScanline
    }
    var isPastLastCycle: Bool {
        self.cycles > Self.ppuCyclesPerScanline
    }
    var isSpriteZeroHit: Bool {
        self.statusRegister[.spriteZeroHit]
    }

    // NOTA BENE: The NMI needs to be fired only after the _following_
    // instruction is completed, simulating the delay in the actual
    // NES hardware. In other words, the PPU doesn't directly and immediately
    // trigger an NMI in the CPU. This corresponds with two calls
    // to PPU's `tick()` function.
    mutating func queueNmi() {
        self.nmiDelay = 2
    }

    mutating func checkNmiQueue() {
        if self.nmiDelay > 0 {
            self.nmiDelay -= 1
            if self.nmiDelay == 0 {
                self.bus!.triggerNmi()
            }
        }
    }

    mutating func updateCycles() {
        // NOTA BENE: Per this section of the NESDev wiki, we need to skip
        // a cycle every other frame
        //
        //     https://www.nesdev.org/wiki/PPU_frame_timing#Even/Odd_Frames
        if self.isRenderingEnabled {
            if self.isEvenFrame && self.isPreRenderLine && self.isOnLastCycle {
                self.cycles = 0
                self.scanline = 0
                self.isEvenFrame = !self.isEvenFrame
                return
            }
        }

        self.cycles += 1

        if self.isPastLastCycle {
            self.cycles = 0
            self.scanline += 1

            if self.isPastPreRenderLine {
                self.scanline = 0
                self.isEvenFrame = !self.isEvenFrame
            }
        }
    }

    // The return value below ultimately reflects whether or not
    // we need to redraw the screen.
    //
    // TODO: Need to rename this function and the one in APU as well
    mutating func tick(cpuCycles: Int) -> Bool {
        var redrawScreen = false

        self.checkNmiQueue()

        for _ in 0 ..< cpuCycles * 3 {
            self.updateCycles()

            if self.isRenderingEnabled {
                if self.isVisibleLine && self.isVisibleCycle {
                    self.renderPixel()
                }

                self.cacheBackgroundTiles()

                if self.isVisibleLine && self.cycles == 0 {
                    self.cacheSprites()
                }
            }

            if self.cycles == 0 {
                if self.isNmiScanline {
                    self.statusRegister[.verticalBlankStarted] = true

                    if self.controllerRegister[.generateNmi] {
                        self.queueNmi()
                    }

                    redrawScreen = true
                }

                if self.isPreRenderLine {
                    self.statusRegister[.verticalBlankStarted] = false
                    self.statusRegister[.spriteZeroHit] = false
                }
            }
        }

        return redrawScreen
    }
}
