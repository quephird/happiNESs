//
//  AudioRingBuffer.swift
//  happiNESs
//
//  Created by Danielle Kefford on 10/17/24.
//

import Foundation

public class AudioRingBuffer {
    private var buffer: [Float] = [Float](repeating: 0.0, count: 44100)
    private var takeIndex: Int = 0
    private var appendIndex: Int = 0

    public func reset() {
        self.buffer = [Float](repeating: 0.0, count: 44100)
        self.takeIndex = 0
        self.appendIndex = 0
    }
}

extension AudioRingBuffer {
    public func take() -> Float? {
        if self.takeIndex < self.appendIndex {
            let currentValue = self.buffer[takeIndex % self.buffer.count]
            takeIndex += 1
            return currentValue
        }

        return nil
    }

    public func append(value: Float) {
        precondition(appendIndex >= takeIndex)
        self.buffer[appendIndex % self.buffer.count] = value
        appendIndex += 1
    }
}
