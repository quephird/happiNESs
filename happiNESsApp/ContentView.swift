//
//  ContentView.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import happiNESs

import GameController
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

    @State private var isPausedShowing = false

    var body: some View {
        Group {
            if self.console.cartridgeLoaded {
                ZStack {
                    Screen(screenBuffer: console.screenBuffer,
                           scale: console.scale)
                    .focusable()
                    .focusEffectDisabled()
                    .focused($focused)
                    .onAppear {
                        focused = true
                    }
                    .onKeyPress(phases: .all) { keyPress in
                        return console.handleKey(keyPress) ? .handled : .ignored
                    }
                    .task {
                        await self.setupGamepad()
                    }
                    if self.console.isPaused {
                        Text("PAUSED")
                            .font(.zelda)
                            .scaleEffect(console.scale)
                            .opacity(self.isPausedShowing ? 0.0 : 1.0)
                            .onAppear {
                                self.isPausedShowing = true
                            }
                            .animation(.easeOut(duration: 2.0), value: self.isPausedShowing)
                            .onDisappear {
                                self.isPausedShowing = false
                            }
                    }
                }
            } else {
                Image("happiNESs")
            }
        }
        .scaledToFit()
    }

    private func setupGamepad() async {
        let controllers = NotificationCenter.default.notifications(
            named: .GCControllerDidConnect
        ).map(
            {
                $0.object as! GCController
            })

        for await controller in controllers {
            controller.input.elementValueDidChangeHandler = { (input: GCDevicePhysicalInput, element: GCPhysicalInputElement) in
                if let dpadElement = element as? GCDirectionPadElement {
                    self.console.handleDpad(dpadElement: dpadElement)
                }

                if let buttonElement = element as? GCButtonElement {
                    if buttonElement === input.buttons[.a] {
                        self.console.handleButton(buttonElement: buttonElement, button: .buttonA)
                    } else if buttonElement === input.buttons[.b] {
                        self.console.handleButton(buttonElement: buttonElement, button: .buttonB)
                    } else if buttonElement === input.buttons[.menu] {
                        self.console.handleButton(buttonElement: buttonElement, button: .start)
                    } else if buttonElement === input.buttons[.home] {
                        self.console.handleButton(buttonElement: buttonElement, button: .select)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
