//
//  NESColor+SwiftUI.swift
//  happiNESsApp
//
//  Created by Danielle Kefford on 6/29/24.
//

import SwiftUI
import happiNESs

extension Color {
    init(nesColor: NESColor) {
        self.init(red: Double(nesColor.red)/255, green: Double(nesColor.green)/255, blue: Double(nesColor.blue)/255)
    }
}
