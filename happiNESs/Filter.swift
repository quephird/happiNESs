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
    var prevX: Float { get set }
    var prevY: Float { get set }

    mutating func filter(signalValue: Float) -> Float
}

extension Filter {
    mutating public func filter(signalValue: Float) -> Float {
        let outputValue = self.b0*signalValue + self.b1*self.prevX - self.a1*self.prevY
        self.prevY = outputValue
        self.prevX = signalValue
        return outputValue
    }
}
