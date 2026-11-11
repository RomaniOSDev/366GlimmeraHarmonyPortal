import SwiftUI

struct VeyraWelcomeReel: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @State private var page = 0

    private let pages: [(still: String, headline: String, detail: String)] = [
        (VeyraStillRack.cliff, "Tag the pull", "When something stops the walk, log the corner and tag it: light, sound, crowd, weather, memory, or detour."),
        (VeyraStillRack.lantern, "Close the route", "Pick up to three stops to carry and write the residue that the next walk should remember."),
        (VeyraStillRack.lake, "Read the brief", "The route rail keeps that close until you mark the brief read, with the quietest hour you usually log.")
    ]

    var body: some View {
        VeyraScreen(still: pages[page].still) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Lantern Close")
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundStyle(Color.veyraInk)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Tap a numbered seal to move between notes. The route rail opens after the last one.")
                        .font(.subheadline)
                        .foregroundStyle(Color.veyraInk.opacity(0.78))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 12) {
                            ForEach(pages.indices, id: \.self) { index in
                                Button {
                                    page = index
                                } label: {
                                    Text("\(index + 1)")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(page == index ? Color.veyraOnPrimary : Color.veyraGlow)
                                        .frame(width: 48, height: 48)
                                        .background {
                                            VeyraPlateSkin(name: page == index ? VeyraChromeArt.primaryPlate : VeyraChromeArt.quietPlate)
                                                .shadow(color: Color.black.opacity(page == index ? 0.35 : 0.18), radius: 6, y: 3)
                                        }
                                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(VeyraPressStyle())
                                .accessibilityLabel("Note \(index + 1)")
                                .accessibilityAddTraits(page == index ? .isSelected : [])
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            veyraSeal(pages[page].still)
                            Text(pages[page].headline)
                                .font(.system(.title2, design: .serif).weight(.bold))
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(pages[page].detail)
                                .font(.body)
                                .foregroundStyle(Color.veyraInk.opacity(0.84))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.veyraCard)
                                .shadow(color: Color.black.opacity(0.14), radius: 8, y: 5)
                        )
                    }

                    Button {
                        if page == pages.count - 1 {
                            vault.veyraMarkWelcomeDone()
                        } else {
                            page += 1
                        }
                    } label: {
                        VeyraPlateLabel(
                            title: page == pages.count - 1 ? "Open the rail" : "Next note",
                            plate: VeyraChromeArt.primaryPlate,
                            titleColor: Color.veyraOnPrimary
                        )
                    }
                    .buttonStyle(VeyraPressStyle())

                    Button {
                        vault.veyraMarkWelcomeDone()
                    } label: {
                        VeyraQuietLinkLabel(title: "Skip to the rail")
                    }
                    .buttonStyle(VeyraPressStyle())
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }

    private func veyraSeal(_ key: String) -> some View {
        Color.clear
            .frame(width: 108, height: 108)
            .overlay {
                Image(key)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.veyraGlow, lineWidth: 3))
            .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)
            .accessibilityHidden(true)
    }
}

enum VeyraWelcomeReelQelmDrift {
    static func veyraWelcomeReelQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [20, 11, 40, 19, 63, 60]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 20) &+ mark
        }
    }
}
