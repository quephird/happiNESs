//
//  NESError.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/29/24.
//

import Foundation

enum NESError: Error, LocalizedError {
    case romFileCouldNotBeSelected
    case romFileCouldNotBeOpened
    case romCouldNotBeRead

    var errorDescription: String? {
        switch self {
        case .romFileCouldNotBeSelected:
            "Unable to select file"
        case .romFileCouldNotBeOpened:
            "Unable to open file"
        case .romCouldNotBeRead:
            "Unable to run file"
        }
    }
}
