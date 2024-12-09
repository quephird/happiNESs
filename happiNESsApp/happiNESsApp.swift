//
//  happiNESsAppApp.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import happiNESs
import SwiftUI
import UniformTypeIdentifiers

@main
@MainActor
struct happiNESsApp: App {
    static let fullscreenNotificationPublisher = NotificationCenter.default.publisher(
        for: NSWindow.didEnterFullScreenNotification
    ).merge(
        with: NotificationCenter.default.publisher(
            for: NSWindow.didExitFullScreenNotification
        )
    )

    @State var console = try! Console()

    @State private var showFileImporter = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var isFullscreen = false
    @State private var oldScale: Double = Console.defaultScale

    private var buttonLabel: String {
        self.console.isPaused ? "Unpause game" : "Pause game"
    }

    private func setErrorMessage(message: String) {
        self.errorMessage = message
        self.showAlert = true
    }

    var body: some Scene {
        let commonView = ContentView()
            .environment(console)
            .alert(errorMessage, isPresented: $showAlert, actions: {})
            .dialogSeverity(.critical)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                do {
                    try self.console.saveSram()
                } catch {
                    self.setErrorMessage(message: error.localizedDescription)
                }
            }

        Window("happiNESs", id: "main") {
            if #available(macOS 15.0, *) {
                HStack {
                    if isFullscreen {
                        // NOTA BENE: We need to set the minimum lenght of the spacer
                        // here to something large enough so that the centering of the
                        // ContentView actually works.
                        Spacer(minLength: NSScreen.main!.frame.width/2.0)
                    }
                    commonView
                    if isFullscreen {
                        Spacer(minLength: NSScreen.main!.frame.width/2.0)
                    }
                }
                    .background(Color.black)
                    .windowFullScreenBehavior(.enabled)
                    .windowResizeBehavior(.disabled)
                    .onReceive(Self.fullscreenNotificationPublisher) { notification in
                        switch notification.name {
                        case NSWindow.didEnterFullScreenNotification:
                            if let window = notification.object as? NSWindow, let screen = window.screen {
                                self.oldScale = console.scale
                                let newScale = screen.frame.size.height / CGFloat(PPU.height)
                                console.scale = newScale
                            }
                            self.isFullscreen = true
                        case NSWindow.didExitFullScreenNotification:
                            console.scale = oldScale
                            self.isFullscreen = false
                        default:
                            break
                        }
                    }
            } else {
                commonView
            }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open ROM...") {
                    self.showFileImporter = true
                }
                .keyboardShortcut("o", modifiers: .command)
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [UTType(filenameExtension: "nes")!],
                    allowsMultipleSelection: false
                ) { result in
                    do {
                        guard let fileUrl = try result.get().first else {
                            throw NESError.romFileCouldNotBeSelected
                        }

                        guard fileUrl.startAccessingSecurityScopedResource() else {
                            throw NESError.romFileCouldNotBeOpened
                        }

                        try self.console.runGame(fileUrl: fileUrl)
                    }
                    catch {
                        self.setErrorMessage(message: error.localizedDescription)
                    }
                }
            }
            CommandGroup(after: .sidebar) {
                Button("Dump PPU State") {
                    console.dumpPpu()
                }
                Toggle("Toggle tracing", isOn: $console.tracingOn)
                Divider()
                Button("Reset game") {
                    console.reset()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!console.cartridgeLoaded)
                Button(self.buttonLabel) {
                    console.togglePause()
                }
                .keyboardShortcut("p", modifiers: .command)
                Picker(selection: $console.scale, label: Text("Scale")) {
                    Text("1x")
                        .tag(1.0)
                        .keyboardShortcut("1", modifiers: .command)
                    Text("2x")
                        .tag(2.0)
                        .keyboardShortcut("2", modifiers: .command)
                    Text("3x")
                        .tag(3.0)
                        .keyboardShortcut("3", modifiers: .command)
                }
                .disabled(isFullscreen)
            }
        }
        .onChange(of: console.currentError) { oldValue, newValue in
            if let consoleError = console.currentError {
                self.setErrorMessage(message: consoleError.localizedDescription)
            }
        }
    }
}
