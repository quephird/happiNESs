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

    var romLoaded: Bool = false
    var displayTimer: Timer!

    // NOTA BENE: We don't want the screen updated every single time something inside
    // this class changes, which is the one being observed by `ContentView`. We're only
    // really interested in changes to `Console`'s state such that at least of the underlying
    // pixels has changed, namely any of the elements of  `screenBuffer`.
    @ObservationIgnored var cpu: CPU
    var screenBuffer: [NESColor] = PPU.makeEmptyScreenBuffer()

    internal init() throws {
        let bus = Bus()
        let cpu = CPU(bus: bus, tracingOn: false)
        self.cpu = cpu
    }

    public func runGame(fileUrl: URL) throws {
        let data: Data = try Data(contentsOf: fileUrl)
        let romBytes = [UInt8](data)
        guard let rom = Rom(bytes: romBytes) else {
            throw NESError.romCouldNotBeRead
        }

        self.cpu.loadRom(rom: rom)
        self.romLoaded = true
        self.cpu.reset()

        // We need to do this to avoid keeping around previously registered timers
        // and having them fire when we load on ROM file after another
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
        cpu.updateScreenBuffer(&self.screenBuffer)
    }

    func handleKey(_ keyPress: KeyPress) -> Bool {
        guard let button = Self.keyMappings[keyPress.key] else {
            return false
        }

        cpu.handleButton(button: button, status: keyPress.phase != .up)
        return true
    }
}
