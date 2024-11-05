//
//  RomTests.swift
//  happiNESsTests
//
//  Created by Danielle Kefford on 7/6/24.
//

import XCTest
@testable import happiNESs

final class RomTests: XCTestCase {
    func testRomWithBadTag() throws {
        let header: [UInt8] = [
            0x0B, 0xAD, 0x0B, 0xAD,
            0x02, 0x01, 0x31, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ]
        let programBytes: [UInt8] = [0xA9, 0x42]
        let prgRomBytes = Array(repeating: 0x00, count: 0x0600) + programBytes + Array(repeating: 0x00, count: 0x9400 - programBytes.count)
        let chrRomBytes = [UInt8](repeating: 0x00, count: 8192)
        let romBytes = header + prgRomBytes + chrRomBytes

        let expectedError = NESError.romNotInInesFormat
        XCTAssertThrowsError(try Cartridge(bytes: romBytes)) { actualError in
            XCTAssertEqual(actualError as! NESError, expectedError)
        }
    }

    func testRomWithBadVersion() throws {
        let header: [UInt8] = [
            0x4E, 0x45, 0x53, 0x1A,
            0x02, 0x01, 0x31, 0b0000_1000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ]
        let programBytes: [UInt8] = [0xA9, 0x42]
        let prgRomBytes = Array(repeating: 0x00, count: 0x0600) + programBytes + Array(repeating: 0x00, count: 0x9400 - programBytes.count)
        let chrRomBytes = [UInt8](repeating: 0x00, count: 8192)
        let romBytes = header + prgRomBytes + chrRomBytes

        let expectedError = NESError.versionTwoPointOhNotSupported
        XCTAssertThrowsError(try Cartridge(bytes: romBytes)) { actualError in
            XCTAssertEqual(actualError as! NESError, expectedError)
        }
    }

    func testRomWithTrainer() throws {
        let header: [UInt8] = [
            0x4E, 0x45, 0x53, 0x1A,
            0x02, 0x01, 0b0011_0101, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ]
        let trainer = [UInt8](repeating: 0x00, count: 512)
        let prgBytes: [UInt8] = [0xA9, 0x42] + [UInt8](repeating: 0x00, count: 32766)
        let chrBytes = [UInt8](repeating: 0x00, count: 8192)

        let allBytes = header + trainer + prgBytes + chrBytes
        let cartridge = try! Cartridge(bytes: allBytes)
        XCTAssertEqual(cartridge.prgMemory[0], 0xA9)
        XCTAssertEqual(cartridge.prgMemory[1], 0x42)
    }
}
