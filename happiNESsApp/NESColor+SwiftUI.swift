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
        switch nesColor {
        case .black:
            self = .black
        case .white:
            self = .white
        case .grey:
            self = .gray
        case .red:
            self = .red
        case .green:
            self = .green
        case .blue:
            self = .blue
        case .magenta:
            self.init(red: 1.0, green: 0.0, blue: 1.0)
        case .yellow:
            self.init(red: 1.0, green: 1.0, blue: 0.0)
        case .cyan:
            self = .cyan
        }
    }
}
