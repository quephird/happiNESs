//
//  happiNESsTests.swift
//  happiNESsTests
//
//  Created by Danielle Kefford on 6/14/24.
//

import XCTest
@testable import happiNESs

extension CPU {
    mutating func loadAndExecuteInstructions(program: [UInt8], stoppingAfter: Int) {
        self.load(program: program)
        self.reset()
        (0..<stoppingAfter).forEach { i in
            self.executeInstruction()
        }
    }
}

final class CPUTests: XCTestCase {
    func testAdcImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x50, 0x69, 0x50]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0xA0)
        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testAdcZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0xB0)
        let program: [UInt8] = [0xA9, 0xB0, 0x65, 0x42]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x60)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertTrue(cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testAdcZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0xB0)
        let program: [UInt8] = [0xA9, 0xB0, 0xA2, 0x20, 0x75, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x60)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertTrue(cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testAdcAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x7F)
        let program: [UInt8] = [0xA9, 0x81, 0x6D, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x00)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.overflow])
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testAdcAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x7F)
        let program: [UInt8] = [0xA9, 0x81, 0xA2, 0x34, 0x7D, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x00)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.overflow])
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testAdcAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x7F)
        let program: [UInt8] = [0xA9, 0x81, 0xA0, 0x34, 0x79, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x00)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.overflow])
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testAdcIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0xFF)
        let program: [UInt8] = [0xA9, 0xFF, 0xA2, 0x20, 0x61, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0xFE)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testAdcIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0xFF)
        let program: [UInt8] = [0xA9, 0xFF, 0xA0, 0x34, 0x71, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0xFE)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testAndImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x29, 0b0000_1111]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b0000_0000)
    }

    func testAndZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0b0101_0101)
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x25, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b0101_0000)
    }

    func testAndZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0b0101_0101)
        let program: [UInt8] = [0xA9, 0b1111_0000, 0xA2, 0x20, 0x35, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0101_0000)
    }

    func testAndAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0x2D, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAndAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x34, 0x3D, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAndAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x39, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAndIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x20, 0x21, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAndIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x31, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAslAccumulator() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x0A]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_1110)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testAslZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b1000_0000)
        let program: [UInt8] = [0x06, 0x42]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0000)
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testAslZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0100_0000)
        let program: [UInt8] = [0xA2, 0x21, 0x16, 0x21]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b1000_0000)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testAslAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0x0E, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0100)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testAslAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0xA2, 0x34, 0x1E, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0100)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testBcc() {
        var cpu = CPU()
        // NOTA BENE: This program loads the accumlator with the value 0x10,
        // then executes the `BCC` instrcution which checks if the carry bit is
        // zero, then jumps two bytes ahead to an `ADC` instruction which adds
        // 0x30 to the accumulator.
        let program: [UInt8] = [
            0xA9, 0x10,
            0x90, 0x02,
            0x69, 0x20,
            0x69, 0x30,
        ]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x40)
    }

    func testBcs() {
        var cpu = CPU()
        let program: [UInt8] = [
            0xA9, 0x01,
            0x69, 0xFF,
            0xB0, 0x02,
            0x69, 0x20,
            0x69, 0x41,
        ]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 4)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBeq() {
        var cpu = CPU()
        let program: [UInt8] = [
            0xA9, 0x00,
            0xF0, 0x02,
            0x69, 0x20,
            0x69, 0x42,
        ]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBitZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b1110_0101)
        let program: [UInt8] = [0xA9, 0b0001_1010, 0x24, 0x42]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.overflow])
    }

    func testBitAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b1101_1010, 0x2C, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.overflow])
    }

    func testBmi() {
        var cpu = CPU()
        let program: [UInt8] = [
            0xA9, 0xFF,
            0x30, 0x02,
            0xA9, 0x20,
            0xA9, 0x42,
        ]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBne() {
        var cpu = CPU()
        let program: [UInt8] = [
            0xA9, 0x21,
            0xD0, 0x02,
            0x69, 0xDE,
            0x69, 0x21,
        ]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBpl() {
        var cpu = CPU()
        let program: [UInt8] = [
            0xA9, 0x21,
            0x10, 0x02,
            0x69, 0xDE,
            0x69, 0x21,
        ]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBrk() {
        var cpu = CPU()
        // NOTA BENE: This program artificially sets flags in the status register
        // before the `BRK` instruction eventually pushes it onto the stack
        let program: [UInt8] = [0x38, 0xF8, 0x00]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 4)

        XCTAssertEqual(cpu.readByte(address: 0x01FF), 0x80)
        XCTAssertEqual(cpu.readByte(address: 0x01FE), 0x04)
        XCTAssertEqual(cpu.readByte(address: 0x01FD), 0b0000_1001)
        XCTAssertEqual(cpu.programCounter, 0x0000)
    }

    func testBvc() {
        var cpu = CPU()
        let program: [UInt8] = [
            0xA9, 0x21,
            0x69, 0x21,
            0x50, 0x02,
            0xA9, 0xFF,
            0x69, 0x00,
        ]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBvs() {
        var cpu = CPU()
        let program: [UInt8] = [
            0xA9, 0b0111_1111,
            0x69, 0b0000_0001,
            0x70, 0x02,
            0xA9, 0x00,
            0x69, 0x00,
        ]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1000_0000)
    }

    func testClc() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28, 0x18]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 4)

        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testCld() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28, 0xD8]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 4)

        XCTAssertTrue(!cpu.statusRegister[.decimalMode])
    }

    func testCli() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28, 0x58]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 4)

        XCTAssertTrue(!cpu.statusRegister[.interrupt])
    }

    func testClv() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28, 0xB8]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 4)

        XCTAssertTrue(!cpu.statusRegister[.overflow])
    }

    func testCmpImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0xC9, 0x43]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCmpZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x43)
        let program: [UInt8] = [0xA9, 0x42, 0xC5, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCmpZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x43)
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0xD5, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCmpAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x43)
        let program: [UInt8] = [0xA9, 0x42, 0xCD, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCmpAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x43)
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x34, 0xDD, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCmpAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x43)
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0xD9, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCmpIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x43)
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0xC1, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCmpIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x43)
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0xD1, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCpxImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA2, 0x42, 0xE0, 0x43]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCpxZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x43)
        let program: [UInt8] = [0xA2, 0x42, 0xE4, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCpxAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x43)
        let program: [UInt8] = [0xA2, 0x42, 0xEC, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCpyImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA0, 0x42, 0xC0, 0x43]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCpyZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x43)
        let program: [UInt8] = [0xA0, 0x42, 0xC4, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testCpyAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x43)
        let program: [UInt8] = [0xA0, 0x42, 0xCC, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testDecZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x10, byte: 0x55)
        let program: [UInt8] = [0xC6, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x10), 0x54)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testDecZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x30, byte: 0x00)
        let program: [UInt8] = [0xA2, 0x20, 0xD6, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x30), 0xFF)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testDecAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55)
        let program: [UInt8] = [0xCE, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x54)
    }

    func testDecAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55)
        let program: [UInt8] = [0xA2, 0x34, 0xDE, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x54)
    }

    func testDexOverflow() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x00, 0xAA, 0xCA]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.xRegister, 0xFF)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testDeyOverflow() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x00, 0xA8, 0x88]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.yRegister, 0xFF)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testEorImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x49, 0b0000_1111]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_1111)
    }

    func testEorZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0b0101_0101)
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x45, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1010_0101)
    }

    func testEorZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0b0101_0101)
        let program: [UInt8] = [0xA9, 0b1111_0000, 0xA2, 0x20, 0x55, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1010_0101)
    }

    func testEorAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0x4D, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testEorAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x34, 0x5D, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testEorAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x59, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testEorIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x20, 0x41, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testEorIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x51, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testIncZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x10, byte: 0x55)
        let program: [UInt8] = [0xE6, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x10), 0x56)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testIncZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x30, byte: 0xFF)
        let program: [UInt8] = [0xA2, 0x20, 0xF6, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x30), 0x00)
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testIncAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55)
        let program: [UInt8] = [0xEE, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x56)
    }

    func testIncAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55)
        let program: [UInt8] = [0xA2, 0x34, 0xFE, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x56)
    }

    func testInxOverflow() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0xAA, 0xE8]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.xRegister, 0x00)
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testInyOverflow() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0xA8, 0xC8]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.yRegister, 0x00)
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testJmpAbsolute() {
        // NOTA BENE: This little program sets the program counter
        // ahead of the LDA instruction such that the accumulator
        // gets initialized to 0x42 instead of 0xFF.
        var cpu = CPU()
        let program: [UInt8] = [0x4C, 0x05, 0x80, 0xA9, 0xFF, 0xA9, 0x42]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testJmpIndirect() {
        // NOTA BENE: This program does the same as the above, albeit
        // via indirect addressing.
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x05)
        cpu.writeByte(address: 0x1235, byte: 0x80)
        let program: [UInt8] = [0x6C, 0x34, 0x12, 0xA9, 0xFF, 0xA9, 0x42]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testJsr() {
        // NOTA BENE: This little program actually involves `JMP` and `RTS` instructions.
        // First, we jump to a subroutine to load the accumulator with 0xFF, then we return,
        // via `RTS`, to the point ahead of the `JSR` instruction which then `JMP`s to the
        // last byte of the program, which is a `NOP`
        var cpu = CPU()
        let program: [UInt8] = [0x20, 0x06, 0x80, 0x4C, 0x09, 0x80, 0xA9, 0xFF, 0x60, 0xEA]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 5)

        XCTAssertEqual(cpu.accumulator, 0xFF)
    }

    func testLdaImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x05]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.accumulator, 0x05)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testLdaZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x10, byte: 0x55)
        let program: [UInt8] = [0xA5, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x30, byte: 0xFF)
        let program: [UInt8] = [0xA2, 0x20, 0xB5, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0xFF)
    }

    func testLdaAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55)
        let program: [UInt8] = [0xAD, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55)
        let program: [UInt8] = [0xA2, 0x34, 0xBD, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55)
        let program: [UInt8] = [0xA0, 0x34, 0xB9, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.writeByte(address: 0x00FF, byte: 0x34)
        cpu.writeByte(address: 0x0000, byte: 0x12)
        let program: [UInt8] = [0xA2, 0x0F, 0xA1, 0xF0]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        let program: [UInt8] = [0xA0, 0x34, 0xB1, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaZeroFlag() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x00]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.accumulator, 0x00)
        XCTAssertTrue(cpu.statusRegister[.zero])
    }

    func testLdxImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA2, 0xF0]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.xRegister, 0xF0)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testLdxZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0xF0)
        let program: [UInt8] = [0xA6, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.xRegister, 0xF0)
    }

    func testLdxZeroPageY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x00FF, byte: 0xF0)
        let program: [UInt8] = [0xA0, 0xF0, 0xB6, 0x0F]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.xRegister, 0xF0)
    }

    func testLdxAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0xF0)
        let program: [UInt8] = [0xAE, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.xRegister, 0xF0)
    }

    func testLdxAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0xF0)
        let program: [UInt8] = [0xA0, 0x34, 0xBE, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.xRegister, 0xF0)
    }

    func testLdyImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA0, 0x00]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.yRegister, 0x00)
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testLdyZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0xF0)
        let program: [UInt8] = [0xA4, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.yRegister, 0xF0)
    }

    func testLdyZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x00FF, byte: 0xF0)
        let program: [UInt8] = [0xA2, 0xF0, 0xB4, 0x0F]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.yRegister, 0xF0)
    }

    func testLdyAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0xF0)
        let program: [UInt8] = [0xAC, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.yRegister, 0xF0)
    }

    func testLdyAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0xF0)
        let program: [UInt8] = [0xA2, 0x34, 0xBC, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.yRegister, 0xF0)
    }

    func testLsrAccumulator() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x4A]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b0111_1111)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testLsrZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0001)
        let program: [UInt8] = [0x46, 0x42]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0000)
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testLsrZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0010)
        let program: [UInt8] = [0xA2, 0x21, 0x56, 0x21]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0001)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testLsrAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0x4E, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testLsrAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0xA2, 0x34, 0x5E, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testOraImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x09, 0b0000_1111]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_1111)
    }

    func testOraZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0b0101_0101)
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x05, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0b0101_0101)
        let program: [UInt8] = [0xA9, 0b1111_0000, 0xA2, 0x20, 0x15, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0x0D, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x34, 0x1D, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x19, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x20, 0x01, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x11, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testPha() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0x48]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x01FF), 0x42)
        XCTAssertEqual(cpu.stackPointer, 0xFE)
    }

    func testPhp() {
        var cpu = CPU()
        // NOTA BENE: We can't directly manipulate the status register
        // so we do it imdirectly by loading the accumulator with a value
        // that affects it.
        let program: [UInt8] = [0xA9, 0xFF, 0x08]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(0b1000_0000, cpu.readByte(address: 0x01FF))
        XCTAssertEqual(cpu.stackPointer, 0xFE)
    }

    func testPla() {
        var cpu = CPU()
        // NOTA BENE: Although we can write directly to the area of memory
        // reserved for the stack, we would bypass the machinery guarding
        // the stack, and we don't want to load a value into the accumulator,
        // push it onto the stack, then pull it back out because that would
        // be circular and not prove much. So, instead we set the accumulator
        // to a value which will set flags in the status register, then
        // push the status register onto the stack, and then finally pop
        // the stack onto the accumulator with a _different_ value.
        let program: [UInt8] = [0xA9, 0xFF, 0x08, 0x68]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1000_0000)
        XCTAssertEqual(cpu.stackPointer, 0xFF)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testPlp() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.stackPointer, 0xFF)
        XCTAssertTrue(cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.overflow])
        XCTAssertTrue(cpu.statusRegister[.break])
        XCTAssertTrue(cpu.statusRegister[.interrupt])
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testRolAccumulator() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x2A]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_1111)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testRolZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0001)
        let program: [UInt8] = [0x26, 0x42]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0010)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testRolZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0010)
        let program: [UInt8] = [0xA2, 0x21, 0x36, 0x21]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0100)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testRolAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0x2E, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testRolAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0xA2, 0x34, 0x3E, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testRorAccumulator() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x6A]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_1111)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testRorZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0001)
        let program: [UInt8] = [0x66, 0x42]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b1000_0000)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testRorZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0010)
        let program: [UInt8] = [0xA2, 0x21, 0x76, 0x21]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0001)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testRorAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0x6E, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testRorAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0xA2, 0x34, 0x7E, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
        XCTAssertTrue(!cpu.statusRegister[.carry])
    }

    func testRti() {
        var cpu = CPU()
        // NOTA BENE: Wow, is this a hacky test. First I push the high and low
        // bytes of the memory location just after the end of this program, 0x800A,
        // onto the stack, then I push a fakey status byte onto the stack, and
        // finally I issue an `RTI` instruction which should pull everything off of
        // the stack.
        let program: [UInt8] = [
            0xA9, 0x80,
            0x48,
            0xA9, 0x0A,
            0x48,
            0xA9, 0x80,
            0x48,
            0x40]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 7)

        XCTAssertEqual(cpu.programCounter, 0x800A)
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testRts() {
        // NOTA BENE: This program is a little evil: the memory address of the
        // program that I want to return to after the RTS instruction is 0x8007,
        // which will load 0xFF into the accumulator. So... first I need to push
        // the high bits of that address (0x80) onto the stack through the accumulator,
        // then the low bits minus 1 (0x06) onto the stack. I wanted this test to be isolated
        // from the one for JSR.
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x80, 0x48, 0xA9, 0x06, 0x48, 0x60, 0xA9, 0xFF]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 6)

        XCTAssertEqual(cpu.accumulator, 0xFF)
    }

    func testSbcImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x32, 0xE9, 0x50]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0xE2)
        XCTAssertTrue(!cpu.statusRegister[.carry])
        XCTAssertTrue(cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testSbcZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0x20)
        let program: [UInt8] = [0xA9, 0x30, 0xE5, 0x42]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x10)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertFalse(cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testSbcZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x20)
        let program: [UInt8] = [0xA9, 0x30, 0xA2, 0x20, 0xF5, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x10)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertFalse(cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testSbcAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x20)
        let program: [UInt8] = [0xA9, 0x30, 0xED, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x10)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertFalse(cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testSbcAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x20)
        let program: [UInt8] = [0xA9, 0x30, 0xA2, 0x34, 0xFD, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x10)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertFalse(cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testSbcAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x20)
        let program: [UInt8] = [0xA9, 0x30, 0xA0, 0x34, 0xF9, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x10)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertFalse(cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testSbcIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x20)
        let program: [UInt8] = [0xA9, 0x30, 0xA2, 0x20, 0xE1, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x10)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testSbcIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x20)
        let program: [UInt8] = [0xA9, 0x30, 0xA0, 0x34, 0xF1, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x10)
        XCTAssertTrue(cpu.statusRegister[.carry])
        XCTAssertTrue(!cpu.statusRegister[.overflow])
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testSec() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x00, 0x48, 0x28, 0x38]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 4)

        XCTAssertTrue(cpu.statusRegister[.carry])
    }

    func testSed() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x00, 0x48, 0x28, 0xF8]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 4)

        XCTAssertTrue(cpu.statusRegister[.decimalMode])
    }

    func testSei() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x00, 0x48, 0x28, 0x78]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 4)

        XCTAssertTrue(cpu.statusRegister[.interrupt])
    }

    func testStaZeroPage() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0x85, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0010), 0x42)
    }

    func testStaZeroPageX() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0x95, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x0030), 0x42)
    }

    func testStaAbsolute() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0x8D, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStaAbsoluteX() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x34, 0x9D, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStaAbsoluteY() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0x99, 0x00, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStaIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0x81, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStaIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0x91, 0x30]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStxZeroPage() {
        var cpu = CPU()
        let program: [UInt8] = [0xA2, 0x42, 0x86, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0010), 0x42)
    }

    func testStxZeroPageY() {
        var cpu = CPU()
        let program: [UInt8] = [0xA2, 0x42, 0xA0, 0x20, 0x96, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x0030), 0x42)
    }

    func testStxAbsolute() {
        var cpu = CPU()
        let program: [UInt8] = [0xA2, 0x42, 0x8E, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStyZeroPage() {
        var cpu = CPU()
        let program: [UInt8] = [0xA0, 0x42, 0x84, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0010), 0x42)
    }

    func testStyZeroPageX() {
        var cpu = CPU()
        let program: [UInt8] = [0xA0, 0x42, 0xA2, 0x20, 0x94, 0x10]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x0030), 0x42)
    }

    func testStyAbsolute() {
        var cpu = CPU()
        let program: [UInt8] = [0xA0, 0x42, 0x8C, 0x34, 0x12]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testTax() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x0A, 0xAA]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.xRegister, 0x0A)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testTay() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0xA8]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.yRegister, 0xFF)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testTsx() {
        var cpu = CPU()
        // NOTA BENE: the stack pointer upon initialization is set to 0xFF
        let program: [UInt8] = [0xBA]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 1)

        XCTAssertEqual(cpu.xRegister, 0xFF)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testTxa() {
        var cpu = CPU()
        let program: [UInt8] = [0xA2, 0xFF, 0x8A]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0xFF)
        XCTAssertTrue(!cpu.statusRegister[.zero])
        XCTAssertTrue(cpu.statusRegister[.negative])
    }

    func testTxs() {
        var cpu = CPU()
        // NOTA BENE: the stack pointer upon initialization is set to 0xFF
        let program: [UInt8] = [0xA2, 0x00, 0x9A]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.stackPointer, 0x00)
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }

    func testTya() {
        var cpu = CPU()
        // NOTA BENE: the stack pointer upon initialization is set to 0xFF
        let program: [UInt8] = [0xA0, 0x00, 0x98]
        cpu.loadAndExecuteInstructions(program: program, stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x00)
        XCTAssertTrue(cpu.statusRegister[.zero])
        XCTAssertTrue(!cpu.statusRegister[.negative])
    }
}
