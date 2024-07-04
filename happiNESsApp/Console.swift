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
    static let clockRate = 14_000

    var displayLink: Timer!

    // NOTA BENE: Only the screenBuffer is actually ever changing (for now)
    @ObservationIgnored var cpu: CPU = CPU()
    var screenBuffer: [NESColor] = [NESColor](repeating: .black, count: 32*32)

    internal init() {
        cpu.load(program: CPU.gameCode)
        cpu.reset()
        displayLink = Timer.scheduledTimer(timeInterval: 1.0/TimeInterval(Self.frameRate), target: self, selector: #selector(runForOneFrame), userInfo: nil, repeats: true)
    }

    @objc func runForOneFrame() {
        cpu.writeByte(address: 0x00FE, byte: UInt8.random(in: 1..<16))
        cpu.executeInstructions(stoppingAfter: Self.clockRate / Self.frameRate)
        self.screenBuffer = cpu.makeScreenBuffer()
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
