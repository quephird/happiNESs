//
//  Screen.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 7/6/24.
//

import SwiftUI

import happiNESs

struct Screen: View {
    static let width: Int = 32
    static let height: Int = 32
    static let scale: Double = 10.0

    var screenBuffer: [NESColor]

    var body: some View {
        Canvas {graphicsContext, size in
            for y in 0 ..< Self.height {
                for x in 0 ..< Self.width {
                    let pixel = CGRect(
                        x: Double(x)*Self.scale,
                        y: Double(y)*Self.scale,
                        width: Self.scale,
                        height: Self.scale)

                    let nesColor = screenBuffer[y*Self.width + x]
                    let color = Color(nesColor: nesColor)

                    graphicsContext.fill(Path(pixel), with: .color(color))
                }
            }
        }
        .frame(
            width: CGFloat(Self.width) * Self.scale,
            height: CGFloat(Self.height) * Self.scale)
    }
}
