import SwiftUI

struct VeyraShelfCanvas: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @AppStorage("veyra.qelm.shelfOrder") private var shelfOrderRaw = VeyraShelfOrder.newest.rawValue
    @State private var makingTrip = false
    @State private var pendingDelete: VeyraTripFolio?
    @State private var query = ""

    private var shelfOrder: VeyraShelfOrder {
        VeyraShelfOrder(rawValue: shelfOrderRaw) ?? .newest
    }

    private var filteredTrips: [VeyraTripFolio] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matched = vault.trips.filter { trip in
            if needle.isEmpty { return true }
            if trip.title.lowercased().contains(needle) { return true }
            if trip.placeNote.lowercased().contains(needle) { return true }
            return vault.moments.contains { moment in
                moment.tripID == trip.id &&
                (moment.placeLine.lowercased().contains(needle) || moment.reflection.lowercased().contains(needle))
            }
        }
        switch shelfOrder {
        case .newest:
            return matched.sorted { $0.openedOn > $1.openedOn }
        case .oldest:
            return matched.sorted { $0.openedOn < $1.openedOn }
        case .title:
            return matched.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    var body: some View {
        VeyraScreen(still: VeyraStillRack.cliff) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    VeyraStillFrame(key: VeyraStillRack.cliff)
                    VeyraHeaderBlock(
                        title: "Route rail",
                        detail: "Open a walk, log what pulled you off it, then close the route with up to three carries."
                    )
                    if vault.veyraBriefIsOpen(), let seal = vault.veyraLatestSeal() {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Next-walk brief")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.veyraMint)
                                Text(vault.veyraTripTitle(seal.routeID))
                                    .font(.headline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(seal.residue)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk.opacity(0.86))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                let carried = vault.veyraCarriedMoments()
                                if carried.isEmpty == false {
                                    Text(carried.map(\.placeLine).joined(separator: " · "))
                                        .font(.footnote)
                                        .foregroundStyle(Color.veyraInk.opacity(0.8))
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Text(vault.veyraQuietHourLabel())
                                    .font(.footnote)
                                    .foregroundStyle(Color.veyraMint)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                VeyraQuietButton(title: "Brief read") {
                                    vault.veyraMarkBriefRead()
                                }
                            }
                        }
                    }
                    if let banner = vault.veyraBanner {
                        VeyraBannerLine(text: banner)
                    }
                    ForEach(vault.veyraAchievementLines(), id: \.self) { line in
                        Text(line)
                            .font(.footnote)
                            .foregroundStyle(Color.veyraInk.opacity(0.8))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if vault.showHints {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name the route, log the stop that pulled you aside, then close it with up to three carries.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                VeyraQuietButton(title: "Hide this hint") {
                                    vault.veyraDismissHints()
                                }
                            }
                        }
                    }
                    VeyraPrimaryButton(title: "Open a route") {
                        makingTrip = true
                    }
                    if vault.trips.isEmpty {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                VeyraEmptyMark(art: VeyraChromeArt.emptyRoute)
                                Text("No route is open")
                                    .font(.headline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Name the walk you want to close. Stops and a seal come after that.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk.opacity(0.78))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        VeyraFieldShell {
                            TextField("Search route, corner, or note", text: $query)
                                .foregroundStyle(Color.veyraInk)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .accessibilityLabel("Search routes")
                        }
                        HStack(spacing: 8) {
                            ForEach(VeyraShelfOrder.allCases) { item in
                                Button {
                                    shelfOrderRaw = item.rawValue
                                } label: {
                                    Text(item.veyraTitle)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(shelfOrder == item ? Color.veyraOnPrimary : Color.veyraGlow)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .padding(.horizontal, 8)
                                        .frame(maxWidth: .infinity, minHeight: 42)
                                        .background {
                                            VeyraPlateSkin(name: shelfOrder == item ? VeyraChromeArt.primaryPlate : VeyraChromeArt.quietPlate)
                                        }
                                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(VeyraPressStyle())
                            }
                        }
                        if let currentID = vault.currentItineraryID,
                           let current = filteredTrips.first(where: { $0.id == currentID }) {
                            VeyraCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Resume")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.veyraMint)
                                    HStack(alignment: .top, spacing: 10) {
                                        VeyraCoverThumb(key: current.veyraCover)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(current.title)
                                                .font(.headline)
                                                .foregroundStyle(Color.veyraInk)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Text(current.placeNote)
                                                .font(.subheadline)
                                                .foregroundStyle(Color.veyraInk.opacity(0.75))
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    NavigationLink {
                                        VeyraTripLeaf(tripID: current.id)
                                    } label: {
                                        VeyraPlateLabel(
                                            title: "Open route",
                                            plate: VeyraChromeArt.primaryPlate,
                                            titleColor: Color.veyraOnPrimary,
                                            minHeight: 48
                                        )
                                    }
                                    .buttonStyle(VeyraPressStyle())
                                }
                            }
                        }
                        if filteredTrips.isEmpty {
                            Text("Nothing matches that search.")
                                .font(.subheadline)
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            ForEach(filteredTrips) { trip in
                                VeyraTripFold(trip: trip, pendingDelete: $pendingDelete)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $makingTrip) {
            VeyraTripMaker(existing: nil)
        }
        .confirmationDialog(
            "Delete this route?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if $0 == false { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    vault.veyraDeleteTrip(pendingDelete.id)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text("Stops, pull notes, and the close stored for this route will be removed.")
        }
    }
}

