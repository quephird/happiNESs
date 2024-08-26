//
//  Console.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import happiNESs
import Observation
import SwiftUI

enum NESError: Error {
    case romCouldNotBeFound
    case romCouldNotBeRead
}

@Observable @MainActor class Console {
    static let frameRate = 60

    var displayTimer: Timer!

    // NOTA BENE: We don't want the screen updated every single time something inside
    // this class changes, which is the one being observed by `ContentView`. We're only
    // really interested in changes to `Console`'s state such that at least of the underlying
    // pixels has changed, namely any of the elements of  `screenBuffer`.
    @ObservationIgnored var cpu: CPU
    var screenBuffer: [NESColor] = PPU.makeEmptyScreenBuffer()

    internal init() throws {
        guard let filePath = Bundle.main.url(forResource: "pacman.nes", withExtension: nil) else {
            throw NESError.romCouldNotBeFound
        }

        let data: Data = try Data(contentsOf: filePath)
        let romBytes = [UInt8](data)
        guard let rom = Rom(bytes: romBytes) else {
            throw NESError.romCouldNotBeRead
        }

        let bus = Bus(rom: rom)
        var cpu = CPU(bus: bus, tracingOn: false)
        cpu.reset()
        self.cpu = cpu

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

    func keyDown(_ press: KeyPress) -> Bool {
        switch press.key {
        case .upArrow:
            cpu.buttonDown(button: .up)
        case .downArrow:
            cpu.buttonDown(button: .down)
        case .leftArrow:
            cpu.buttonDown(button: .left)
        case .rightArrow:
            cpu.buttonDown(button: .right)
        default:
            return false
        }

        return true
    }
}
