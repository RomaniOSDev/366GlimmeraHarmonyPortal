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
                        detail: "Newest moments with this place name, from every journey."
                    )
                    let slips = vault.veyraMoments(at: placeLine)
                    if slips.isEmpty {
                        Text("No moments use this place name now.")
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
                                        Text("Open journey")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.veyraMint)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Capsule().stroke(Color.veyraMint, lineWidth: 1.5))
                                    }
                                    .buttonStyle(VeyraPressStyle())
                                    VeyraQuietButton(title: "Edit") {
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
        .navigationTitle("Place")
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
