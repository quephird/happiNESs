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
    public var prevInputValue: Float
    public var prevOutputValue: Float

    init(sampleRate: Float, cutoffFrequency: Float) {
        // NOTA BENE: I can find _very_ little information on the thinking behind
        // the assignment of values to b0, b1, and a1. The most I can find is later
        // on in this StackExchange answer for their _relative_ values:
        //
        //     https://dsp.stackexchange.com/a/51714
        //
        // As for the _specific_ values, I still cannot find anything... but it does work.
        let c = sampleRate / Float.pi / cutoffFrequency
        self.b0 = 1 / (1 + c)
        self.b1 = 1 / (1 + c)
        self.a1 = (1 - c) / (1 + c)
        self.prevInputValue = 0.0
        self.prevOutputValue = 0.0
    }
}
