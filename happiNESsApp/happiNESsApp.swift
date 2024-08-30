//
//  happiNESsAppApp.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import SwiftUI
import UniformTypeIdentifiers

@main
@MainActor
struct happiNESsApp: App {
    @State var console = try! Console()

    @State private var showFileImporter = false
    @State private var errorMessage = ""
    @State private var showAlert = false

    private func setErrorMessage(message: String) {
        self.errorMessage = message
        self.showAlert = true
    }

    var body: some Scene {
        Window("happiNESs", id: "main") {
            ContentView()
                .environment(console)
                .alert(errorMessage, isPresented: $showAlert, actions: {})
                .dialogSeverity(.critical)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open ROM...") {
                    self.showFileImporter = true
                }
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
        }
    }
}
