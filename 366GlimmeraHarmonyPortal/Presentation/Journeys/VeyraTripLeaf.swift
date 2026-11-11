import SwiftUI

struct VeyraTripLeaf: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    let tripID: UUID
    @State private var editingTrip = false
    @State private var composer: VeyraMomentSlip?
    @State private var openedPlace: String?
    @State private var sealing = false

    private var trip: VeyraTripFolio? {
        vault.trips.first { $0.id == tripID }
    }

    var body: some View {
        VeyraScreen(still: trip?.veyraCover ?? VeyraStillRack.lantern) {
            List {
                if let trip {
                    Section {
                        VeyraStillFrame(key: trip.veyraCover, height: 120)
                        VeyraHeaderBlock(title: trip.title, detail: trip.placeNote)
                        Text("Opened \(VeyraStampText.day(trip.openedOn))")
                            .font(.footnote)
                            .foregroundStyle(Color.veyraMint)
                        if let banner = vault.veyraBanner {
                            VeyraBannerLine(text: banner)
                        }
                        VeyraQuietButton(title: "Edit route") {
                            editingTrip = true
                        }
                        NavigationLink {
                            VeyraTripReading(tripID: trip.id)
                        } label: {
                            VeyraQuietLinkLabel(title: "Read the route")
                        }
                        .buttonStyle(VeyraPressStyle())
                        VeyraPrimaryButton(title: vault.veyraSeal(for: trip.id) == nil ? "Close this route" : "Revise the close") {
                            sealing = true
                        }
                        .disabled(vault.veyraMoments(for: trip.id).isEmpty)
                        VeyraPrimaryButton(title: "Log a stop") {
                            composer = VeyraMomentSlip(
                                id: UUID(),
                                tripID: trip.id,
                                iconGlyph: VeyraGlyphRack.marks[0],
                                reflection: "",
                                placeLine: "",
                                stampedOn: Date(),
                                pinnedHighlight: false
                            )
                        }
                        let slips = vault.veyraMoments(for: trip.id)
                        if slips.isEmpty {
                            Text("This route is waiting for the first stop. Tag what pulled you aside, then close it.")
                                .font(.subheadline)
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    let slips = vault.veyraMoments(for: trip.id)
                    ForEach(Array(slips.enumerated()), id: \.element.id) { index, slip in
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 6) {
                                if let photo = slip.photoFile {
                                    VeyraPhotoFrame(fileName: photo, height: 150)
                                }
                                Button {
                                    openedPlace = slip.placeLine
                                } label: {
                                    Text("\(slip.iconGlyph)  \(slip.placeLine)")
                                        .font(.headline)
                                        .foregroundStyle(Color.veyraInk)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Shows every stop at this corner")
                                Text("\(slip.veyraPull.title) · \(VeyraStampText.day(slip.stampedOn))")
                                    .font(.caption)
                                    .foregroundStyle(Color.veyraMint)
                                Text(slip.reflection)
                                    .font(.body)
                                    .foregroundStyle(Color.veyraInk.opacity(0.86))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let caption = vault.veyraCaption(for: slip.id) {
                                    Text(caption.captionBody)
                                        .font(.footnote)
                                        .foregroundStyle(Color.veyraInk.opacity(0.75))
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                if slip.pinnedHighlight {
                                    Text("In the carry")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.veyraMint)
                                }
                                HStack(spacing: 6) {
                                    VeyraIconChip(title: "Up", art: VeyraChromeArt.up, enabled: index != 0) {
                                        vault.veyraNudgeMoment(slip.id, upward: true)
                                    }
                                    VeyraIconChip(title: "Down", art: VeyraChromeArt.down, enabled: index != slips.count - 1) {
                                        vault.veyraNudgeMoment(slip.id, upward: false)
                                    }
                                }
                                VeyraIconChip(title: "Edit", art: VeyraChromeArt.edit) {
                                    composer = slip
                                }
                                VeyraIconChip(title: "Delete", art: VeyraChromeArt.delete) {
                                    vault.veyraStageMomentRemoval(slip.id)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                vault.veyraStageMomentRemoval(slip.id)
                            }
                        }
                        .contextMenu {
                            Button("Edit") { composer = slip }
                            Button("Delete", role: .destructive) {
                                vault.veyraStageMomentRemoval(slip.id)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                } else {
                    Text("This route is no longer on the rail.")
                        .font(.body)
                        .foregroundStyle(Color.veyraInk)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Route")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear {
            vault.veyraRememberCurrent(tripID)
        }
        .sheet(isPresented: $editingTrip) {
            if let trip {
                VeyraTripMaker(existing: trip)
            }
        }
        .sheet(item: $composer) { slip in
            VeyraMomentComposer(starter: slip)
        }
        .sheet(isPresented: $sealing) {
            VeyraRouteSealSheet(tripID: tripID)
        }
        .navigationDestination(isPresented: Binding(
            get: { openedPlace != nil },
            set: { if $0 == false { openedPlace = nil } }
        )) {
            VeyraPlaceLeaf(placeLine: openedPlace ?? "")
        }
    }
}

private struct VeyraRouteSealSheet: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @Environment(\.dismiss) private var dismiss
    let tripID: UUID

    @State private var picked: Set<UUID> = []
    @State private var residue = ""
    @State private var trouble: String?

    var body: some View {
        NavigationStack {
            VeyraScreen(still: VeyraStillRack.desk) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VeyraHeaderBlock(
                            title: "Close the route",
                            detail: "Pick up to three stops to carry into the next walk, then write what is still unfinished."
                        )
                        ForEach(vault.veyraMoments(for: tripID)) { slip in
                            Button {
                                veyraToggle(slip.id)
                            } label: {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(slip.iconGlyph)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(slip.placeLine)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.veyraInk)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(slip.veyraPull.title)
                                            .font(.caption)
                                            .foregroundStyle(Color.veyraMint)
                                    }
                                    Spacer(minLength: 8)
                                    if picked.contains(slip.id) {
                                        VeyraGlyphMark(name: VeyraChromeArt.check, size: 24)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.veyraCard)
                                )
                            }
                            .buttonStyle(VeyraPressStyle())
                        }
                        Text("Residue")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraInk)
                        VeyraFieldShell {
                            TextField("What should the next walk remember?", text: $residue)
                                .foregroundStyle(Color.veyraInk)
                        }
                        Text("\(picked.count) of 3 selected")
                            .font(.footnote)
                            .foregroundStyle(Color.veyraMint)
                        if let trouble {
                            Text(trouble)
                                .font(.footnote)
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        VeyraPrimaryButton(title: "Seal route") {
                            veyraCommit()
                        }
                        VeyraQuietButton(title: "Cancel") {
                            dismiss()
                        }
                    }
                    .padding(16)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Close")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
        }
        .veyraHoldSheetOpen()
        .onAppear {
            if let seal = vault.veyraSeal(for: tripID) {
                picked = Set(seal.carriedIDs.prefix(3))
                residue = seal.residue
            } else {
                let offered = vault.veyraMoments(for: tripID).filter(\.pinnedHighlight).prefix(3)
                picked = Set(offered.map(\.id))
            }
        }
    }

    private func veyraToggle(_ id: UUID) {
        if picked.contains(id) {
            picked.remove(id)
        } else if picked.count < 3 {
            picked.insert(id)
        } else {
            trouble = "Carry at most three stops."
        }
    }

    private func veyraCommit() {
        let note = residue.trimmingCharacters(in: .whitespacesAndNewlines)
        if picked.isEmpty {
            trouble = "Pick at least one stop to carry."
            return
        }
        if note.isEmpty {
            trouble = "Write the residue before sealing."
            return
        }
        let ordered = vault.veyraMoments(for: tripID).map(\.id).filter { picked.contains($0) }
        vault.veyraSaveSeal(routeID: tripID, carriedIDs: ordered, residue: note)
        dismiss()
    }
}

enum VeyraTripLeafQelmDrift {
    static func veyraTripLeafQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [10, 65, 58, 66, 38, 22]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 10) &+ mark
        }
    }
}
