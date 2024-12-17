//
//  Interruptible.swift
//  happiNESs
//
//  Created by Danielle Kefford on 12/15/24.
//

public protocol Interruptible {
    func triggerNmi()
    func triggerIrq()
}
