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
        // NOTA BENE: As with the low pass filter, I can hardly find any
        // information on the derivation of the values for b0, b1, and a1.
        // I _did_ find a few comments here basically saying that the high
        // pass filter is effectively the additive inverse of the low pass
        // filter for the "b" coefficients:
        //
        //     https://www.reddit.com/r/DSP/comments/1dw854e/comment/lbtewn3/
        let c = sampleRate / Float.pi / cutoffFrequency
        self.b0 = c / (1 + c)
        self.b1 = -c / (1 + c)
        self.a1 = (1 - c) / (1 + c)
        self.prevInputValue = 0.0
        self.prevOutputValue = 0.0
    }
}
