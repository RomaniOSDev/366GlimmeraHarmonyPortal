import Foundation

struct VeyraTripFolio: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var placeNote: String
    var openedOn: Date
    var coverKey: String? = nil

    var veyraCover: String {
        if let coverKey, VeyraStillRack.choices.contains(coverKey) {
            return coverKey
        }
        return VeyraStillRack.cliff
    }
}

struct VeyraMomentSlip: Identifiable, Codable, Hashable {
    var id: UUID
    var tripID: UUID
    var iconGlyph: String
    var reflection: String
    var placeLine: String
    var stampedOn: Date
    var pinnedHighlight: Bool
    var ordinal: Int? = nil
    var photoFile: String? = nil

    var veyraOrdinal: Int { ordinal ?? 0 }
}

enum VeyraShelfOrder: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case title

    var id: String { rawValue }

    var veyraTitle: String {
        switch self {
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        case .title: return "Name"
        }
    }
}

struct VeyraCaptionLeaf: Identifiable, Codable, Hashable {
    var id: UUID
    var momentID: UUID
    var imageKey: String
    var captionBody: String
    var stampedOn: Date
}

enum VeyraGlyphRack {
    static let marks = ["🌍", "⛰️", "🏛️", "🌊", "🍜", "🚂", "🌅", "🏕️", "🌉", "🐚", "🎭", "🌙"]
}

enum VeyraStillRack {
    static let cliff = "veyraCliffDusk"
    static let desk = "veyraJournalDesk"
    static let lantern = "veyraLanternStreet"
    static let lake = "veyraLakeMorning"
    static let choices = [cliff, desk, lantern, lake]

    static func veyraLabel(for key: String) -> String {
        switch key {
        case cliff: return "Cliff path"
        case desk: return "Desk journal"
        case lantern: return "Lantern street"
        case lake: return "Morning lake"
        default: return "Scene picture"
        }
    }
}

enum VeyraDockLane: Int, CaseIterable, Identifiable {
    case trips
    case notes
    case stars
    case setup

    var id: Int { rawValue }

    var veyraTitle: String {
        switch self {
        case .trips: return "Trips"
        case .notes: return "Notes"
        case .stars: return "Stars"
        case .setup: return "Setup"
        }
    }

    var veyraSymbol: String {
        switch self {
        case .trips: return "map"
        case .notes: return "text.alignleft"
        case .stars: return "star"
        case .setup: return "slider.horizontal.3"
        }
    }
}

enum VeyraFolioModelsQelmDrift {
    static func veyraFolioModelsQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [72, 47, 36, 61, 16, 80]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 72) &+ mark
        }
    }
}
