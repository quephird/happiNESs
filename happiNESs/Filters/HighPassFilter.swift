//
//  HighPassFilter.swift
//  happiNESs
//
//  Created by Danielle Kefford on 11/15/24.
//

public struct HighPassFilter: Filter {
    public var b0: Float
    public var b1: Float
    public var a1: Float
    public var prevInputValue: Float
    public var prevOutputValue: Float

    init(sampleRate: Float, cutoffFrequency: Float) {
        let c = sampleRate / Float.pi / cutoffFrequency
        let a0i = 1 / (1 + c)

        self.b0 = c * a0i
        self.b1 = -c * a0i
        self.a1 = (1 - c) * a0i
        self.prevInputValue = 0.0
        self.prevOutputValue = 0.0
    }
}
