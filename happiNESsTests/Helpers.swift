//
//  Helpers.swift
//  happiNESsTests
//
//  Created by Danielle Kefford on 7/6/24.
//

@testable import happiNESs

func makeRom(programBytes: [UInt8]) -> Rom {
    let header: [UInt8] = [
        0x4E, 0x45, 0x53, 0x1A,
        0x02, 0x01, 0x31, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ]
    let prgRomBytes = Array(repeating: 0x00, count: 0x0600) + programBytes + Array(repeating: 0x00, count: 0x9400 - programBytes.count)
    let chrRomBytes = [UInt8](repeating: 0x00, count: 8192)
    let romBytes = header + prgRomBytes + chrRomBytes

    return Rom(bytes: romBytes)!
}

func makeCpu(programBytes: [UInt8]) -> CPU {
    let rom = makeRom(programBytes: programBytes)
    let bus = Bus(rom: rom)
    var cpu = CPU(bus: bus)
    cpu.reset()

    return cpu
}
