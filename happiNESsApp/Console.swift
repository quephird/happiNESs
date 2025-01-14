//
//  Console.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import happiNESs

import GameController
import Observation
import SwiftUI

@Observable @MainActor class Console {
    static let frameRate = 60
    static let defaultScale = 2.0

    public static let keyMappings: [KeyEquivalent : RegisterBit] = [
        .upArrow : .up,
        .downArrow : .down,
        .leftArrow : .left,
        .rightArrow : .right,
        .space : .select,
        .return : .start,
        KeyEquivalent("a") : .buttonA,
        KeyEquivalent("s") : .buttonB,
    ]

    public var isPaused: Bool = false
    private var speaker: Speaker
    var cartridgeLoaded: Bool = false
    private var cartridge: Cartridge?
    var displayTimer: Timer!
    var saveSramDirectory: URL
    private var saveSramPath: URL?
    public var lastSavedDate: Date = Date.now
    public var currentError: NESError? = nil

    // NOTA BENE: We don't want the screen updated every single time something inside
    // this class changes, which is the one being observed by `ContentView`. We're only
    // really interested in changes to `Console`'s state such that at least of the underlying
    // pixels has changed, namely any of the elements of  `screenBuffer`.
    @ObservationIgnored private var cpu: CPU
    var screenBuffer: [UInt8] = PPU.makeEmptyScreenBuffer()
    var scale: Double = Console.defaultScale

    internal init() throws {
        let bus = Bus()
        let cpu = CPU(bus: bus, tracingOn: false)
        self.cpu = cpu

        self.speaker = try Speaker(inputBuffer: cpu.bus.apu.buffer)

        do {
            let fileManager = FileManager.default
            self.saveSramDirectory = try fileManager.url(for: .applicationSupportDirectory,
                                                             in: .userDomainMask,
                                                             appropriateFor: nil,
                                                             create: true).appending(path: "happiNESs")
            try fileManager.createDirectory(at: saveSramDirectory, withIntermediateDirectories: true)
        } catch {
            throw NESError.cannotCreateSaveDataDirectory
        }
    }

    public func runGame(fileUrl: URL) throws {
        let romData: Data = try Data(contentsOf: fileUrl)
        let cartridge = try Cartridge(romData: romData,
                                      interruptible: self.cpu.bus)

        let romFileName = fileUrl.lastPathComponent
        var saveSramFilename: String
        if let index = romFileName.lastIndex(of: ".") {
            let sramPrefix = String(romFileName.prefix(upTo: index))
            saveSramFilename = sramPrefix + ".dat"
        } else {
            saveSramFilename = romFileName + ".dat"
        }
        self.saveSramPath = saveSramDirectory.appendingPathComponent(saveSramFilename)

        self.cartridge = cartridge
        try self.loadSram()

        self.cpu.loadCartridge(cartridge: cartridge)
        self.cartridgeLoaded = true
        self.cpu.reset()

        // We need to do this to avoid keeping around previously registered timers
        // and having them fire when we load one ROM file after another
        self.displayTimer?.invalidate()

        // This sets up a timer which will call `runForOneFrame()` every time it fires.
        self.displayTimer = Timer.scheduledTimer(
            timeInterval: 1.0/TimeInterval(Self.frameRate),
            target: self,
            selector: #selector(runForOneFrame),
            userInfo: nil,
            repeats: true)
    }

    @objc func runForOneFrame() {
        if self.isPaused {
            return
        }

        cpu.executeInstructions(stoppingAfter: .nextFrame)
        cpu.bus.ppu.updateScreenBuffer(&self.screenBuffer)
        if self.cpu.bus.cartridge!.isSramDirty {
            if self.lastSavedDate.timeIntervalSinceNow < -5.0 {
                do {
                    try self.saveSram()
                } catch let error as NESError {
                    self.currentError = error
                } catch {
                    fatalError("We should not get here!")
                }
            }
        }
    }

    func handleKey(_ keyPress: KeyPress) -> Bool {
        guard let button = Self.keyMappings[keyPress.key] else {
            return false
        }

        cpu.handleButton(button: button, status: keyPress.phase != .up)
        return true
    }

    public func handleDpad(dpadElement: GCDirectionPadElement) {
        self.cpu.handleButton(button: .up, status: dpadElement.up.value > 0.5)
        self.cpu.handleButton(button: .down, status: dpadElement.down.value > 0.5)
        self.cpu.handleButton(button: .left, status: dpadElement.left.value > 0.5)
        self.cpu.handleButton(button: .right, status: dpadElement.right.value > 0.5)
    }

    public func handleButton(buttonElement: GCButtonElement, button: RegisterBit) {
        self.cpu.handleButton(button: button, status: buttonElement.pressedInput.isPressed)
    }

    public func dumpPpu() {
        self.cpu.bus.ppu.dump()
    }

    public func reset() {
        self.cpu.reset()
    }

    public func loadSram() throws {
        guard let cartridge = self.cartridge else {
            return
        }

        try cartridge.loadSramIfNeeded {
            var sramData: Data
            do {
                sramData = try Data.init(contentsOf: self.saveSramPath!)
            } catch {
                sramData = Data(repeating: 0x00, count: 0x2000)
            }

            if sramData.count != 0x2000 {
                throw NESError.invalidSaveDatafile
            }

            return sramData
        }
    }

    public func saveSram() throws {
        do {
            guard let cartridge = self.cartridge else {
                return
            }

            try cartridge.saveSramIfNeeded { sram in
                try sram.write(to: self.saveSramPath!)
                self.lastSavedDate = Date.now
            }
        } catch let error {
            throw NESError.unableToSaveDataFile(error.localizedDescription)
        }
    }

    public func togglePause() {
        self.isPaused.toggle()
        if self.isPaused {
            self.speaker.playPauseSound()
        }
    }

    var tracingOn: Bool {
        get {
            access(keyPath: \.tracingOn)
            return self.cpu.tracingOn
        }
        set {
            withMutation(keyPath: \.tracingOn) {
                self.cpu.tracingOn = newValue
            }
        }
    }
}