private struct VeyraTripFold: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    let trip: VeyraTripFolio
    @Binding var pendingDelete: VeyraTripFolio?
    @State private var momentDraft: VeyraMomentSlip?

    var body: some View {
        VeyraCard {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 10) {
                    let slips = vault.veyraMoments(for: trip.id)
                    if slips.isEmpty {
                        Text("No stops on this route yet.")
                            .font(.subheadline)
                            .foregroundStyle(Color.veyraInk.opacity(0.78))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        ForEach(slips) { slip in
                            VStack(alignment: .leading, spacing: 4) {
                                if let photo = slip.photoFile {
                                    VeyraPhotoFrame(fileName: photo, height: 96)
                                }
                                VeyraPlaceLink(
                                    glyph: slip.iconGlyph,
                                    placeLine: slip.placeLine,
                                    font: .subheadline.weight(.semibold)
                                )
                                Text(slip.reflection)
                                    .font(.footnote)
                                    .foregroundStyle(Color.veyraInk.opacity(0.78))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(VeyraStampText.day(slip.stampedOn))
                                    .font(.caption)
                                    .foregroundStyle(Color.veyraMint)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    VeyraQuietButton(title: "Log a stop") {
                        momentDraft = VeyraMomentSlip(
                            id: UUID(),
                            tripID: trip.id,
                            iconGlyph: VeyraGlyphRack.marks[0],
                            reflection: "",
                            placeLine: "",
                            stampedOn: Date(),
                            pinnedHighlight: false
                        )
                    }
                    NavigationLink {
                        VeyraTripLeaf(tripID: trip.id)
                    } label: {
                        VeyraPlateLabel(
                            title: "Open route",
                            plate: VeyraChromeArt.primaryPlate,
                            titleColor: Color.veyraOnPrimary,
                            minHeight: 48
                        )
                    }
                    .buttonStyle(VeyraPressStyle())
                }
                .padding(.top, 8)
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    VeyraCoverThumb(key: trip.veyraCover)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.title)
                            .font(.headline)
                            .foregroundStyle(Color.veyraInk)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(trip.placeNote)
                            .font(.subheadline)
                            .foregroundStyle(Color.veyraInk.opacity(0.75))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(vault.veyraMoments(for: trip.id).count) stops · \(VeyraStampText.day(trip.openedOn))")
                            .font(.caption)
                            .foregroundStyle(Color.veyraMint)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .tint(Color.veyraMint)
            VeyraQuietButton(title: "Delete route") {
                pendingDelete = trip
            }
            .padding(.top, 8)
        }
        .sheet(item: $momentDraft) { slip in
            VeyraMomentComposer(starter: slip)
        }
    }
}

enum VeyraShelfCanvasQelmDrift {
    static func veyraShelfCanvasQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [74, 20, 62, 27, 27, 43]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 74) &+ mark
        }
    }
}
