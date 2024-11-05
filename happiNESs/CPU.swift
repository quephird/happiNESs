//
//  CPU.swift
//  happiNESs
//
//  Created by Danielle Kefford on 6/14/24.
//

public class CPU {
    static let frequency = 1789773.0

    static let nmiVectorAddress: UInt16 = 0xFFFA
    static let resetVectorAddress: UInt16 = 0xFFFC
    static let interruptVectorAddress: UInt16 = 0xFFFE
    // TODO: Need to look into why the stack pointer starts here and not at 0xFF!!!
    static let resetStackPointerValue: UInt8 = 0xFD
    static let stackBottomMemoryAddress: UInt16 = 0x0100

    public var accumulator: UInt8
    public var statusRegister: StatusRegister
    public var xRegister: UInt8
    public var yRegister: UInt8
    public var stackPointer: UInt8
    public var programCounter: UInt16
    public var bus: Bus
    public var interrupt: Interrupt = .none
    public var stall: Int = 0

    public var tracingOn: Bool

    public init(bus: Bus, tracingOn: Bool = false) {
        self.bus = bus
        self.accumulator = 0x00
        self.statusRegister = StatusRegister(rawValue: 0x00)
        self.xRegister = 0x00
        self.yRegister = 0x00
        self.stackPointer = Self.resetStackPointerValue
        self.programCounter = 0x0000
        self.tracingOn = tracingOn

        self.bus.cpu = self
    }

    public func loadCartridge(cartridge: Cartridge) {
        self.bus.loadCartridge(cartridge: cartridge)
    }

    public func reset() {
        self.accumulator = 0x00;
        self.statusRegister.reset();
        self.xRegister = 0x00;
        self.yRegister = 0x00;
        self.stackPointer = Self.resetStackPointerValue
        self.programCounter = self.readWord(address: Self.resetVectorAddress)
        self.interrupt = .none
        self.stall = 0

        self.bus.reset()
        // TODO: Look more deeply into whether or not this is the best strategy
        // for simulating the initial number of CPU cycles when resetting the CPU
        let _ = self.bus.tick(cycles: 7)
    }

    public func handleButton(button: JoypadButton, status: Bool) {
        self.bus.joypad.updateButtonStatus(button: button, status: status)
    }

    public func handleNmi() {
        self.pushStack(word: self.programCounter)

        var copy = self.statusRegister
        copy[.break] = false
        copy[.unused] = true

        self.pushStack(byte: copy.rawValue)
        self.statusRegister[.interruptsDisabled] = true

        self.programCounter = self.readWord(address: Self.nmiVectorAddress)
        let _ = self.bus.tick(cycles: 7)
    }

    public func handleIrq() {
        self.pushStack(word: self.programCounter)

        var copy = self.statusRegister
        copy[.break] = false
        copy[.unused] = true

        self.pushStack(byte: copy.rawValue)
        self.statusRegister[.interruptsDisabled] = true

        self.programCounter = self.readWord(address: Self.interruptVectorAddress)
        let _ = self.bus.tick(cycles: 7)
    }
}
