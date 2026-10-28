import SwiftUI

struct VeyraTripMaker: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @Environment(\.dismiss) private var dismiss
    let existing: VeyraTripFolio?

    @State private var title: String
    @State private var placeNote: String
    @State private var openedOn: Date
    @State private var coverKey: String
    @State private var trouble: String?

    init(existing: VeyraTripFolio?) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _placeNote = State(initialValue: existing?.placeNote ?? "")
        _openedOn = State(initialValue: existing?.openedOn ?? Date())
        _coverKey = State(initialValue: existing?.veyraCover ?? VeyraStillRack.cliff)
    }

    var body: some View {
        NavigationStack {
            VeyraScreen(still: coverKey) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VeyraHeaderBlock(
                            title: existing == nil ? "New journey" : "Edit journey",
                            detail: "A title, a place note, and a cover scene are saved with the journey."
                        )
                        Text("Title")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraInk)
                        VeyraFieldShell {
                            TextField("Name the journey", text: $title)
                                .foregroundStyle(Color.veyraInk)
                        }
                        Text("Place note")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraInk)
                        VeyraFieldShell {
                            TextField("Where does it belong?", text: $placeNote)
                                .foregroundStyle(Color.veyraInk)
                        }
                        Text("Cover")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraInk)
                        ForEach(VeyraStillRack.choices, id: \.self) { key in
                            Button {
                                coverKey = key
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    VeyraStillFrame(key: key, height: 84)
                                    Text(VeyraStillRack.veyraLabel(for: key))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.veyraInk)
                                    if coverKey == key {
                                        Text("Selected")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color.veyraMint)
                                    }
                                }
                            }
                            .buttonStyle(VeyraPressStyle())
                        }
                        DatePicker("Opened on", selection: $openedOn, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .foregroundStyle(Color.veyraInk)
                        if let trouble {
                            Text(trouble)
                                .font(.footnote)
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        VeyraPrimaryButton(title: "Save journey") {
                            veyraCommit()
                        }
                        VeyraQuietButton(title: "Cancel") {
                            dismiss()
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
        }
        .veyraHoldSheetOpen()
    }

    private func veyraCommit() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPlace = placeNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty {
            trouble = "Add a journey title before saving."
            return
        }
        if cleanPlace.isEmpty {
            trouble = "Add a place note before saving."
            return
        }
        let trip = VeyraTripFolio(
            id: existing?.id ?? UUID(),
            title: cleanTitle,
            placeNote: cleanPlace,
            openedOn: openedOn,
            coverKey: coverKey
        )
        vault.veyraSaveTrip(trip)
        dismiss()
    }
}

enum VeyraTripMakerQelmDrift {
    static func veyraTripMakerQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [28, 32, 29, 81, 5, 42]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 28) &+ mark
        }
    }
}
