import SwiftUI

struct VeyraTripReading: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    let tripID: UUID

    private var trip: VeyraTripFolio? {
        vault.trips.first { $0.id == tripID }
    }

    var body: some View {
        VeyraScreen(still: trip?.veyraCover ?? VeyraStillRack.lantern) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let trip {
                        VeyraStillFrame(key: trip.veyraCover, height: 140)
                        VeyraHeaderBlock(title: trip.title, detail: trip.placeNote)
                        let slips = vault.veyraMoments(for: trip.id)
                        if slips.isEmpty {
                            Text("This reading is waiting for the first moment.")
                                .font(.body)
                                .foregroundStyle(Color.veyraInk)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            ForEach(slips) { slip in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(VeyraStampText.day(slip.stampedOn))
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.veyraMint)
                                    Text("\(slip.iconGlyph)  \(slip.placeLine)")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(Color.veyraInk)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if let photo = slip.photoFile {
                                        VeyraPhotoFrame(fileName: photo, height: 180)
                                    }
                                    Text(slip.reflection)
                                        .font(.body)
                                        .foregroundStyle(Color.veyraInk.opacity(0.9))
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if let caption = vault.veyraCaption(for: slip.id) {
                                        Text(caption.captionBody)
                                            .font(.body.italic())
                                            .foregroundStyle(Color.veyraInk.opacity(0.75))
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("This journey is no longer on the shelf.")
                            .font(.body)
                            .foregroundStyle(Color.veyraInk)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

enum VeyraTripReadingQelmDrift {
    static func veyraTripReadingQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [25, 39, 19, 43, 29, 74]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 25) &+ mark
        }
    }
}
