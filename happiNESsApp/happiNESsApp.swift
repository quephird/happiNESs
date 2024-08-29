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

    var body: some Scene {
        Window("happiNESs", id: "main") {
            ContentView()
                .environment(console)
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
                    switch result {
                    case .success(let fileUrls):
                        fileUrls.forEach { fileUrl in
                            guard fileUrl.startAccessingSecurityScopedResource() else {
                                return
                            }

                            do {
                                try self.console.runGame(fileUrl: fileUrl)
                            } catch {
                                return
                            }
                        }
                    case .failure(let error):
                        // handle error
                        print(error)
                    }
                }
            }
        }
    }
}
