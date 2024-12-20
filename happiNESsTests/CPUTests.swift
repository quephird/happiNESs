//
//  happiNESsTests.swift
//  happiNESsTests
//
//  Created by Danielle Kefford on 6/14/24.
//

import XCTest
import happiNESs

final class CPUTests: XCTestCase {
    func testAdcImmediate() {
        let program: [UInt8] = [0xA9, 0x50, 0x69, 0x50]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0xA0)
        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testAdcZeroPage() {
        let program: [UInt8] = [0xA9, 0xB0, 0x65, 0x42]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0xB0)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x60)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertTrue(cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testAdcZeroPageX() {
        let program: [UInt8] = [0xA9, 0xB0, 0xA2, 0x20, 0x75, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0xB0)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x60)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertTrue(cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testAdcAbsolute() {
        let program: [UInt8] = [0xA9, 0x81, 0x6D, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x7F)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x00)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.overflow])
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testAdcAbsoluteX() {
        let program: [UInt8] = [0xA9, 0x81, 0xA2, 0x34, 0x7D, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x7F)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x00)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.overflow])
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testAdcAbsoluteY() {
        let program: [UInt8] = [0xA9, 0x81, 0xA0, 0x34, 0x79, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x7F)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x00)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.overflow])
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testAdcIndirectX() {
        let program: [UInt8] = [0xA9, 0xFF, 0xA2, 0x20, 0x61, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0xFF)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0xFE)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testAdcIndirectY() {
        let program: [UInt8] = [0xA9, 0xFF, 0xA0, 0x34, 0x71, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0xFF)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0xFE)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testAndImmediate() {
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x29, 0b0000_1111]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b0000_0000)
    }

    func testAndZeroPage() {
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x25, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0010, byte: 0b0101_0101)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b0101_0000)
    }

    func testAndZeroPageX() {
        let program: [UInt8] = [0xA9, 0b1111_0000, 0xA2, 0x20, 0x35, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0b0101_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0101_0000)
    }

    func testAndAbsolute() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0x2D, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAndAbsoluteX() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x34, 0x3D, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAndAbsoluteY() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x39, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAndIndirectX() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x20, 0x21, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAndIndirectY() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x31, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b0000_0101)
    }

    func testAslAccumulator() {
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x0A]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_1110)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testAslZeroPage() {
        let program: [UInt8] = [0x06, 0x42]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0b1000_0000)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0000)
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testAslZeroPageX() {
        let program: [UInt8] = [0xA2, 0x21, 0x16, 0x21]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0b0100_0000)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b1000_0000)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

    func testAslAbsolute() {
        let program: [UInt8] = [0x0E, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0100)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testAslAbsoluteX() {
        let program: [UInt8] = [0xA2, 0x34, 0x1E, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0100)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testBcc() {
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
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x40)
    }

    func testBcs() {
        let program: [UInt8] = [
            0xA9, 0x01,
            0x69, 0xFF,
            0xB0, 0x02,
            0x69, 0x20,
            0x69, 0x41,
        ]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 4)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBeq() {
        let program: [UInt8] = [
            0xA9, 0x00,
            0xF0, 0x02,
            0x69, 0x20,
            0x69, 0x42,
        ]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBitZeroPage() {
        let program: [UInt8] = [0xA9, 0b0001_1010, 0x24, 0x42]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0b1110_0101)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
        XCTAssertTrue(cpu.status[.overflow])
    }

    func testBitAbsolute() {
        let program: [UInt8] = [0xA9, 0b1101_1010, 0x2C, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.overflow])
    }

    func testBmi() {
        let program: [UInt8] = [
            0xA9, 0xFF,
            0x30, 0x02,
            0xA9, 0x20,
            0xA9, 0x42,
        ]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBne() {
        let program: [UInt8] = [
            0xA9, 0x21,
            0xD0, 0x02,
            0x69, 0xDE,
            0x69, 0x21,
        ]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBpl() {
        let program: [UInt8] = [
            0xA9, 0x21,
            0x10, 0x02,
            0x69, 0xDE,
            0x69, 0x21,
        ]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBrk() {
        // NOTA BENE: This program artificially sets flags in the status register
        // before the `BRK` instruction eventually pushes it onto the stack
        let program: [UInt8] = [0x38, 0xF8, 0x00]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x01FD), 0x86)
        XCTAssertEqual(cpu.readByte(address: 0x01FC), 0x04)
        XCTAssertEqual(cpu.readByte(address: 0x01FB), 0b0011_1101)
        XCTAssertEqual(cpu.programCounter, 0x0000)
    }

    func testBvc() {
        let program: [UInt8] = [
            0xA9, 0x21,
            0x69, 0x21,
            0x50, 0x02,
            0xA9, 0xFF,
            0x69, 0x00,
        ]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testBvs() {
        let program: [UInt8] = [
            0xA9, 0b0111_1111,
            0x69, 0b0000_0001,
            0x70, 0x02,
            0xA9, 0x00,
            0x69, 0x00,
        ]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1000_0000)
    }

    func testClc() {
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28, 0x18]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 4)

        XCTAssertTrue(!cpu.status[.carry])
    }

    func testCld() {
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28, 0xD8]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 4)

        XCTAssertTrue(!cpu.status[.decimalMode])
    }

    func testCli() {
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28, 0x58]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 4)

        XCTAssertTrue(!cpu.status[.interruptsDisabled])
    }

    func testClv() {
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28, 0xB8]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 4)

        XCTAssertTrue(!cpu.status[.overflow])
    }

    func testCmpImmediate() {
        let program: [UInt8] = [0xA9, 0x42, 0xC9, 0x43]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCmpZeroPage() {
        let program: [UInt8] = [0xA9, 0x42, 0xC5, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCmpZeroPageX() {
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0xD5, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCmpAbsolute() {
        let program: [UInt8] = [0xA9, 0x42, 0xCD, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCmpAbsoluteX() {
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x34, 0xDD, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCmpAbsoluteY() {
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0xD9, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCmpIndirectX() {
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0xC1, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCmpIndirectY() {
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0xD1, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCpxImmediate() {
        let program: [UInt8] = [0xA2, 0x42, 0xE0, 0x43]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCpxZeroPage() {
        let program: [UInt8] = [0xA2, 0x42, 0xE4, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCpxAbsolute() {
        let program: [UInt8] = [0xA2, 0x42, 0xEC, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCpyImmediate() {
        let program: [UInt8] = [0xA0, 0x42, 0xC0, 0x43]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCpyZeroPage() {
        let program: [UInt8] = [0xA0, 0x42, 0xC4, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testCpyAbsolute() {
        let program: [UInt8] = [0xA0, 0x42, 0xCC, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x43)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testDecZeroPage() {
        let program: [UInt8] = [0xC6, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x10, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x10), 0x54)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testDecZeroPageX() {
        let program: [UInt8] = [0xA2, 0x20, 0xD6, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x30, byte: 0x00)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x30), 0xFF)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testDecAbsolute() {
        let program: [UInt8] = [0xCE, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x54)
    }

    func testDecAbsoluteX() {
        let program: [UInt8] = [0xA2, 0x34, 0xDE, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x54)
    }

    func testDexOverflow() {
        let program: [UInt8] = [0xA9, 0x00, 0xAA, 0xCA]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.xRegister, 0xFF)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testDeyOverflow() {
        let program: [UInt8] = [0xA9, 0x00, 0xA8, 0x88]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.yRegister, 0xFF)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testEorImmediate() {
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x49, 0b0000_1111]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_1111)
    }

    func testEorZeroPage() {
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x45, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0010, byte: 0b0101_0101)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1010_0101)
    }

    func testEorZeroPageX() {
        let program: [UInt8] = [0xA9, 0b1111_0000, 0xA2, 0x20, 0x55, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0b0101_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1010_0101)
    }

    func testEorAbsolute() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0x4D, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testEorAbsoluteX() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x34, 0x5D, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testEorAbsoluteY() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x59, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testEorIndirectX() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x20, 0x41, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testEorIndirectY() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x51, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0000)
    }

    func testIncZeroPage() {
        let program: [UInt8] = [0xE6, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x10, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x10), 0x56)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testIncZeroPageX() {
        let program: [UInt8] = [0xA2, 0x20, 0xF6, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x30, byte: 0xFF)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x30), 0x00)
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testIncAbsolute() {
        let program: [UInt8] = [0xEE, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x56)
    }

    func testIncAbsoluteX() {
        let program: [UInt8] = [0xA2, 0x34, 0xFE, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x56)
    }

    func testInxOverflow() {
        let program: [UInt8] = [0xA9, 0xFF, 0xAA, 0xE8]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.xRegister, 0x00)
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testInyOverflow() {
        let program: [UInt8] = [0xA9, 0xFF, 0xA8, 0xC8]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.yRegister, 0x00)
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testJmpAbsolute() {
        // NOTA BENE: This little program sets the program counter
        // ahead of the LDA instruction such that the accumulator
        // gets initialized to 0x42 instead of 0xFF.
        let program: [UInt8] = [
            0x4C, 0x05, 0x86,
            0xA9, 0xFF,
            0xA9, 0x42
        ]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testJmpIndirect() {
        // NOTA BENE: This program does the same as the above, albeit
        // via indirect addressing.
        let program: [UInt8] = [0x6C, 0x34, 0x12, 0xA9, 0xFF, 0xA9, 0x42]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x05)
        cpu.writeByte(address: 0x1235, byte: 0x86)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x42)
    }

    func testJsr() {
        // NOTA BENE: This little program actually involves `JMP` and `RTS` instructions.
        // First, we jump to a subroutine to load the accumulator with 0xFF, then we return,
        // via `RTS`, to the point ahead of the `JSR` instruction which then `JMP`s to the
        // last byte of the program, which is a `NOP`
        let program: [UInt8] = [
            0x20, 0x06, 0x86,
            0x4C, 0x09, 0x86,
            0xA9, 0xFF,
            0x60,
            0xEA
        ]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 5)

        XCTAssertEqual(cpu.accumulator, 0xFF)
    }

    func testLdaImmediate() {
        let program: [UInt8] = [0xA9, 0x05]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.accumulator, 0x05)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testLdaZeroPage() {
        let program: [UInt8] = [0xA5, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x10, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaZeroPageX() {
        let program: [UInt8] = [0xA2, 0x20, 0xB5, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x30, byte: 0xFF)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0xFF)
    }

    func testLdaAbsolute() {
        let program: [UInt8] = [0xAD, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaAbsoluteX() {
        let program: [UInt8] = [0xA2, 0x34, 0xBD, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaAbsoluteY() {
        let program: [UInt8] = [0xA0, 0x34, 0xB9, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaIndirectX() {
        let program: [UInt8] = [0xA2, 0x0F, 0xA1, 0xF0]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.writeByte(address: 0x00FF, byte: 0x34)
        cpu.writeByte(address: 0x0000, byte: 0x12)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdaIndirectY() {
        let program: [UInt8] = [0xA0, 0x34, 0xB1, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x55)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x55)
    }

    func testLdxImmediate() {
        let program: [UInt8] = [0xA2, 0xF0]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.xRegister, 0xF0)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testLdxZeroPage() {
        let program: [UInt8] = [0xA6, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0010, byte: 0xF0)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.xRegister, 0xF0)
    }

    func testLdxZeroPageY() {
        let program: [UInt8] = [0xA0, 0xF0, 0xB6, 0x0F]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x00FF, byte: 0xF0)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.xRegister, 0xF0)
    }

    func testLdxAbsolute() {
        let program: [UInt8] = [0xAE, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0xF0)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.xRegister, 0xF0)
    }

    func testLdxAbsoluteY() {
        let program: [UInt8] = [0xA0, 0x34, 0xBE, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0xF0)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.xRegister, 0xF0)
    }

    func testLdyImmediate() {
        let program: [UInt8] = [0xA0, 0x00]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.yRegister, 0x00)
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testLdyZeroPage() {
        let program: [UInt8] = [0xA4, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0010, byte: 0xF0)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.yRegister, 0xF0)
    }

    func testLdyZeroPageX() {
        let program: [UInt8] = [0xA2, 0xF0, 0xB4, 0x0F]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x00FF, byte: 0xF0)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.yRegister, 0xF0)
    }

    func testLdyAbsolute() {
        let program: [UInt8] = [0xAC, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0xF0)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.yRegister, 0xF0)
    }

    func testLdyAbsoluteX() {
        let program: [UInt8] = [0xA2, 0x34, 0xBC, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0xF0)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.yRegister, 0xF0)
    }

    func testLsrAccumulator() {
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x4A]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b0111_1111)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testLsrZeroPage() {
        let program: [UInt8] = [0x46, 0x42]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0b0000_0001)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0000)
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testLsrZeroPageX() {
        let program: [UInt8] = [0xA2, 0x21, 0x56, 0x21]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0b0000_0010)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0001)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

    func testLsrAbsolute() {
        let program: [UInt8] = [0x4E, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

    func testLsrAbsoluteX() {
        let program: [UInt8] = [0xA2, 0x34, 0x5E, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

    func testOraImmediate() {
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x09, 0b0000_1111]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_1111)
    }

    func testOraZeroPage() {
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x05, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0010, byte: 0b0101_0101)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraZeroPageX() {
        let program: [UInt8] = [0xA9, 0b1111_0000, 0xA2, 0x20, 0x15, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0b0101_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraAbsolute() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0x0D, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraAbsoluteX() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x34, 0x1D, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraAbsoluteY() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x19, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraIndirectX() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x20, 0x01, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testOraIndirectY() {
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x11, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1111_0101)
    }

    func testPha() {
        let program: [UInt8] = [0xA9, 0x42, 0x48]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x01FD), 0x42)
        XCTAssertEqual(cpu.stackPointer, 0xFC)
    }

    func testPhp() {
        // NOTA BENE: We can't directly manipulate the status register
        // so we do it imdirectly by loading the accumulator with a value
        // that affects it.
        let program: [UInt8] = [0xA9, 0xFF, 0x08]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(0b1011_0100, cpu.readByte(address: 0x01FD))
        XCTAssertEqual(cpu.stackPointer, 0xFC)
    }

    func testPla() {
        // NOTA BENE: Although we can write directly to the area of memory
        // reserved for the stack, we would bypass the machinery guarding
        // the stack, and we don't want to load a value into the accumulator,
        // push it onto the stack, then pull it back out because that would
        // be circular and not prove much. So, instead we set the accumulator
        // to a value which will set flags in the status register, then
        // push the status register onto the stack, and then finally pop
        // the stack onto the accumulator with a _different_ value.
        let program: [UInt8] = [0xA9, 0xFF, 0x08, 0x68]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0b1011_0100)
        XCTAssertEqual(cpu.stackPointer, 0xFD)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

    func testPlp() {
        let program: [UInt8] = [0xA9, 0xFF, 0x48, 0x28]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.stackPointer, 0xFD)
        XCTAssertTrue(cpu.status[.negative])
        XCTAssertTrue(cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.break])
        XCTAssertTrue(cpu.status[.interruptsDisabled])
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testRolAccumulator() {
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x2A]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b1111_1110)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testRolZeroPage() {
        let program: [UInt8] = [0x26, 0x42]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0b0000_0001)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0010)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

    func testRolZeroPageX() {
        let program: [UInt8] = [0xA2, 0x21, 0x36, 0x21]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0b0000_0010)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0100)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

    func testRolAbsolute() {
        let program: [UInt8] = [0x2E, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0100)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testRolAbsoluteX() {
        let program: [UInt8] = [0xA2, 0x34, 0x3E, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0100)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testRorAccumulator() {
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x6A]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0b0111_1111)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testRorZeroPage() {
        let program: [UInt8] = [0x66, 0x42]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0b1000_0001)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0100_0000)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(cpu.status[.carry])
    }

    func testRorZeroPageX() {
        let program: [UInt8] = [0xA2, 0x21, 0x76, 0x21]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0b0000_0010)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0001)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

    func testRorAbsolute() {
        let program: [UInt8] = [0x6E, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

    func testRorAbsoluteX() {
        let program: [UInt8] = [0xA2, 0x34, 0x7E, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
        XCTAssertTrue(!cpu.status[.carry])
    }

//    func testRti() {
//        let cpu = makeCpu(programBytes: program)
//        // NOTA BENE: Wow, is this a hacky test. First I push the high and low
//        // bytes of the memory location just after the end of this program, 0x800A,
//        // onto the stack, then I push a fakey status byte onto the stack, and
//        // finally I issue an `RTI` instruction which should pull everything off of
//        // the stack.
//        let program: [UInt8] = [
//            0xA9, 0x80,
//            0x48,
//            0xA9, 0x0A,
//            0x48,
//            0xA9, 0x80,
//            0x48,
//            0x40]
//        cpu.executeInstructions(stoppingAfter: 7)
//
//        XCTAssertEqual(cpu.programCounter, 0x800A)
//        XCTAssertTrue(cpu.statusRegister[.negative])
//    }
//
//    func testRts() {
//        // NOTA BENE: This program is a little evil: the memory address of the
//        // program that I want to return to after the RTS instruction is 0x0607,
//        // which will load 0xFF into the accumulator. So... first I need to push
//        // the high bits of that address (0x06) onto the stack through the accumulator,
//        // then the low bits minus 1 (0x06) onto the stack. I wanted this test to be isolated
//        // from the one for JSR.
//        let cpu = makeCpu(programBytes: program)
//        let program: [UInt8] = [
//            0xA9, 0x06,
//            0x48,
//            0xA9, 0x06,
//            0x48,
//            0x60,
//            0xA9, 0xFF
//        ]
//        cpu.executeInstructions(stoppingAfter: 6)
//
//        XCTAssertEqual(cpu.accumulator, 0xFF)
//    }

    func testSbcImmediate() {
        let program: [UInt8] = [0xA9, 0x32, 0xE9, 0x50]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0xE1)
        XCTAssertTrue(!cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testSbcZeroPage() {
        let program: [UInt8] = [0xA9, 0x30, 0xE5, 0x42]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0042, byte: 0x20)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x0F)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertFalse(cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testSbcZeroPageX() {
        let program: [UInt8] = [0xA9, 0x30, 0xA2, 0x20, 0xF5, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x20)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x0F)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertFalse(cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testSbcAbsolute() {
        let program: [UInt8] = [0xA9, 0x30, 0xED, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x20)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x0F)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertFalse(cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testSbcAbsoluteX() {
        let program: [UInt8] = [0xA9, 0x30, 0xA2, 0x34, 0xFD, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x20)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x0F)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertFalse(cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testSbcAbsoluteY() {
        let program: [UInt8] = [0xA9, 0x30, 0xA0, 0x34, 0xF9, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x1234, byte: 0x20)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x0F)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertFalse(cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testSbcIndirectX() {
        let program: [UInt8] = [0xA9, 0x30, 0xA2, 0x20, 0xE1, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x20)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x0F)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testSbcIndirectY() {
        let program: [UInt8] = [0xA9, 0x30, 0xA0, 0x34, 0xF1, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.writeByte(address: 0x1234, byte: 0x20)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.accumulator, 0x0F)
        XCTAssertTrue(cpu.status[.carry])
        XCTAssertTrue(!cpu.status[.overflow])
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testSec() {
        let program: [UInt8] = [0xA9, 0x00, 0x48, 0x28, 0x38]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 4)

        XCTAssertTrue(cpu.status[.carry])
    }

    func testSed() {
        let program: [UInt8] = [0xA9, 0x00, 0x48, 0x28, 0xF8]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 4)

        XCTAssertTrue(cpu.status[.decimalMode])
    }

    func testSei() {
        let program: [UInt8] = [0xA9, 0x00, 0x48, 0x28, 0x78]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 4)

        XCTAssertTrue(cpu.status[.interruptsDisabled])
    }

    func testStaZeroPage() {
        let program: [UInt8] = [0xA9, 0x42, 0x85, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0010), 0x42)
    }

    func testStaZeroPageX() {
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0x95, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x0030), 0x42)
    }

    func testStaAbsolute() {
        let program: [UInt8] = [0xA9, 0x42, 0x8D, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStaAbsoluteX() {
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x34, 0x9D, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStaAbsoluteY() {
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0x99, 0x00, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStaIndirectX() {
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0x81, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x34)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStaIndirectY() {
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0x91, 0x30]
        let cpu = makeCpu(programBytes: program)
        cpu.writeByte(address: 0x0030, byte: 0x00)
        cpu.writeByte(address: 0x0031, byte: 0x12)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStxZeroPage() {
        let program: [UInt8] = [0xA2, 0x42, 0x86, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0010), 0x42)
    }

    func testStxZeroPageY() {
        let program: [UInt8] = [0xA2, 0x42, 0xA0, 0x20, 0x96, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x0030), 0x42)
    }

    func testStxAbsolute() {
        let program: [UInt8] = [0xA2, 0x42, 0x8E, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testStyZeroPage() {
        let program: [UInt8] = [0xA0, 0x42, 0x84, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x0010), 0x42)
    }

    func testStyZeroPageX() {
        let program: [UInt8] = [0xA0, 0x42, 0xA2, 0x20, 0x94, 0x10]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 3)

        XCTAssertEqual(cpu.readByte(address: 0x0030), 0x42)
    }

    func testStyAbsolute() {
        let program: [UInt8] = [0xA0, 0x42, 0x8C, 0x34, 0x12]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42)
    }

    func testTax() {
        let program: [UInt8] = [0xA9, 0x0A, 0xAA]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.xRegister, 0x0A)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testTay() {
        let program: [UInt8] = [0xA9, 0xFF, 0xA8]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.yRegister, 0xFF)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testTsx() {
        // NOTA BENE: the stack pointer upon initialization is set to 0xFD
        let program: [UInt8] = [0xBA]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 1)

        XCTAssertEqual(cpu.xRegister, 0xFD)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testTxa() {
        let program: [UInt8] = [0xA2, 0xFF, 0x8A]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0xFF)
        XCTAssertTrue(!cpu.status[.zero])
        XCTAssertTrue(cpu.status[.negative])
    }

    func testTxs() {
        // NOTA BENE: the stack pointer upon initialization is set to 0xFF
        let program: [UInt8] = [0xA2, 0x00, 0x9A]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.stackPointer, 0x00)
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }

    func testTya() {
        // NOTA BENE: the stack pointer upon initialization is set to 0xFF
        let program: [UInt8] = [0xA0, 0x00, 0x98]
        let cpu = makeCpu(programBytes: program)
        cpu.executeInstructions(stoppingAfter: 2)

        XCTAssertEqual(cpu.accumulator, 0x00)
        XCTAssertTrue(cpu.status[.zero])
        XCTAssertTrue(!cpu.status[.negative])
    }
}
