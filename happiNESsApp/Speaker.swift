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
    private let wavNode = AVAudioPlayerNode()
    private let pauseWavFile = try! AVAudioFile(forReading: Bundle.main.url(forResource: "pause",
                                                                            withExtension: "mp3",
                                                                            subdirectory: "Sounds",
                                                                            localization: nil)!)

    init(inputBuffer: AudioRingBuffer) throws {
        self.inputBuffer = inputBuffer

        let mainMixer = engine.mainMixerNode
        let output = engine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        let inputFormat = AVAudioFormat(commonFormat: outputFormat.commonFormat,
                                        sampleRate: outputFormat.sampleRate,
                                        channels: 1,
                                        interleaved: outputFormat.isInterleaved)

        let sourceNode = AVAudioSourceNode { [inputBuffer] _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                let value = inputBuffer.take() ?? 0.0

                for outputAudioBuffer in ablPointer {
                    let outputBuffer: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(outputAudioBuffer)
                    outputBuffer[frame] = value
                }
            }

            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: inputFormat)
        engine.attach(self.wavNode)
        engine.connect(wavNode, to: mainMixer, format: inputFormat)
        engine.connect(mainMixer, to: output, format: outputFormat)
        mainMixer.outputVolume = 1.0

        try engine.start()
    }

    public func playPauseSound() {
        self.wavNode.scheduleFile(self.pauseWavFile, at: nil)
        self.wavNode.play()
    }
}
