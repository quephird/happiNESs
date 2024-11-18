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
        let outputValue = self.b0*inputValue + self.b1*self.prevInputValue - self.a1*self.prevOutputValue
        self.prevOutputValue = outputValue
        self.prevInputValue = inputValue
        return outputValue
    }
}
