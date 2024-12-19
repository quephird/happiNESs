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
        guard let romUrl = Bundle(for: ROMTests.self).url(forResource: "nestest", withExtension: "nes") else {
            XCTFail("ROM file could not be found")
            return
        }
        let romData: Data = try Data(contentsOf: romUrl)
        let cartridge = try Cartridge(romData: romData,
                                      interruptible: cpu.bus)

        cpu.loadCartridge(cartridge: cartridge)
        cpu.reset()
        cpu.programCounter = 0xC000

        while cpu.programCounter != 0xC66E {
            let _ = cpu.executeInstruction()
        }

        let officialOpcodeStatus = self.cpu.readByte(address: 0x0002)
        let unofficialOpcodeStatus = self.cpu.readByte(address: 0x0003)
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
