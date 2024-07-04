//
//  ContentView.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(Console.self) var console

    // NOTA BENE: We need to make the single `Canvas` element focused, so we introduce
    // a boolean value annotated with `@FocusState` property wrapper, in addition to
    // passing a reference ot the `focused()` modifier as well as setting the property
    // to `true` in the `onAppear()` modifier. See this for more details:
    //
    //     https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-focusstate-property-wrapper
    //
    // Moreover, we can't just simply add a key handler via `onKeyPress()` to the view to make
    // responsive to user input; we need to make it `focusable()`. See the following for more details:
    //
    //     https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-and-respond-to-key-press-events
    @FocusState private var focused: Bool

    static let width: Int = 32
    static let height: Int = 32
    static let scale: Double = 10.0

    var body: some View {
        Canvas {graphicsContext, size in
            for y in 0 ..< Self.height {
                for x in 0 ..< Self.width {
                    let pixel = CGRect(
                        x: Double(x)*Self.scale,
                        y: Double(y)*Self.scale,
                        width: Self.scale,
                        height: Self.scale)

                    let nesColor = console.screenBuffer[y*Self.width + x]
                    let color = Color(nesColor: nesColor)

                    graphicsContext.fill(Path(pixel), with: .color(color))
                }
            }
        }
        .frame(
            width: CGFloat(Self.width) * Self.scale,
            height: CGFloat(Self.height) * Self.scale)
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
