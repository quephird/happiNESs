//
//  Helpers.swift
//  happiNESsTests
//
//  Created by Danielle Kefford on 7/6/24.
//

@testable import happiNESs

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
