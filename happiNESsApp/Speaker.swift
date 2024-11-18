//
//  Speaker.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 10/16/24.
//

import AVFoundation

import happiNESs

struct Speaker {
    public var inputBuffer: AudioRingBuffer
    private let engine = AVAudioEngine()

    init(inputBuffer: AudioRingBuffer) throws {
        self.inputBuffer = inputBuffer

        let mainMixer = engine.mainMixerNode
        let output = engine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        let inputFormat = AVAudioFormat(commonFormat: outputFormat.commonFormat,
                                        sampleRate: outputFormat.sampleRate,
                                        channels: 1,
                                        interleaved: outputFormat.isInterleaved)

        var cachedBufferValue: Float = 0.0
        let sourceNode = AVAudioSourceNode { [inputBuffer] _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                // NOTA BENE: Because the emulated timing between the CPU and APU
                // is not quite accurate, the buffer is sometimes empty, and so
                // if we put a zero value into the output buffer, the result is a
                // popping/slapping sound. So for now, we cache the previous value
                // of the sample and use that in the event that the buffer, resulting
                // in a much smoother audio output.
                let value = inputBuffer.take() ?? cachedBufferValue
                cachedBufferValue = value

                for outputAudioBuffer in ablPointer {
                    let outputBuffer: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(outputAudioBuffer)
                    outputBuffer[frame] = value
                }
            }

            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: inputFormat)
        engine.connect(mainMixer, to: output, format: outputFormat)
        mainMixer.outputVolume = 1.0

        try engine.start()
    }
}
