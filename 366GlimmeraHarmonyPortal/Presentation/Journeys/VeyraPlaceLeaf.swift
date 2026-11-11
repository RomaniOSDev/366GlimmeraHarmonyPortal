import SwiftUI

struct VeyraPlaceLeaf: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    let placeLine: String
    @State private var composer: VeyraMomentSlip?

    var body: some View {
        VeyraScreen(still: VeyraStillRack.lake) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VeyraHeaderBlock(
                        title: placeLine,
                        detail: "Newest stops with this corner name, from every route."
                    )
                    let slips = vault.veyraMoments(at: placeLine)
                    if slips.isEmpty {
                        Text("No stops use this corner name now.")
                            .font(.subheadline)
                            .foregroundStyle(Color.veyraInk)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        ForEach(slips) { slip in
                            VeyraCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    if let photo = slip.photoFile {
                                        VeyraPhotoFrame(fileName: photo, height: 140)
                                    }
                                    Text("\(slip.iconGlyph)  \(vault.veyraTripTitle(slip.tripID))")
                                        .font(.headline)
                                        .foregroundStyle(Color.veyraInk)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
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
                                    NavigationLink {
                                        VeyraTripLeaf(tripID: slip.tripID)
                                    } label: {
                                        VeyraQuietLinkLabel(title: "Open route")
                                    }
                                    .buttonStyle(VeyraPressStyle())
                                    VeyraIconChip(title: "Edit", art: VeyraChromeArt.edit) {
                                        composer = slip
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Corner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(item: $composer) { slip in
            VeyraMomentComposer(starter: slip)
        }
    }
}

enum VeyraPlaceLeafQelmDrift {
    static func veyraPlaceLeafQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [7, 61, 26, 71, 37, 53]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 7) &+ mark
        }
    }
}
