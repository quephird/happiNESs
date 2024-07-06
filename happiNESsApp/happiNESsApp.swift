//
//  happiNESsAppApp.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import SwiftUI

@main
@MainActor
struct happiNESsApp: App {
    @State var console = try! Console()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(console)
        }
    }
}
