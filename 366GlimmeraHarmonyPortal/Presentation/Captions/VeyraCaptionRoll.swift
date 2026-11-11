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
                        title: "Pull radar",
                        detail: "Every stop keeps the reason it stopped the walk. The peak pull and the quiet hour come from those tags."
                    )
                    VeyraCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(vault.veyraPeakPullLabel())
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(vault.veyraQuietHourLabel())
                                .font(.footnote)
                                .foregroundStyle(Color.veyraMint)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            ForEach(vault.veyraPullTally()) { row in
                                HStack {
                                    Text(row.kind.title)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.veyraInk)
                                        .frame(width: 72, alignment: .leading)
                                    GeometryReader { proxy in
                                        let width = vault.moments.isEmpty ? 0 : proxy.size.width * CGFloat(row.count) / CGFloat(max(vault.moments.count, 1))
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color.veyraMint)
                                            .frame(width: max(width, row.count == 0 ? 0 : 8), height: 8)
                                            .frame(maxHeight: .infinity, alignment: .leading)
                                    }
                                    .frame(height: 12)
                                    Text("\(row.count)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.veyraInk)
                                }
                            }
                        }
                    }
                    if let banner = vault.veyraBanner {
                        VeyraBannerLine(text: banner)
                    }
                    if vault.moments.isEmpty {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                VeyraEmptyMark(art: VeyraChromeArt.emptyPlus)
                                Text("No stops yet")
                                    .font(.headline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("A pull note needs a stop. Log one on the route rail first.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk.opacity(0.78))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                VeyraPrimaryButton(title: "Go to routes") {
                                    vault.veyraFocusLane = .trips
                                }
                            }
                        }
                    } else if vault.captions.isEmpty {
                        VeyraCard {
                            VStack(alignment: .leading, spacing: 8) {
                                VeyraEmptyMark(art: VeyraChromeArt.emptyPlus)
                                Text("No pull notes yet")
                                    .font(.headline)
                                    .foregroundStyle(Color.veyraInk)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("The tags are already on the stops. A pull note is the extra line you want to keep.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.veyraInk.opacity(0.78))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    if vault.moments.isEmpty == false {
                        VeyraPrimaryButton(title: "Write a pull note") {
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
                                Text(vault.moments.first { $0.id == leaf.momentID }?.placeLine ?? "Stop")
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
            "Delete this pull note?",
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
            Text("The stop itself stays on the route.")
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
