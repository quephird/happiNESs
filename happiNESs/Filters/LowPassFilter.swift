//
//  LowPassFilter.swift
//  happiNESs
//
//  Created by Danielle Kefford on 11/15/24.
//

public struct LowPassFilter: Filter {
    public var b0: Float
    public var b1: Float
    public var a1: Float
    public var prevX: Float
    public var prevY: Float

    init(sampleRate: Double, cutoffFrequency: Double) {
        let c = Float(sampleRate) / Float.pi / Float(cutoffFrequency)
        let a0i = 1 / (1 + c)

        self.b0 = a0i
        self.b1 = a0i
        self.a1 = (1 - c) * a0i
        self.prevX = 0.0
        self.prevY = 0.0
    }
}
