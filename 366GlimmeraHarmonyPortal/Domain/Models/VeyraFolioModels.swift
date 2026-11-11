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

enum VeyraPullKind: String, Codable, CaseIterable, Identifiable {
    case light
    case sound
    case crowd
    case weather
    case memory
    case detour

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "Light"
        case .sound: return "Sound"
        case .crowd: return "Crowd"
        case .weather: return "Weather"
        case .memory: return "Memory"
        case .detour: return "Detour"
        }
    }
}

struct VeyraPullCount: Identifiable {
    var kind: VeyraPullKind
    var count: Int
    var id: String { kind.id }
}

struct VeyraRouteSeal: Identifiable, Codable, Hashable {
    var id: UUID
    var routeID: UUID
    var carriedIDs: [UUID]
    var residue: String
    var sealedOn: Date
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
    var pullKind: String? = nil
    var pullHour: Int? = nil

    var veyraOrdinal: Int { ordinal ?? 0 }

    var veyraPull: VeyraPullKind {
        VeyraPullKind(rawValue: pullKind ?? "") ?? .light
    }

    enum CodingKeys: String, CodingKey {
        case id, tripID, iconGlyph, reflection, placeLine, stampedOn, pinnedHighlight, ordinal, photoFile, pullKind, pullHour
    }

    init(id: UUID, tripID: UUID, iconGlyph: String, reflection: String, placeLine: String, stampedOn: Date, pinnedHighlight: Bool, ordinal: Int? = nil, photoFile: String? = nil, pullKind: String? = nil, pullHour: Int? = nil) {
        self.id = id
        self.tripID = tripID
        self.iconGlyph = iconGlyph
        self.reflection = reflection
        self.placeLine = placeLine
        self.stampedOn = stampedOn
        self.pinnedHighlight = pinnedHighlight
        self.ordinal = ordinal
        self.photoFile = photoFile
        self.pullKind = pullKind
        self.pullHour = pullHour
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        tripID = try container.decode(UUID.self, forKey: .tripID)
        iconGlyph = try container.decode(String.self, forKey: .iconGlyph)
        reflection = try container.decode(String.self, forKey: .reflection)
        placeLine = try container.decode(String.self, forKey: .placeLine)
        stampedOn = try container.decode(Date.self, forKey: .stampedOn)
        pinnedHighlight = try container.decode(Bool.self, forKey: .pinnedHighlight)
        ordinal = try container.decodeIfPresent(Int.self, forKey: .ordinal)
        photoFile = try container.decodeIfPresent(String.self, forKey: .photoFile)
        pullKind = try container.decodeIfPresent(String.self, forKey: .pullKind)
        pullHour = try container.decodeIfPresent(Int.self, forKey: .pullHour)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tripID, forKey: .tripID)
        try container.encode(iconGlyph, forKey: .iconGlyph)
        try container.encode(reflection, forKey: .reflection)
        try container.encode(placeLine, forKey: .placeLine)
        try container.encode(stampedOn, forKey: .stampedOn)
        try container.encode(pinnedHighlight, forKey: .pinnedHighlight)
        try container.encodeIfPresent(ordinal, forKey: .ordinal)
        try container.encodeIfPresent(photoFile, forKey: .photoFile)
        try container.encodeIfPresent(pullKind, forKey: .pullKind)
        try container.encodeIfPresent(pullHour, forKey: .pullHour)
    }
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
        case cliff: return "Night stair"
        case desk: return "Close desk"
        case lantern: return "Amber lane"
        case lake: return "Quiet sill"
        default: return "Night scene"
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
        case .trips: return "Routes"
        case .notes: return "Pulls"
        case .stars: return "Carry"
        case .setup: return "Desk"
        }
    }

    var veyraSymbol: String {
        switch self {
        case .trips: return "veyraIconRoutes"
        case .notes: return "veyraIconPulls"
        case .stars: return "veyraIconCarry"
        case .setup: return "veyraIconDesk"
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
