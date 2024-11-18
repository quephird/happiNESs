//
//  FilterChain.swift
//  happiNESs
//
//  Created by Danielle Kefford on 11/15/24.
//

public struct FilterChain {
    public var filters: [Filter]

    mutating public func filter(inputValue: Float) -> Float {
        var outputValue: Float = inputValue
        for i in filters.indices {
            outputValue = filters[i].filter(inputValue: outputValue)
        }

        return outputValue
    }
}
