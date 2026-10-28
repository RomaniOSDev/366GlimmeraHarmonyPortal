import SwiftUI

struct VeyraHighlightLeaf: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @Environment(\.dismiss) private var dismiss
    let momentID: UUID
    @State private var composer: VeyraMomentSlip?
    @State private var confirmUnpin = false

    private var moment: VeyraMomentSlip? {
        vault.moments.first { $0.id == momentID }
    }

    var body: some View {
        VeyraScreen(still: vault.veyraCaption(for: momentID)?.imageKey ?? VeyraStillRack.lake) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let moment {
                        if let photo = moment.photoFile {
                            VeyraPhotoFrame(fileName: photo, height: 180)
                        }
                        if let caption = vault.veyraCaption(for: moment.id) {
                            VeyraStillFrame(key: caption.imageKey, height: 180)
                            Text(caption.captionBody)
                                .font(.body)
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if moment.photoFile == nil {
                            Text(moment.iconGlyph)
                                .font(.system(size: 56))
                                .frame(maxWidth: .infinity, minHeight: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.veyraMint.opacity(0.4), Color.veyraCard],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                            Text("No caption yet. You can still read the moment below.")
                                .font(.footnote)
                                .foregroundStyle(Color.veyraInk.opacity(0.75))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        NavigationLink {
                            VeyraPlaceLeaf(placeLine: moment.placeLine)
                        } label: {
                            VeyraHeaderBlock(
                                title: moment.placeLine,
                                detail: vault.veyraTripTitle(moment.tripID)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Shows every moment at this place")
                        Text(VeyraStampText.day(moment.stampedOn))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.veyraMint)
                        Text(moment.reflection)
                            .font(.body)
                            .foregroundStyle(Color.veyraInk)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        if let banner = vault.veyraBanner {
                            VeyraBannerLine(text: banner)
                        }
                        VeyraPrimaryButton(title: "Edit moment") {
                            composer = moment
                        }
                        NavigationLink {
                            VeyraCaptionEditor(starterMomentID: moment.id)
                        } label: {
                            Text(vault.veyraCaption(for: moment.id) == nil ? "Write a caption" : "Edit caption")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.veyraMint)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Capsule().stroke(Color.veyraMint, lineWidth: 1.5))
                        }
                        .buttonStyle(VeyraPressStyle())
                        VeyraQuietButton(title: "Remove from highlights") {
                            confirmUnpin = true
                        }
                    } else {
                        Text("This highlight is no longer available.")
                            .font(.body)
                            .foregroundStyle(Color.veyraInk)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        VeyraQuietButton(title: "Back") {
                            dismiss()
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationTitle("Highlight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(item: $composer) { slip in
            VeyraMomentComposer(starter: slip)
        }
        .confirmationDialog("Remove from highlights?", isPresented: $confirmUnpin, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                vault.veyraUnpin(momentID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The moment stays on its journey.")
        }
    }
}

enum VeyraHighlightLeafQelmDrift {
    static func veyraHighlightLeafQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [63, 69, 27, 15, 76, 31]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 63) &+ mark
        }
    }
}
