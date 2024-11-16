//
//  FilterChain.swift
//  happiNESs
//
//  Created by Danielle Kefford on 11/15/24.
//

public struct FilterChain {
    public var filters: [Filter]

    mutating public func filter(signalValue: Float) -> Float {
        var outputValue: Float = signalValue
        for i in filters.indices {
            outputValue = filters[i].filter(signalValue: outputValue)
        }

        return outputValue
    }
}
