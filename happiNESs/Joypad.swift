//
//  Joypad.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/27/24.
//

public struct Joypad {
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
        return (self.joypadButton.rawValue >> self.buttonIndex) & 0b0000_0001
    }

    mutating public func readByte() -> UInt8 {
        defer {
            self.buttonIndex = self.buttonIndex &+ 1

            if self.strobe {
                self.buttonIndex = 0
            }
        }

        guard self.buttonIndex < 8 else {
            return 0
        }

        return self.readByteWithoutMutating()
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
