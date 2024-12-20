//
//  Helpers.swift
//  happiNESsTests
//
//  Created by Danielle Kefford on 7/6/24.
//

import XCTest
import happiNESs

struct MockBus: Interruptible {
    func triggerNmi() {
        // Do nothing
    }

    func triggerIrq() {
        // Do nothing
    }
}

func makeCartridge(programBytes: [UInt8]) -> Cartridge {
    let header: [UInt8] = [
        0x4E, 0x45, 0x53, 0x1A,
        0x02, 0x01, 0x31, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ]
    let prgRomBytes = Array(repeating: 0x00, count: 0x0600) + programBytes + Array(repeating: 0x00, count: 0x79FC - programBytes.count) + [0x00, 0x86, 0x00, 0x00]
    let chrRomBytes = [UInt8](repeating: 0x00, count: 8192)
    let romBytes = header + prgRomBytes + chrRomBytes
    let romData = Data(romBytes)

    return try! Cartridge(romData: romData, interruptible: MockBus())
}

func makeCpu(programBytes: [UInt8]) -> CPU {
    let cartridge = makeCartridge(programBytes: programBytes)
    let bus = Bus()
    let cpu = CPU(bus: bus)
    cpu.loadCartridge(cartridge: cartridge)
    cpu.reset()

    return cpu
}

func loadRomFile(romName: String, cpu: CPU) throws {
    guard let romUrl = Bundle(for: ROMTests.self).url(forResource: romName, withExtension: "nes") else {
        XCTFail("ROM file could not be found")
        return
    }
    let romData: Data = try Data(contentsOf: romUrl)
    let cartridge = try Cartridge(romData: romData,
                                  interruptible: cpu.bus)

    cpu.loadCartridge(cartridge: cartridge)
    cpu.reset()
}

func hasBlarggTestBegun(cpu: CPU) -> Bool {
    let statusBytes = (0x6001 ... 0x6003).map { address in
        cpu.readByteWithoutMutating(address: address)
    }

    return statusBytes == [0xDE, 0xB0, 0x61]
}

enum BlarggTestStatus {
    case stillRunning
    case passed
    case failed(String)
}

func getBlarggTestMessage(cpu: CPU) -> String {
    var messageAddress: UInt16 = 0x6004
    var messageBytes: [UInt8] = []
    while true {
        let byte = cpu.readByteWithoutMutating(address: messageAddress)
        if byte == 0x00 {
            break
        }
        messageBytes.append(byte)
        messageAddress += 1
    }

    return String(bytes: messageBytes, encoding: .utf8)!
}

func getBlarggTestStatus(cpu: CPU) -> BlarggTestStatus {
    let status = cpu.readByteWithoutMutating(address: 0x6000)

    switch status {
    case 0x80:
        return .stillRunning
    case 0x00:
        return .passed
    default:
        let message = getBlarggTestMessage(cpu: cpu)
        return .failed(message)
    }
}

func testBlarggRom(romName: String, cpu: CPU) throws {
    try loadRomFile(romName: romName, cpu: cpu)

    while true {
        let _ = cpu.executeInstruction()

        let testHasBegun = hasBlarggTestBegun(cpu: cpu)
        if !testHasBegun {
            continue
        }

        let testStatus = getBlarggTestStatus(cpu: cpu)
        switch testStatus {
        case .stillRunning:
            continue
        case .passed:
            return
        case .failed(let message):
            XCTFail(message)
            return
        }
    }
}
