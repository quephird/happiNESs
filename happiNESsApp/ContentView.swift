//
//  ContentView.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(Console.self) var console
    @FocusState private var focused: Bool
    let scale: CGFloat = 10.0

    var body: some View {
        Canvas {graphicsContext, size in
            for y in 0 ..< 32 {
                for x in 0 ..< 32 {
                    let leftX = CGFloat(x)*scale
                    let rightX = CGFloat(x+1)*scale
                    let topY = CGFloat(y)*scale
                    let bottomY = CGFloat(y+1)*scale

                    var path = Path()
                    path.move(to: CGPoint(x: leftX, y: topY))
                    path.addLine(to: CGPoint(x: rightX, y: topY))
                    path.addLine(to: CGPoint(x: rightX, y: bottomY))
                    path.addLine(to: CGPoint(x: leftX, y: bottomY))
                    path.closeSubpath()

                    let nesColor = console.screenBuffer[y*32 + x]
                    let color = Color(nesColor: nesColor)

                    graphicsContext.fill(path, with: .color(color))
                }
            }
        }
        .frame(width: 32 * scale, height: 32 * scale)
        .padding()
        .focusable()
        .focused($focused)
        .onAppear {
            focused = true
        }
        .onKeyPress(phases: [.down]) { keyPress in
            console.keyDown(keyPress) ? .handled : .ignored
        }
    }
}

#Preview {
    ContentView()
}
