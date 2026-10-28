import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct VeyraMomentComposer: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @Environment(\.dismiss) private var dismiss
    let starter: VeyraMomentSlip

    @State private var tripID: UUID
    @State private var iconGlyph: String
    @State private var reflection: String
    @State private var placeLine: String
    @State private var stampedOn: Date
    @State private var pinnedHighlight: Bool
    @State private var photoFile: String?
    @State private var photoData: Data?
    @State private var photoCleared = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var trouble: String?

    init(starter: VeyraMomentSlip) {
        self.starter = starter
        _tripID = State(initialValue: starter.tripID)
        _iconGlyph = State(initialValue: starter.iconGlyph)
        _reflection = State(initialValue: starter.reflection)
        _placeLine = State(initialValue: starter.placeLine)
        _stampedOn = State(initialValue: starter.stampedOn)
        _pinnedHighlight = State(initialValue: starter.pinnedHighlight)
        _photoFile = State(initialValue: starter.photoFile)
    }

    var body: some View {
        NavigationStack {
            VeyraScreen(still: VeyraStillRack.lake) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VeyraHeaderBlock(
                            title: "Moment",
                            detail: "Pick an icon, name the place, add a photo if you want, and write what you want to remember."
                        )
                        Text("Journey")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraInk)
                        ForEach(vault.trips) { trip in
                            Button {
                                tripID = trip.id
                            } label: {
                                HStack {
                                    Text(trip.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.veyraInk)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 8)
                                    if trip.id == tripID {
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
                        Text("Icon")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraInk)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(VeyraGlyphRack.marks, id: \.self) { mark in
                                Button {
                                    iconGlyph = mark
                                } label: {
                                    Text(mark)
                                        .font(.title2)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(iconGlyph == mark ? Color.veyraMint.opacity(0.35) : Color.veyraCard)
                                        )
                                }
                                .buttonStyle(VeyraPressStyle())
                                .accessibilityLabel("Icon \(mark)")
                            }
                        }
                        Text("Place")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraInk)
                        VeyraFieldShell {
                            TextField("Place name", text: $placeLine)
                                .foregroundStyle(Color.veyraInk)
                        }
                        Text("Reflection")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraInk)
                        VeyraFieldShell {
                            TextEditor(text: $reflection)
                                .frame(minHeight: 120)
                                .foregroundStyle(Color.veyraInk)
                                .scrollContentBackground(.hidden)
                        }
                        Text("Photo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.veyraInk)
                        if let photoData, let image = UIImage(data: photoData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        } else if photoCleared == false, let photoFile {
                            VeyraPhotoFrame(fileName: photoFile, height: 160)
                        }
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Text("Choose a photo")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.veyraMint)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 10)
                                .background(
                                    Capsule(style: .continuous)
                                        .stroke(Color.veyraMint, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(VeyraPressStyle())
                        if photoData != nil || (photoCleared == false && photoFile != nil) {
                            VeyraQuietButton(title: "Remove photo") {
                                photoData = nil
                                photoCleared = true
                                pickerItem = nil
                            }
                        }
                        DatePicker("Date", selection: $stampedOn, displayedComponents: .date)
                            .foregroundStyle(Color.veyraInk)
                        Toggle(isOn: $pinnedHighlight) {
                            Text("Show in highlights")
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .tint(Color.veyraMint)
                        if let trouble {
                            Text(trouble)
                                .font(.footnote)
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        VeyraPrimaryButton(title: "Save moment") {
                            veyraCommit()
                        }
                        VeyraQuietButton(title: "Cancel") {
                            dismiss()
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: pickerItem) { item in
                    guard let item else { return }
                    Task {
                        if let picked = try? await item.loadTransferable(type: VeyraPickedPhoto.self) {
                            await MainActor.run {
                                photoData = picked.data
                                photoCleared = false
                            }
                        }
                    }
                }
            }
            .navigationTitle("Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
        }
        .veyraHoldSheetOpen()
    }

    private func veyraCommit() {
        let place = placeLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard vault.trips.contains(where: { $0.id == tripID }) else {
            trouble = "Choose a journey before saving."
            return
        }
        if place.isEmpty {
            trouble = "Add the place before saving."
            return
        }
        if note.isEmpty {
            trouble = "Write a reflection before saving."
            return
        }
        var file = photoCleared ? nil : photoFile
        if let photoData {
            guard let name = VeyraPhotoStore.write(photoData, id: starter.id) else {
                trouble = "The photo could not be saved."
                return
            }
            file = name
        } else if photoCleared {
            VeyraPhotoStore.remove(photoFile)
            file = nil
        }
        vault.veyraSaveMoment(VeyraMomentSlip(
            id: starter.id,
            tripID: tripID,
            iconGlyph: iconGlyph,
            reflection: note,
            placeLine: place,
            stampedOn: stampedOn,
            pinnedHighlight: pinnedHighlight,
            ordinal: starter.ordinal,
            photoFile: file
        ))
        dismiss()
    }
}

private struct VeyraPickedPhoto: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            VeyraPickedPhoto(data: data)
        }
    }
}

enum VeyraMomentComposerQelmDrift {
    static func veyraMomentComposerQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [83, 36, 20, 49, 52, 60]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 83) &+ mark
        }
    }
}
