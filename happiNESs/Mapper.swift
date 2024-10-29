//
//  Mapper.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/28/24.
//

public protocol Mapper {
    var cartridge: Cartridge? { get set }

    func readByte(address: UInt16) -> UInt8
    func writeByte(address: UInt16, byte: UInt8)
}
