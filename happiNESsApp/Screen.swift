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

    static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    static let bitmapInfo: CGBitmapInfo = [
        CGBitmapInfo(alphaInfo: .none),
        CGBitmapInfo(byteOrderInfo: .orderDefault),
    ]

    var screenBuffer: [UInt8]
    var scale: Double

    var image: CGImage {
        self.screenBuffer.withUnsafeBytes { bufferPointer in
            // Creates a CFData instance with a copy of the data from the screen buffer
            let data = CFDataCreate(nil, bufferPointer.baseAddress!, bufferPointer.count)!

            // Make a provider that instructs CGImage how to read in the bitmap buffer.
            let dataProvider = CGDataProvider(data: data)!

            // Create the actual CGImage using the data provider.
            return CGImage(width: Self.width,
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
        }
    }

    var body: some View {
        Image(self.image,
              scale: 1/self.scale,
              orientation: .up,
              label: Text(verbatim: "Screen"))
        .interpolation(.none)
        .frame(
            maxWidth: CGFloat(Self.width) * self.scale,
            maxHeight: CGFloat(Self.height) * self.scale)
        .fixedSize()
    }
}
