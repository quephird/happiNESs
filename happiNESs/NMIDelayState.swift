//
//  NMIDelayState.swift
//  happiNESs
//
//  Created by Danielle Kefford on 11/3/24.
//

public enum NMIDelayState: Hashable {
    case delayed(Int)
    case none
    case canceled
}

extension NMIDelayState {
    // NOTA BENE: The NMI needs to be fired only after the _following_
    // CPU instruction is completed, simulating the delay in the actual
    // NES hardware. In other words, the PPU doesn't directly and immediately
    // trigger an NMI in the CPU. This delay corresponds roughly with the
    // execution of two CPU instructions, namely the current one and the
    // next one.
    mutating func scheduleNmi() {
        if self == .canceled {
            return
        }

        self = .delayed(14)
    }

    mutating func shouldTriggerNmi() -> Bool {
        if self == .delayed(0) {
            self = .none
            return true
        }

        return false
    }

    mutating public func decrement() {
        switch self {
        case .delayed(let cycles):
            self = .delayed(cycles - 1)
        default:
            break
        }
    }

    mutating public func uncancel() {
        if self == .canceled {
            self = .none
        }
    }
}
