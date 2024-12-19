//
//  ROMTests.swift
//  happiNESs
//
//  Created by Danielle Kefford on 12/18/24.
//

import XCTest
import happiNESs

final class ROMTests: XCTestCase {
    let cpu = CPU(bus: Bus())

    func testNestest() throws {
        try loadRomFile(romName: "nestest", cpu: self.cpu)
        cpu.programCounter = 0xC000

        // NOTA BENE: The addresses for the program counter and status bytes
        // were taken from this blog post:
        //
        //     http://nnarain.github.io/2020/04/15/nescore-NES-Emulator-written-in-Rust.html
        while cpu.programCounter != 0xC66E {
            let _ = cpu.executeInstruction()
        }

        let officialOpcodeStatus = self.cpu.readByteWithoutMutating(address: 0x0002)
        let unofficialOpcodeStatus = self.cpu.readByteWithoutMutating(address: 0x0003)
        XCTAssertEqual(officialOpcodeStatus, 0x00, "Official opcodes failed")
        XCTAssertEqual(unofficialOpcodeStatus, 0x00, "Official opcodes failed")
    }

    func testOfficialOnly() throws {
        try testBlarggRom(romName: "official_only", cpu: self.cpu)
    }

    func testPpuReadBuffer() throws {
        try testBlarggRom(romName: "test_ppu_read_buffer", cpu: self.cpu)
    }

    func testPpuVblNmi() throws {
        try testBlarggRom(romName: "ppu_vbl_nmi", cpu: self.cpu)
    }
}
