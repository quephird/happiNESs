//
//  happiNESsTests.swift
//  happiNESsTests
//
//  Created by Danielle Kefford on 6/14/24.
//

import XCTest
@testable import happiNESs

final class CPUTests: XCTestCase {
    func testAndImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x29, 0b0000_1111, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b0000_0000);
    }

    func testAndZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0b0101_0101);
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x25, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b0101_0000);
    }

    func testAndZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0b0101_0101);
        let program: [UInt8] = [0xA9, 0b1111_0000, 0xA2, 0x20, 0x35, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b0101_0000);
    }

    func testAndAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0x2D, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b0000_0101);
    }

    func testAndAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x34, 0x3D, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b0000_0101);
    }

    func testAndAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x39, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b0000_0101);
    }

    func testAndIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        cpu.writeByte(address: 0x0030, byte: 0x34);
        cpu.writeByte(address: 0x0031, byte: 0x12);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x20, 0x21, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b0000_0101);
    }

    func testAndIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00);
        cpu.writeByte(address: 0x0031, byte: 0x12);
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x31, 0x30, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b0000_0101);
    }

    func testAslAccumulator() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x0A, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_1110);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testAslZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b1000_0000)
        let program: [UInt8] = [0x06, 0x42, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0000);
        XCTAssertTrue(cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testAslZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0100_0000)
        let program: [UInt8] = [0xA2, 0x21, 0x16, 0x21, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b1000_0000);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(cpu.statusRegister[.negative]);
        XCTAssertTrue(!cpu.statusRegister[.carry]);
    }

    func testAslAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0x0E, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0100);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testAslAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0xA2, 0x34, 0x1E, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0100);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testEorImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x49, 0b0000_1111, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_1111);
    }

    func testEorZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0b0101_0101);
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x45, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1010_0101);
    }

    func testEorZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0b0101_0101);
        let program: [UInt8] = [0xA9, 0b1111_0000, 0xA2, 0x20, 0x55, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1010_0101);
    }

    func testEorAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0x4D, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0000);
    }

    func testEorAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x34, 0x5D, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0000);
    }

    func testEorAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x59, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0000);
    }

    func testEorIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        cpu.writeByte(address: 0x0030, byte: 0x34);
        cpu.writeByte(address: 0x0031, byte: 0x12);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x20, 0x41, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0000);
    }

    func testEorIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00);
        cpu.writeByte(address: 0x0031, byte: 0x12);
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x51, 0x30, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0000);
    }

    func testInxOverflow() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0xAA, 0xE8, 0xE8, 0x00]
        cpu.loadAndRun(program: program)

        XCTAssertEqual(cpu.xRegister, 0x01)
    }

    func testLdaImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x05, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0x05);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
    }

    func testLdaZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x10, byte: 0x55);
        let program: [UInt8] = [0xA5, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0x55);
    }

    func testLdaZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x30, byte: 0xFF);
        let program: [UInt8] = [0xA2, 0x20, 0xB5, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0xFF);
    }

    func testLdaAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55);
        let program: [UInt8] = [0xAD, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0x55);
    }

    func testLdaAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55);
        let program: [UInt8] = [0xA2, 0x34, 0xBD, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0x55);
    }

    func testLdaAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55);
        let program: [UInt8] = [0xA0, 0x34, 0xB9, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0x55);
    }

    func testLdaIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0x55);
        cpu.writeByte(address: 0x00FF, byte: 0x34);
        cpu.writeByte(address: 0x0000, byte: 0x12);
        let program: [UInt8] = [0xA2, 0x0F, 0xA1, 0xF0, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0x55);
    }

    func testLdaIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00);
        cpu.writeByte(address: 0x0031, byte: 0x12);
        cpu.writeByte(address: 0x1234, byte: 0x55);
        let program: [UInt8] = [0xA0, 0x34, 0xB1, 0x30, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0x55);
    }

    func testLdaZeroFlag() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x00, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0x00);
        XCTAssertTrue(cpu.statusRegister[.zero]);
    }

    func testLdxImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA2, 0xF0, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.xRegister, 0xF0);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(cpu.statusRegister[.negative]);
    }

    func testLdxZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0xF0);
        let program: [UInt8] = [0xA6, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.xRegister, 0xF0);
    }

    func testLdxZeroPageY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x00FF, byte: 0xF0);
        let program: [UInt8] = [0xA0, 0xF0, 0xB6, 0x0F, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.xRegister, 0xF0);
    }

    func testLdxAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0xF0);
        let program: [UInt8] = [0xAE, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.xRegister, 0xF0);
    }

    func testLdxAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0xF0);
        let program: [UInt8] = [0xA0, 0x34, 0xBE, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.xRegister, 0xF0);
    }

    func testLdyImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA0, 0x00, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.yRegister, 0x00);
        XCTAssertTrue(cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
    }

    func testLdyZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0xF0);
        let program: [UInt8] = [0xA4, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.yRegister, 0xF0);
    }

    func testLdyZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x00FF, byte: 0xF0);
        let program: [UInt8] = [0xA2, 0xF0, 0xB4, 0x0F, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.yRegister, 0xF0);
    }

    func testLdyAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0xF0);
        let program: [UInt8] = [0xAC, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.yRegister, 0xF0);
    }

    func testLdyAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0xF0);
        let program: [UInt8] = [0xA2, 0x34, 0xBC, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.yRegister, 0xF0);
    }

    func testLsrAccumulator() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x4A, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b0111_1111);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testLsrZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0001)
        let program: [UInt8] = [0x46, 0x42, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0000);
        XCTAssertTrue(cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testLsrZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0010)
        let program: [UInt8] = [0xA2, 0x21, 0x56, 0x21, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0001);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(!cpu.statusRegister[.carry]);
    }

    func testLsrAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0x4E, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(!cpu.statusRegister[.carry]);
    }

    func testLsrAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0xA2, 0x34, 0x5E, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(!cpu.statusRegister[.carry]);
    }

    func testOraImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x09, 0b0000_1111, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_1111);
    }

    func testOraZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0010, byte: 0b0101_0101);
        let program: [UInt8] = [0xA9, 0b1111_0000, 0x05, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0101);
    }

    func testOraZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0b0101_0101);
        let program: [UInt8] = [0xA9, 0b1111_0000, 0xA2, 0x20, 0x15, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0101);
    }

    func testOraAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0x0D, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0101);
    }

    func testOraAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x34, 0x1D, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0101);
    }

    func testOraAbsoluteY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x19, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0101);
    }

    func testOraIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        cpu.writeByte(address: 0x0030, byte: 0x34);
        cpu.writeByte(address: 0x0031, byte: 0x12);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA2, 0x20, 0x01, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0101);
    }

    func testOraIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00);
        cpu.writeByte(address: 0x0031, byte: 0x12);
        cpu.writeByte(address: 0x1234, byte: 0b1010_0101);
        let program: [UInt8] = [0xA9, 0b0101_0101, 0xA0, 0x34, 0x11, 0x30, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_0101);
    }

    func testRolAccumulator() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x2A, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_1111);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testRolZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0001)
        let program: [UInt8] = [0x26, 0x42, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0010);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(!cpu.statusRegister[.carry]);
    }

    func testRolZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0010)
        let program: [UInt8] = [0xA2, 0x21, 0x36, 0x21, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0100);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(!cpu.statusRegister[.carry]);
    }

    func testRolAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0x2E, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testRolAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0xA2, 0x34, 0x3E, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testRorAccumulator() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0b1111_1111, 0x6A, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0b1111_1111);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testRorZeroPage() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0001)
        let program: [UInt8] = [0x66, 0x42, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b1000_0000);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(cpu.statusRegister[.negative]);
        XCTAssertTrue(cpu.statusRegister[.carry]);
    }

    func testRorZeroPageX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0042, byte: 0b0000_0010)
        let program: [UInt8] = [0xA2, 0x21, 0x76, 0x21, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0042), 0b0000_0001);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(!cpu.statusRegister[.carry]);
    }

    func testRorAbsolute() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0x6E, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(!cpu.statusRegister[.carry]);
    }

    func testRorAbsoluteX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x1234, byte: 0b1010_1010)
        let program: [UInt8] = [0xA2, 0x34, 0x7E, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0b0101_0101);
        XCTAssertTrue(!cpu.statusRegister[.zero]);
        XCTAssertTrue(!cpu.statusRegister[.negative]);
        XCTAssertTrue(!cpu.statusRegister[.carry]);
    }

    func testStaZeroPage() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0x85, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0010), 0x42);
    }

    func testStaZeroPageX() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0x95, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x0030), 0x42);
    }

    func testStaAbsolute() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0x8D, 0x34, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42);
    }

    func testStaAbsoluteX() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x34, 0x9D, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42);
    }

    func testStaAbsoluteY() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0x99, 0x00, 0x12, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42);
    }

    func testStaIndirectX() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x34);
        cpu.writeByte(address: 0x0031, byte: 0x12);
        let program: [UInt8] = [0xA9, 0x42, 0xA2, 0x20, 0x81, 0x10, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42);
    }

    func testStaIndirectY() {
        var cpu = CPU()
        cpu.writeByte(address: 0x0030, byte: 0x00);
        cpu.writeByte(address: 0x0031, byte: 0x12);
        let program: [UInt8] = [0xA9, 0x42, 0xA0, 0x34, 0x91, 0x30, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.readByte(address: 0x1234), 0x42);
    }

    func testTaxMoveAToX() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x0A, 0xAA, 0x00];
        cpu.loadAndRun(program: program);
        XCTAssertEqual(cpu.xRegister, 0x0A);
    }

    func testFiveOpcodesWorkingTogether() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xc0, 0xAA, 0xE8, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.xRegister, 0xC1)
    }
}
