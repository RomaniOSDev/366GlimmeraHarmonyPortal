import SwiftUI

struct VeyraCaptionEditor: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @Environment(\.dismiss) private var dismiss
    let starterMomentID: UUID

    @State private var momentID: UUID
    @State private var imageKey = VeyraStillRack.cliff
    @State private var captionBody = ""
    @State private var stampedOn = Date()
    @State private var trouble: String?
    @State private var existingID: UUID?

    init(starterMomentID: UUID) {
        self.starterMomentID = starterMomentID
        _momentID = State(initialValue: starterMomentID)
    }

    var body: some View {
        VeyraScreen(still: imageKey) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VeyraHeaderBlock(
                        title: "Caption",
                        detail: "The words stay with the moment you pick. Choose one scene picture."
                    )
                    Text("Moment")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.veyraInk)
                    ForEach(vault.moments.sorted { $0.stampedOn > $1.stampedOn }) { moment in
                        Button {
                            momentID = moment.id
                            if let leaf = vault.veyraCaption(for: moment.id) {
                                imageKey = leaf.imageKey
                                captionBody = leaf.captionBody
                                stampedOn = leaf.stampedOn
                                existingID = leaf.id
                            }
                        } label: {
                            HStack(alignment: .top) {
                                Text(moment.iconGlyph)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(moment.placeLine)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.veyraInk)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(vault.veyraTripTitle(moment.tripID))
                                        .font(.caption)
                                        .foregroundStyle(Color.veyraMint)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                if moment.id == momentID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.veyraMint)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.veyraCard)
                            )
                        }
                        .buttonStyle(VeyraPressStyle())
                    }
                    Text("Scene picture")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.veyraInk)
                    ForEach(VeyraStillRack.choices, id: \.self) { key in
                        Button {
                            imageKey = key
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                VeyraStillFrame(key: key, height: 92)
                                Text(VeyraStillRack.veyraLabel(for: key))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.veyraInk)
                                if imageKey == key {
                                    Text("Selected")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.veyraMint)
                                }
                            }
                        }
                        .buttonStyle(VeyraPressStyle())
                    }
                    Text("Caption")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.veyraInk)
                    VeyraFieldShell {
                        TextEditor(text: $captionBody)
                            .frame(minHeight: 120)
                            .foregroundStyle(Color.veyraInk)
                            .scrollContentBackground(.hidden)
                    }
                    DatePicker("Date", selection: $stampedOn, displayedComponents: .date)
                        .foregroundStyle(Color.veyraInk)
                    if let trouble {
                        Text(trouble)
                            .font(.footnote)
                            .foregroundStyle(Color.veyraInk)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VeyraPrimaryButton(title: "Save caption") {
                        veyraCommit()
                    }
                    VeyraQuietButton(title: "Cancel") {
                        dismiss()
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationTitle("Caption")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear {
            if let leaf = vault.veyraCaption(for: starterMomentID) {
                imageKey = leaf.imageKey
                captionBody = leaf.captionBody
                stampedOn = leaf.stampedOn
                existingID = leaf.id
                momentID = leaf.momentID
            }
        }
    }

    private func veyraCommit() {
        let note = captionBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard vault.moments.contains(where: { $0.id == momentID }) else {
            trouble = "Choose a moment before saving."
            return
        }
        if note.isEmpty {
            trouble = "Write a caption before saving."
            return
        }
        vault.veyraSaveCaption(VeyraCaptionLeaf(
            id: existingID ?? UUID(),
            momentID: momentID,
            imageKey: imageKey,
            captionBody: note,
            stampedOn: stampedOn
        ))
        dismiss()
    }
}

enum VeyraCaptionEditorQelmDrift {
    static func veyraCaptionEditorQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [64, 34, 45, 50, 69, 67]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 64) &+ mark
        }
    }
}
