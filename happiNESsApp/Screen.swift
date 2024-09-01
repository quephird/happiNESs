//
//  Screen.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 7/6/24.
//

import SwiftUI

import happiNESs

extension CGBitmapInfo {
    public init(alphaInfo: CGImageAlphaInfo) {
        self.init(rawValue: alphaInfo.rawValue)
    }

    public init(byteOrderInfo: CGImageByteOrderInfo) {
        self.init(rawValue: byteOrderInfo.rawValue)
    }
}

struct Screen: View {
    static let width: Int = PPU.width
    static let height: Int = PPU.height
    static let scale: Double = 2.0
    static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    static let bitmapInfo: CGBitmapInfo = [
        CGBitmapInfo(alphaInfo: .none),
        CGBitmapInfo(byteOrderInfo: .orderDefault),
    ]

    var screenBuffer: [NESColor]

    var body: some View {
        Canvas {graphicsContext, size in
            graphicsContext.withCGContext { cgContext in
                // First we have to convert screenBuffer into a bitmap buffer of raw UInt8's
                var bitmapBuffer = [UInt8]()
                bitmapBuffer.reserveCapacity(Self.width * Self.height * 3)
                for color in screenBuffer {
                    bitmapBuffer.append(color.red)
                    bitmapBuffer.append(color.green)
                    bitmapBuffer.append(color.blue)
                }

                precondition(bitmapBuffer.count == Self.width * Self.height * 3)
                bitmapBuffer.withUnsafeBytes { bufferPointer in
                    // Then we need to make a provider that instructs CGImage how to read in the bitmap buffer.
                    //
                    // NOTA BENE: bufferPointer.baseAddress will never be null in this context
                    // Also, we don't need to use an actual closure in when we deallocate the data provider,
                    // and so don't need to pass in a value for dataInfo to that closure either.
                    let dataProvider = CGDataProvider(
                        dataInfo: nil,
                        data: bufferPointer.baseAddress!,
                        size: bufferPointer.count,
                        releaseData: {_, _, _ in })!

                    // Next we need to create the actual CGImage using the data provider.
                    let image = CGImage(
                        width: Self.width,
                        height: Self.height,
                        bitsPerComponent: 8,
                        bitsPerPixel: 8 * 3,
                        bytesPerRow: Self.width * 3,
                        space: Self.colorSpace,
                        bitmapInfo: Self.bitmapInfo,
                        provider: dataProvider,
                        decode: nil,
                        shouldInterpolate: false,
                        intent: .defaultIntent)!

                    // Then we need to set up the graphics context such that the image
                    // actually starts at the upper left not the bottom left, and doesn't
                    // wind up being displayed upside down.
                    cgContext.scaleBy(x: 1, y: -1)
                    cgContext.translateBy(x: 0, y: -size.height)

                    // Then we draw the image to the graphics context
                    let drawingRect = CGRect(origin: .zero, size: size)
                    cgContext.draw(image, in: drawingRect, byTiling: false)
                }
            }
        }
        .frame(
            width: CGFloat(Self.width) * Self.scale,
            height: CGFloat(Self.height) * Self.scale)
    }
}
