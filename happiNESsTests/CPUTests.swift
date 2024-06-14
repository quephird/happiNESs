//
//  happiNESsTests.swift
//  happiNESsTests
//
//  Created by Danielle Kefford on 6/14/24.
//

import XCTest
@testable import happiNESs

final class CPUTests: XCTestCase {
    func testInxOverflow() throws {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0xFF, 0xAA, 0xE8, 0xE8, 0x00]
        cpu.loadAndRun(program: program)

        XCTAssertEqual(cpu.xRegister, 0x01)
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

    func testLdaImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA9, 0x05, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.accumulator, 0x05);
        XCTAssertTrue(cpu.statusRegister & 0b0000_0010 == 0b0000_0000);
        XCTAssertTrue(cpu.statusRegister & 0b1000_0000 == 0b0000_0000);
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
        XCTAssertTrue(cpu.statusRegister & 0b0000_0010 == 0b0000_0010);
    }

    func testLdxImmediate() {
        var cpu = CPU()
        let program: [UInt8] = [0xA2, 0xF0, 0x00];
        cpu.loadAndRun(program: program);

        XCTAssertEqual(cpu.xRegister, 0xF0);
        XCTAssertTrue(cpu.statusRegister & 0b0000_0010 == 0b0000_0000);
        XCTAssertTrue(cpu.statusRegister & 0b1000_0000 == 0b1000_0000);
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
        XCTAssertTrue(cpu.statusRegister & 0b0000_0010 == 0b0000_0010);
        XCTAssertTrue(cpu.statusRegister & 0b1000_0000 == 0b0000_0000);
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
