import SwiftUI

struct VeyraTripLeaf: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    let tripID: UUID
    @State private var editingTrip = false
    @State private var composer: VeyraMomentSlip?
    @State private var openedPlace: String?

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
                        VeyraQuietButton(title: "Edit journey") {
                            editingTrip = true
                        }
                        NavigationLink {
                            VeyraTripReading(tripID: trip.id)
                        } label: {
                            Text("Read journey")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.veyraMint)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Capsule().stroke(Color.veyraMint, lineWidth: 1.5))
                        }
                        .buttonStyle(VeyraPressStyle())
                        VeyraPrimaryButton(title: "Add a moment") {
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
                            Text("This timeline is waiting for the first moment.")
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
                                .accessibilityHint("Shows every moment at this place")
                                Text(VeyraStampText.day(slip.stampedOn))
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
                                    Text("In highlights")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.veyraMint)
                                }
                                HStack(spacing: 6) {
                                    Button("Up") {
                                        vault.veyraNudgeMoment(slip.id, upward: true)
                                    }
                                    .disabled(index == 0)
                                    Button("Down") {
                                        vault.veyraNudgeMoment(slip.id, upward: false)
                                    }
                                    .disabled(index == slips.count - 1)
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.veyraMint)
                                .buttonStyle(.bordered)
                                VeyraQuietButton(title: "Edit") {
                                    composer = slip
                                }
                                VeyraQuietButton(title: "Delete") {
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
                    Text("This journey is no longer on the shelf.")
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
        .navigationTitle("Timeline")
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
        .navigationDestination(isPresented: Binding(
            get: { openedPlace != nil },
            set: { if $0 == false { openedPlace = nil } }
        )) {
            VeyraPlaceLeaf(placeLine: openedPlace ?? "")
        }
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
