import SwiftUI

struct VeyraCaptionRoll: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @State private var composerMoment: VeyraMomentSlip?
    @State private var pendingCaption: VeyraCaptionLeaf?

    var body: some View {
        VeyraScreen(still: VeyraStillRack.lantern) {
            List {
                Section {
                    VeyraStillFrame(key: VeyraStillRack.lantern, height: 120)
                    VeyraHeaderBlock(
                        title: "Captions",
                        detail: "Each caption stays attached to one moment and uses a scene picture from this set."
                    )
                    if let banner = vault.veyraBanner {
                        VeyraBannerLine(text: banner)
                    }
                    if vault.moments.isEmpty {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.veyraMint)
                                Text("Add your first travel moment")
                                    .font(.headline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("A caption needs a moment. Create one on the trip shelf first.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk.opacity(0.78))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                VeyraPrimaryButton(title: "Go to trips") {
                                    vault.veyraFocusLane = .trips
                                }
                            }
                        }
                    } else if vault.captions.isEmpty {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.veyraMint)
                                Text("Add your first travel moment")
                                    .font(.headline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Choose a saved moment and write the caption beside a scene picture.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk.opacity(0.78))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    if vault.moments.isEmpty == false {
                        VeyraPrimaryButton(title: "Write a caption") {
                            composerMoment = vault.moments.sorted { $0.stampedOn > $1.stampedOn }.first
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                ForEach(vault.captions.sorted { $0.stampedOn > $1.stampedOn }) { leaf in
                    NavigationLink {
                        VeyraCaptionEditor(starterMomentID: leaf.momentID)
                    } label: {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                VeyraStillFrame(key: leaf.imageKey, height: 110)
                                Text(vault.moments.first { $0.id == leaf.momentID }?.placeLine ?? "Moment")
                                    .font(.headline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(vault.veyraTripTitle(vault.moments.first { $0.id == leaf.momentID }?.tripID ?? UUID()))
                                    .font(.caption)
                                    .foregroundStyle(Color.veyraMint)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(leaf.captionBody)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk.opacity(0.84))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(VeyraStampText.day(leaf.stampedOn))
                                    .font(.caption)
                                    .foregroundStyle(Color.veyraInk.opacity(0.7))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            pendingCaption = leaf
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .scrollDismissesKeyboard(.immediately)
        }
        .sheet(item: $composerMoment) { moment in
            VeyraCaptionEditor(starterMomentID: moment.id)
        }
        .confirmationDialog(
            "Delete this caption?",
            isPresented: Binding(
                get: { pendingCaption != nil },
                set: { if $0 == false { pendingCaption = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let pendingCaption {
                    vault.veyraDeleteCaption(pendingCaption.id)
                }
                pendingCaption = nil
            }
            Button("Cancel", role: .cancel) {
                pendingCaption = nil
            }
        } message: {
            Text("The moment itself stays on the journey.")
        }
    }
}

enum VeyraCaptionRollQelmDrift {
    static func veyraCaptionRollQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [77, 28, 13, 77, 47, 73]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 77) &+ mark
        }
    }
}
