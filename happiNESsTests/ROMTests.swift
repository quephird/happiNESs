//
//  ROMTests.swift
//  happiNESs
//
//  Created by Danielle Kefford on 12/18/24.
//

import XCTest
@testable import happiNESs

final class ROMTests: XCTestCase {
    let cpu = CPU(bus: Bus())

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
