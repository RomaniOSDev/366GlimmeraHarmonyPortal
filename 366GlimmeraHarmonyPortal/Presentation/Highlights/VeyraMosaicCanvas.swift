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
                        title: "Highlights",
                        detail: "Moments you mark appear here. Move them up or down to set the order."
                    )
                    if let banner = vault.veyraBanner {
                        VeyraBannerLine(text: banner)
                    }
                    let pinned = vault.veyraHighlightMoments()
                    if pinned.isEmpty {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "star.circle")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.veyraMint)
                                Text("No Highlights Yet")
                                    .font(.headline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Open a moment and turn on Show in highlights.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk.opacity(0.78))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                VeyraPrimaryButton(title: "Go to trips") {
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
                                        Text("Open")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color.veyraOnPrimary)
                                            .frame(maxWidth: .infinity, minHeight: 36)
                                            .background(Capsule().fill(Color.veyraMint))
                                    }
                                    .buttonStyle(VeyraPressStyle())
                                    HStack(spacing: 6) {
                                        Button("Up") {
                                            vault.veyraNudgeHighlight(moment.id, upward: true)
                                        }
                                        .disabled(index == 0)
                                        Button("Down") {
                                            vault.veyraNudgeHighlight(moment.id, upward: false)
                                        }
                                        .disabled(index == pinned.count - 1)
                                    }
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.veyraMint)
                                    .buttonStyle(.bordered)
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
