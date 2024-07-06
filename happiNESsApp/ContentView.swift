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

    var body: some View {
        Screen(screenBuffer: console.screenBuffer)
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
