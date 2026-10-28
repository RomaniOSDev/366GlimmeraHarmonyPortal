import SwiftUI

struct VeyraWelcomeReel: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @State private var page = 0

    private let pages: [(still: String, headline: String, detail: String)] = [
        (VeyraStillRack.cliff, "Capture Moments", "Write a place, choose an icon, and keep the note inside a journey you can open later."),
        (VeyraStillRack.lantern, "Add Annotations", "Attach a short caption and one scene picture to a moment you already saved."),
        (VeyraStillRack.lake, "Start Your Journey", "Create a journey, add the first moment, then mark the ones you want in the highlight mosaic.")
    ]

    var body: some View {
        VeyraScreen(still: pages[page].still) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Field notes")
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundStyle(Color.veyraInk)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Tap a wax seal to move between notes. The shelf opens after the last one.")
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
                                        .foregroundStyle(page == index ? Color.veyraOnPrimary : Color.veyraMint)
                                        .frame(width: 48, height: 48)
                                        .background {
                                            if page == index {
                                                Circle().fill(
                                                    LinearGradient(colors: [Color.veyraMint, Color.veyraGlow], startPoint: .top, endPoint: .bottom)
                                                )
                                            } else {
                                                Circle().fill(Color.veyraCard)
                                            }
                                        }
                                        .overlay(Circle().stroke(Color.veyraMint, lineWidth: 1.5))
                                        .shadow(color: Color.veyraMint.opacity(page == index ? 0.35 : 0), radius: 6, y: 3)
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
                        Text(page == pages.count - 1 ? "Open the shelf" : "Next note")
                            .font(.headline)
                            .foregroundStyle(Color.veyraOnPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule().fill(
                                    LinearGradient(colors: [Color.veyraMint, Color.veyraGlow], startPoint: .leading, endPoint: .trailing)
                                )
                                .shadow(color: Color.veyraMint.opacity(0.3), radius: 8, y: 4)
                            )
                    }
                    .buttonStyle(VeyraPressStyle())

                    Button {
                        vault.veyraMarkWelcomeDone()
                    } label: {
                        Text("Skip the walk")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraMint)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, minHeight: 44)
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
