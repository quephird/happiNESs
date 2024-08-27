//
//  Joypad.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/27/24.
//

import SwiftUI

public struct Joypad {
    public static let keyMappings: [Character : JoypadButton] = [
        KeyEquivalent.upArrow.character : .up,
        KeyEquivalent.downArrow.character : .down,
        KeyEquivalent.leftArrow.character : .left,
        KeyEquivalent.rightArrow.character : .right,
        KeyEquivalent.space.character : .select,
        KeyEquivalent.return.character : .start,
        "a" : .buttonA,
        "s" : .buttonB,
    ]

    public var strobe: Bool
    public var buttonIndex: Int
    public var joypadButton: JoypadButton

    init() {
        self.strobe = false
        self.buttonIndex = 0
        self.joypadButton = JoypadButton()
    }
}

extension Joypad {
    public func readByteWithoutMutating() -> UInt8 {
        return (self.joypadButton.rawValue & (1 << self.buttonIndex)) >> self.buttonIndex
    }

    mutating public func readByte() -> UInt8 {
        if self.buttonIndex > 7 {
            return 1
        }

        let result = self.readByteWithoutMutating()
        if !self.strobe && self.buttonIndex <= 7 {
            self.buttonIndex += 1
        }

        return result
    }

    mutating public func writeByte(byte: UInt8) {
        self.strobe = (byte & 0b0000_0001) == 1

        if self.strobe {
            self.buttonIndex = 0
        }
    }

    mutating public func updateButtonStatus(button: JoypadButton, status: Bool) {
        self.joypadButton[button] = status
    }
}
