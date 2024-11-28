//
//  NESError.swift
//  happiNESs
//
//  Created by Danielle Kefford on 8/29/24.
//

import Foundation

enum NESError: Equatable, Error, LocalizedError {
    case romFileCouldNotBeSelected
    case romFileCouldNotBeOpened
    case romNotInInesFormat
    case versionTwoPointOhOrEarlierSupported
    case unsupportedTimingMode
    case mapperNotSupported(Int)
    case cannotCreateSaveDataDirectory
    case invalidSaveDatafile
    case unableToSaveDataFile(String)

    var errorDescription: String? {
        switch self {
        case .romFileCouldNotBeSelected:
            "Unable to select file"
        case .romFileCouldNotBeOpened:
            "Unable to open file"
        case .romNotInInesFormat:
            "ROM file not in iNES format"
        case .versionTwoPointOhOrEarlierSupported:
            "NES 2.0 ROMs or earlier supported only"
        case .unsupportedTimingMode:
            "Only NTSC and PAL ROMs currently supported"
        case .mapperNotSupported(let mapperNumber):
            String(format: "Mapper number %03d not supported", mapperNumber)
        case .cannotCreateSaveDataDirectory:
            "Could not create save directory for game data files"
        case .invalidSaveDatafile:
            "Save data file is somehow invalid and cannot be loaded"
        case .unableToSaveDataFile(let message):
            "Error saving SRAM: \(message)"
        }
    }
}
