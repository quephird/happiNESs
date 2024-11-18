//
//  Filter.swift
//  happiNESs
//
//  Created by Danielle Kefford on 11/15/24.
//

public protocol Filter {
    var b0: Float { get set }
    var b1: Float { get set }
    var a1: Float { get set }
    var prevInputValue: Float { get set }
    var prevOutputValue: Float { get set }

    mutating func filter(inputValue: Float) -> Float
}

extension Filter {
    mutating public func filter(inputValue: Float) -> Float {
        // NOTA BENE: This code was adapted from Michael Fogleman's implementation here:
        //
        //     https://github.com/fogleman/nes/blob/master/nes/filter.go#L19-L24
        //
        // I don't fully understand the theory behind how filters work but this is apparently
        // an implementation of a so-called first order causal IIR difference equation, some
        // of the details of which are explained here:
        //
        //     https://dsp.stackexchange.com/a/51710
        //
        // the "b" parameters are the so-called feedforward filter coefficients and the a1
        // a1 value is a feedback filter coefficient. The general form of the equation is
        // discussed here:
        //
        //     https://en.wikipedia.org/wiki/Infinite_impulse_response#Transfer_function_derivation
        let outputValue = self.b0*inputValue + self.b1*self.prevInputValue - self.a1*self.prevOutputValue
        self.prevOutputValue = outputValue
        self.prevInputValue = inputValue
        return outputValue
    }
}
