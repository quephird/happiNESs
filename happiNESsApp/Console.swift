//
//  Console.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import happiNESs
import Observation
import SwiftUI

@Observable @MainActor class Console {
    static let frameRate = 60
    static let defaultScale = 2.0

    public static let keyMappings: [KeyEquivalent : JoypadButton] = [
        .upArrow : .up,
        .downArrow : .down,
        .leftArrow : .left,
        .rightArrow : .right,
        .space : .select,
        .return : .start,
        KeyEquivalent("a") : .buttonA,
        KeyEquivalent("s") : .buttonB,
    ]

    private var speaker: Speaker
    var cartridgeLoaded: Bool = false
    var displayTimer: Timer!
    var saveDataFileDirectory: URL
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
            self.saveDataFileDirectory = try fileManager.url(for: .applicationSupportDirectory,
                                                             in: .userDomainMask,
                                                             appropriateFor: nil,
                                                             create: true).appending(path: "happiNESs")
            try fileManager.createDirectory(at: saveDataFileDirectory, withIntermediateDirectories: true)
        } catch {
            throw NESError.cannotCreateSaveDataDirectory
        }
    }

    public func runGame(fileUrl: URL) throws {
        let cartridge = try Cartridge(cartridgeUrl: fileUrl, saveDataFileDirectory: self.saveDataFileDirectory)
        if cartridge.hasBattery {
            try cartridge.loadSram()
        }

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

    public func dumpPpu() {
        self.cpu.bus.ppu.dump()
    }

    public func reset() {
        self.cpu.reset()
    }

    public func saveSram() throws {
        if self.cpu.bus.cartridge!.hasBattery {
            try self.cpu.bus.cartridge!.saveSram()
            self.lastSavedDate = Date.now
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
