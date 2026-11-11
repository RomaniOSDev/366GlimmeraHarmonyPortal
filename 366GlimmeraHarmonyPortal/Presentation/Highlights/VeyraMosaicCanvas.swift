import SwiftUI

struct VeyraMosaicCanvas: View {
    @EnvironmentObject private var vault: VeyraLedgerVault

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VeyraScreen(still: VeyraStillRack.lake) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VeyraStillFrame(key: VeyraStillRack.lake, height: 120)
                    VeyraHeaderBlock(
                        title: "Carry",
                        detail: "The latest close keeps up to three stops for the next walk. Move them to set the order."
                    )
                    if let seal = vault.veyraLatestSeal() {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 6) {
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
                                Text("Closed \(VeyraStampText.day(seal.sealedOn))")
                                    .font(.caption)
                                    .foregroundStyle(Color.veyraMint)
                                Text(vault.veyraQuietHourLabel())
                                    .font(.footnote)
                                    .foregroundStyle(Color.veyraInk.opacity(0.8))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    if let banner = vault.veyraBanner {
                        VeyraBannerLine(text: banner)
                    }
                    let pinned = vault.veyraCarriedMoments()
                    if pinned.isEmpty {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                VeyraEmptyMark(art: VeyraChromeArt.emptyCarry)
                                Text("Nothing carried yet")
                                    .font(.headline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Open a route and tap Close this route. Pick up to three stops and write the residue.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk.opacity(0.78))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                VeyraPrimaryButton(title: "Go to routes") {
                                    vault.veyraFocusLane = .trips
                                }
                            }
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(pinned.enumerated()), id: \.element.id) { index, moment in
                                VStack(alignment: .leading, spacing: 8) {
                                    if let photo = moment.photoFile, VeyraPhotoStore.image(named: photo) != nil {
                                        VeyraPhotoFrame(fileName: photo, height: 88)
                                    } else if let caption = vault.veyraCaption(for: moment.id) {
                                        VeyraStillFrame(key: caption.imageKey, height: 88)
                                    } else {
                                        Text(moment.iconGlyph)
                                            .font(.largeTitle)
                                            .frame(maxWidth: .infinity, minHeight: 88)
                                            .background(
                                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Color.veyraMint.opacity(0.45), Color.veyraGlow.opacity(0.35)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            )
                                    }
                                    VeyraPlaceLink(
                                        glyph: moment.iconGlyph,
                                        placeLine: moment.placeLine,
                                        font: .subheadline.weight(.semibold)
                                    )
                                    Text(moment.reflection)
                                        .font(.caption)
                                        .foregroundStyle(Color.veyraInk.opacity(0.78))
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                    NavigationLink {
                                        VeyraHighlightLeaf(momentID: moment.id)
                                    } label: {
                                        VeyraPlateLabel(
                                            title: "Open",
                                            plate: VeyraChromeArt.primaryPlate,
                                            titleColor: Color.veyraOnPrimary,
                                            minHeight: 40
                                        )
                                    }
                                    .buttonStyle(VeyraPressStyle())
                                    HStack(spacing: 6) {
                                        VeyraIconChip(title: "Up", art: VeyraChromeArt.up, enabled: index != 0) {
                                            vault.veyraNudgeHighlight(moment.id, upward: true)
                                        }
                                        VeyraIconChip(title: "Down", art: VeyraChromeArt.down, enabled: index != pinned.count - 1) {
                                            vault.veyraNudgeHighlight(moment.id, upward: false)
                                        }
                                    }
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.veyraCard)
                                        .shadow(color: Color.black.opacity(0.12), radius: 6, y: 3)
                                )
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

enum VeyraMosaicCanvasQelmDrift {
    static func veyraMosaicCanvasQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [9, 12, 7, 52, 65, 24]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 9) &+ mark
        }
    }
}
