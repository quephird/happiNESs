//
//  Joypad.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/27/24.
//

public struct JoypadStatus {
    public var strobe: Bool
    public var buttonIndex: Int
    public var buttons: Register

    init() {
        self.strobe = false
        self.buttonIndex = 0
        self.buttons = 0x00
    }
}

extension JoypadStatus {
    public func readByteWithoutMutating() -> UInt8 {
        return (self.buttons >> self.buttonIndex) & 0b0000_0001
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

    mutating public func writeStrobe(strobe: Bool) {
        self.strobe = strobe

        if self.strobe {
            self.buttonIndex = 0
        }
    }

    mutating public func updateButtonStatus(button: RegisterBit, status: Bool) {
        self.buttons[button] = status
    }
}
