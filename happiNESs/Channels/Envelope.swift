//
//  Envelope.swift
//  happiNESs
//
//  Created by Danielle Kefford on 12/31/24.
//

struct Envelope {
    public var constantVolume: Bool = false
    public var loopEnabled: Bool = false
    public var started: Bool = false
    public var timer: Timer = Timer()
    public var decayValue: UInt8 = 0

    mutating public func reset() {
        self.constantVolume = false
        self.loopEnabled = false
        self.started = false
        self.timer.reset()
        self.decayValue = 0
    }
}

extension Envelope {
    public func getSample() -> UInt8 {
        if self.constantVolume {
            return UInt8(self.timer.period)
        } else {
            return self.decayValue
        }
    }

    mutating public func step() {
        if self.started {
            self.started = false
            self.decayValue = 15
            self.timer.reload()
        } else if self.timer.step() {
            if self.decayValue > 0 {
                self.decayValue -= 1
            } else if self.loopEnabled {
                self.decayValue = 15
            }
        }
    }
}
