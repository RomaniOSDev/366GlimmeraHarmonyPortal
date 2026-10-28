import Foundation
import UIKit

enum VeyraPhotoStore {
    static func image(named name: String) -> UIImage? {
        let url = folder().appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func write(_ data: Data, id: UUID) -> String? {
        guard let source = UIImage(data: data) else { return nil }
        let fitted = veyraFitted(source, maxSide: 1600)
        guard let jpeg = fitted.jpegData(compressionQuality: 0.82) else { return nil }
        let name = "\(id.uuidString).jpg"
        do {
            try jpeg.write(to: folder().appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func remove(_ name: String?) {
        guard let name, name.isEmpty == false else { return }
        try? FileManager.default.removeItem(at: folder().appendingPathComponent(name))
    }

    static func removeAll() {
        try? FileManager.default.removeItem(at: folder())
    }

    static func sweep(keeping names: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: folder(),
            includingPropertiesForKeys: nil
        ) else { return }
        for url in files where names.contains(url.lastPathComponent) == false {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func folder() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VeyraMomentPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    private static func veyraFitted(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxSide, longest > 0 else { return image }
        let scale = maxSide / longest
        let next = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: next).image { _ in
            image.draw(in: CGRect(origin: .zero, size: next))
        }
    }
}

private struct VeyraMomentUndo {
    var slip: VeyraMomentSlip
    var caption: VeyraCaptionLeaf?
    var highlightIndex: Int?
}

extension Notification.Name {
    static let dataReset = Notification.Name("veyraQelmDataReset")
}

enum VeyraVaultKey {
    static let seen = "veyra.qelm.seenWelcome"
    static let hints = "veyra.qelm.showHints"
    static let trips = "veyra.qelm.trips"
    static let moments = "veyra.qelm.scrapbooks"
    static let captions = "veyra.qelm.captions"
    static let order = "veyra.qelm.highlightOrder"
    static let current = "veyra.qelm.currentItinerary"
    static let achievements = "veyra.qelm.achievements"
    static let lastActivity = "veyra.qelm.lastActivity"
}

@MainActor
final class VeyraLedgerVault: ObservableObject {
    @Published var hasSeenOnboarding: Bool
    @Published var showHints: Bool
    @Published var trips: [VeyraTripFolio]
    @Published var moments: [VeyraMomentSlip]
    @Published var captions: [VeyraCaptionLeaf]
    @Published var highlightOrder: [UUID]
    @Published var currentItineraryID: UUID?
    @Published var achievementsUnlocked: [String: Date]
    @Published var lastActivityDate: Date?
    @Published var veyraBanner: String?
    @Published var veyraFocusLane: VeyraDockLane?
    @Published var undoNote: String?

    private var veyraFlashTask: Task<Void, Never>?
    private var undoTask: Task<Void, Never>?
    private var undoToken = UUID()
    private var momentUndo: VeyraMomentUndo?
    private let veyraDefaults = UserDefaults.standard

    init() {
        hasSeenOnboarding = veyraDefaults.bool(forKey: VeyraVaultKey.seen)
        if veyraDefaults.object(forKey: VeyraVaultKey.hints) == nil {
            showHints = true
        } else {
            showHints = veyraDefaults.bool(forKey: VeyraVaultKey.hints)
        }
        trips = Self.veyraDecode([VeyraTripFolio].self, key: VeyraVaultKey.trips, defaults: veyraDefaults) ?? []
        moments = Self.veyraDecode([VeyraMomentSlip].self, key: VeyraVaultKey.moments, defaults: veyraDefaults) ?? []
        captions = Self.veyraDecode([VeyraCaptionLeaf].self, key: VeyraVaultKey.captions, defaults: veyraDefaults) ?? []
        highlightOrder = Self.veyraDecode([UUID].self, key: VeyraVaultKey.order, defaults: veyraDefaults) ?? []
        if let raw = veyraDefaults.string(forKey: VeyraVaultKey.current) {
            currentItineraryID = UUID(uuidString: raw)
        } else {
            currentItineraryID = nil
        }
        achievementsUnlocked = Self.veyraDecode([String: Date].self, key: VeyraVaultKey.achievements, defaults: veyraDefaults) ?? [:]
        if let stamp = Self.veyraDecode(Date.self, key: VeyraVaultKey.lastActivity, defaults: veyraDefaults) {
            lastActivityDate = stamp
        } else {
            lastActivityDate = nil
        }
        veyraBackfillMarks()
        VeyraPhotoStore.sweep(keeping: Set(moments.compactMap(\.photoFile)))
    }

    func veyraMarkWelcomeDone() {
        hasSeenOnboarding = true
        veyraPersist()
    }

    func veyraRememberCurrent(_ id: UUID) {
        guard currentItineraryID != id else { return }
        currentItineraryID = id
        veyraPersist()
    }

    func veyraDismissHints() {
        showHints = false
        veyraPersist()
    }

    func veyraSaveTrip(_ trip: VeyraTripFolio) {
        let isNew = trips.contains(where: { $0.id == trip.id }) == false
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
        } else {
            trips.append(trip)
        }
        currentItineraryID = trip.id
        if isNew, achievementsUnlocked["first-journey"] == nil {
            achievementsUnlocked["first-journey"] = Date()
        }
        veyraTouch()
        veyraPersist()
        veyraPulse()
        veyraFlash("Journey saved.")
    }

    func veyraSaveMoment(_ slip: VeyraMomentSlip) {
        var next = slip
        let isNew = moments.contains(where: { $0.id == slip.id }) == false
        if isNew {
            next.ordinal = veyraOrdinalForNew(next)
        } else if let existing = moments.first(where: { $0.id == slip.id }) {
            if existing.photoFile != next.photoFile {
                VeyraPhotoStore.remove(existing.photoFile)
            }
            next.ordinal = existing.veyraOrdinal
        }
        if let index = moments.firstIndex(where: { $0.id == next.id }) {
            moments[index] = next
        } else {
            moments.append(next)
        }
        if next.pinnedHighlight {
            if highlightOrder.contains(next.id) == false {
                highlightOrder.append(next.id)
            }
        } else {
            highlightOrder.removeAll { $0 == next.id }
        }
        currentItineraryID = next.tripID
        if isNew, achievementsUnlocked["first-moment"] == nil {
            achievementsUnlocked["first-moment"] = Date()
        }
        veyraNotePlaces()
        veyraTouch()
        veyraPersist()
        veyraPulse()
        veyraFlash(next.pinnedHighlight ? "Moment saved and added to highlights." : "Moment saved to the journey.")
    }

    func veyraSaveCaption(_ leaf: VeyraCaptionLeaf) {
        let isNew = captions.contains(where: { $0.momentID == leaf.momentID || $0.id == leaf.id }) == false
        if let index = captions.firstIndex(where: { $0.momentID == leaf.momentID }) {
            var next = leaf
            next.id = captions[index].id
            captions[index] = next
        } else if let index = captions.firstIndex(where: { $0.id == leaf.id }) {
            captions[index] = leaf
        } else {
            captions.append(leaf)
        }
        if isNew, achievementsUnlocked["first-caption"] == nil {
            achievementsUnlocked["first-caption"] = Date()
        }
        veyraTouch()
        veyraPersist()
        veyraPulse()
        veyraFlash("Caption saved beside the moment.")
    }

    func veyraDeleteTrip(_ id: UUID) {
        if let undo = momentUndo, undo.slip.tripID == id {
            VeyraPhotoStore.remove(undo.slip.photoFile)
            undoToken = UUID()
            undoTask?.cancel()
            momentUndo = nil
            undoNote = nil
        }
        let doomed = moments.filter { $0.tripID == id }
        for slip in doomed {
            VeyraPhotoStore.remove(slip.photoFile)
        }
        let momentIDs = doomed.map(\.id)
        trips.removeAll { $0.id == id }
        moments.removeAll { $0.tripID == id }
        captions.removeAll { momentIDs.contains($0.momentID) }
        highlightOrder.removeAll { momentIDs.contains($0) }
        if currentItineraryID == id {
            currentItineraryID = nil
        }
        veyraTouch()
        veyraPersist()
        veyraFlash("Journey removed.")
    }

    func veyraDeleteMoment(_ id: UUID) {
        if momentUndo?.slip.id == id {
            undoToken = UUID()
            undoTask?.cancel()
            momentUndo = nil
            undoNote = nil
        }
        if let file = moments.first(where: { $0.id == id })?.photoFile {
            VeyraPhotoStore.remove(file)
        }
        moments.removeAll { $0.id == id }
        captions.removeAll { $0.momentID == id }
        highlightOrder.removeAll { $0 == id }
        veyraTouch()
        veyraPersist()
        veyraFlash("Moment removed.")
    }

    func veyraStageMomentRemoval(_ id: UUID) {
        guard let slip = moments.first(where: { $0.id == id }) else { return }
        if let previous = momentUndo {
            VeyraPhotoStore.remove(previous.slip.photoFile)
        }
        undoTask?.cancel()
        let caption = captions.first { $0.momentID == id }
        let highlightIndex = highlightOrder.firstIndex(of: id)
        moments.removeAll { $0.id == id }
        captions.removeAll { $0.momentID == id }
        highlightOrder.removeAll { $0 == id }
        momentUndo = VeyraMomentUndo(slip: slip, caption: caption, highlightIndex: highlightIndex)
        undoNote = "Moment removed."
        undoToken = UUID()
        let token = undoToken
        veyraTouch()
        veyraPersist()
        veyraPulse()
        undoTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard Task.isCancelled == false, self.undoToken == token else { return }
            self.veyraExpireUndo()
        }
    }

    func veyraUndoMomentDelete() {
        guard let undo = momentUndo else { return }
        undoToken = UUID()
        undoTask?.cancel()
        moments.append(undo.slip)
        if let caption = undo.caption {
            captions.append(caption)
        }
        if undo.slip.pinnedHighlight, highlightOrder.contains(undo.slip.id) == false {
            if let index = undo.highlightIndex, highlightOrder.indices.contains(index) {
                highlightOrder.insert(undo.slip.id, at: index)
            } else {
                highlightOrder.append(undo.slip.id)
            }
        }
        momentUndo = nil
        undoNote = nil
        veyraTouch()
        veyraPersist()
        veyraFlash("Moment restored.")
    }

    func veyraDeleteCaption(_ id: UUID) {
        captions.removeAll { $0.id == id }
        veyraTouch()
        veyraPersist()
        veyraFlash("Caption removed.")
    }

    func veyraNudgeHighlight(_ id: UUID, upward: Bool) {
        guard let index = highlightOrder.firstIndex(of: id) else { return }
        let target = upward ? index - 1 : index + 1
        guard highlightOrder.indices.contains(target) else { return }
        highlightOrder.swapAt(index, target)
        veyraTouch()
        veyraPersist()
    }

    func veyraNudgeMoment(_ id: UUID, upward: Bool) {
        guard let tripID = moments.first(where: { $0.id == id })?.tripID else { return }
        var ordered = veyraMoments(for: tripID)
        guard ordered.count > 1, let index = ordered.firstIndex(where: { $0.id == id }) else { return }
        let target = upward ? index - 1 : index + 1
        guard ordered.indices.contains(target) else { return }
        let shared = ordered[0].veyraOrdinal
        if ordered.allSatisfy({ $0.veyraOrdinal == shared }) {
            for (offset, item) in ordered.enumerated() {
                guard let idx = moments.firstIndex(where: { $0.id == item.id }) else { continue }
                moments[idx].ordinal = offset
            }
            ordered = veyraMoments(for: tripID)
        }
        guard let freshIndex = ordered.firstIndex(where: { $0.id == id }) else { return }
        let freshTarget = upward ? freshIndex - 1 : freshIndex + 1
        guard ordered.indices.contains(freshTarget),
              let left = moments.firstIndex(where: { $0.id == ordered[freshIndex].id }),
              let right = moments.firstIndex(where: { $0.id == ordered[freshTarget].id }) else { return }
        let leftOrdinal = moments[left].veyraOrdinal
        let rightOrdinal = moments[right].veyraOrdinal
        if leftOrdinal == rightOrdinal {
            moments[left].ordinal = freshTarget
            moments[right].ordinal = freshIndex
        } else {
            moments[left].ordinal = rightOrdinal
            moments[right].ordinal = leftOrdinal
        }
        veyraTouch()
        veyraPersist()
    }

    func veyraUnpin(_ id: UUID) {
        guard let index = moments.firstIndex(where: { $0.id == id }) else { return }
        moments[index].pinnedHighlight = false
        highlightOrder.removeAll { $0 == id }
        veyraTouch()
        veyraPersist()
        veyraFlash("Removed from highlights.")
    }

    func veyraResetAll() {
        hasSeenOnboarding = false
        showHints = true
        trips = []
        moments = []
        captions = []
        highlightOrder = []
        currentItineraryID = nil
        achievementsUnlocked = [:]
        lastActivityDate = nil
        veyraBanner = nil
        undoToken = UUID()
        undoTask?.cancel()
        momentUndo = nil
        undoNote = nil
        VeyraPhotoStore.removeAll()
        veyraPersist()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func veyraMoments(for tripID: UUID) -> [VeyraMomentSlip] {
        moments.filter { $0.tripID == tripID }.sorted { lhs, rhs in
            if lhs.veyraOrdinal == rhs.veyraOrdinal {
                return lhs.stampedOn < rhs.stampedOn
            }
            return lhs.veyraOrdinal < rhs.veyraOrdinal
        }
    }

    func veyraMoments(at placeLine: String) -> [VeyraMomentSlip] {
        let key = veyraPlaceKey(placeLine)
        guard key.isEmpty == false else { return [] }
        return moments.filter { veyraPlaceKey($0.placeLine) == key }.sorted { $0.stampedOn > $1.stampedOn }
    }

    func veyraDistinctPlaceCount() -> Int {
        Set(moments.map { veyraPlaceKey($0.placeLine) }.filter { $0.isEmpty == false }).count
    }

    func veyraAchievementLines() -> [String] {
        var lines: [String] = []
        if let date = achievementsUnlocked["first-journey"] {
            lines.append("First journey saved \(VeyraStampText.day(date)).")
        }
        if let date = achievementsUnlocked["first-moment"] {
            lines.append("First moment saved \(VeyraStampText.day(date)).")
        }
        if let date = achievementsUnlocked["first-caption"] {
            lines.append("First caption saved \(VeyraStampText.day(date)).")
        }
        if let date = achievementsUnlocked["three-places"] {
            lines.append("Three different places saved \(VeyraStampText.day(date)).")
        }
        return lines
    }

    func veyraHighlightMoments() -> [VeyraMomentSlip] {
        let pinned = moments.filter(\.pinnedHighlight)
        return pinned.sorted { lhs, rhs in
            let left = highlightOrder.firstIndex(of: lhs.id) ?? Int.max
            let right = highlightOrder.firstIndex(of: rhs.id) ?? Int.max
            if left == right { return lhs.stampedOn < rhs.stampedOn }
            return left < right
        }
    }

    func veyraCaption(for momentID: UUID) -> VeyraCaptionLeaf? {
        captions.first { $0.momentID == momentID }
    }

    func veyraTripTitle(_ id: UUID) -> String {
        trips.first { $0.id == id }?.title ?? "Journey"
    }

    func veyraFlash(_ text: String) {
        veyraBanner = text
        veyraFlashTask?.cancel()
        veyraFlashTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            guard Task.isCancelled == false else { return }
            self.veyraBanner = nil
        }
    }

    private func veyraExpireUndo() {
        if let undo = momentUndo {
            VeyraPhotoStore.remove(undo.slip.photoFile)
        }
        momentUndo = nil
        undoNote = nil
    }

    private func veyraOrdinalForNew(_ slip: VeyraMomentSlip) -> Int {
        let peers = moments.filter { $0.tripID == slip.tripID && $0.id != slip.id }
        if peers.isEmpty || peers.allSatisfy({ $0.veyraOrdinal == 0 }) {
            return 0
        }
        return (peers.map(\.veyraOrdinal).max() ?? 0) + 1
    }

    private func veyraPlaceKey(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func veyraNotePlaces() {
        guard veyraDistinctPlaceCount() >= 3, achievementsUnlocked["three-places"] == nil else { return }
        achievementsUnlocked["three-places"] = Date()
    }

    private func veyraBackfillMarks() {
        var changed = false
        if trips.isEmpty == false, achievementsUnlocked["first-journey"] == nil {
            achievementsUnlocked["first-journey"] = trips.map(\.openedOn).min() ?? Date()
            changed = true
        }
        if moments.isEmpty == false, achievementsUnlocked["first-moment"] == nil {
            achievementsUnlocked["first-moment"] = moments.map(\.stampedOn).min() ?? Date()
            changed = true
        }
        if captions.isEmpty == false, achievementsUnlocked["first-caption"] == nil {
            achievementsUnlocked["first-caption"] = captions.map(\.stampedOn).min() ?? Date()
            changed = true
        }
        if veyraDistinctPlaceCount() >= 3, achievementsUnlocked["three-places"] == nil {
            achievementsUnlocked["three-places"] = Date()
            changed = true
        }
        if changed {
            veyraPersist()
        }
    }

    private func veyraTouch() {
        lastActivityDate = Date()
    }

    private func veyraPulse() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func veyraPersist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        func pack<T: Encodable>(_ value: T, _ key: String) {
            if let data = try? encoder.encode(value) {
                veyraDefaults.set(data, forKey: key)
            }
        }
        veyraDefaults.set(hasSeenOnboarding, forKey: VeyraVaultKey.seen)
        veyraDefaults.set(showHints, forKey: VeyraVaultKey.hints)
        pack(trips, VeyraVaultKey.trips)
        pack(moments, VeyraVaultKey.moments)
        pack(captions, VeyraVaultKey.captions)
        pack(highlightOrder, VeyraVaultKey.order)
        pack(achievementsUnlocked, VeyraVaultKey.achievements)
        if let currentItineraryID {
            veyraDefaults.set(currentItineraryID.uuidString, forKey: VeyraVaultKey.current)
        } else {
            veyraDefaults.removeObject(forKey: VeyraVaultKey.current)
        }
        if let lastActivityDate {
            pack(lastActivityDate, VeyraVaultKey.lastActivity)
        } else {
            veyraDefaults.removeObject(forKey: VeyraVaultKey.lastActivity)
        }
    }

    private static func veyraDecode<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(type, from: data)
    }
}

enum VeyraLedgerVaultQelmDrift {
    static func veyraLedgerVaultQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [25, 82, 6, 48, 10, 73]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 25) &+ mark
        }
    }
}
