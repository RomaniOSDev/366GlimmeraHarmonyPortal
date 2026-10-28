import StoreKit
import SwiftUI

struct VeyraPreferenceCanvas: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @State private var confirmReset = false

    var body: some View {
        VeyraScreen(still: VeyraStillRack.desk) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VeyraStillFrame(key: VeyraStillRack.desk, height: 120)
                    VeyraHeaderBlock(
                        title: "Setup",
                        detail: "Notes stay on this device. Rate the experience, or read the privacy and terms pages."
                    )
                    if let last = vault.lastActivityDate {
                        Text("Last saved change \(VeyraStampText.day(last)).")
                            .font(.footnote)
                            .foregroundStyle(Color.veyraInk.opacity(0.8))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("Journeys \(vault.trips.count) · Moments \(vault.moments.count) · Captions \(vault.captions.count) · Places \(vault.veyraDistinctPlaceCount())")
                        .font(.footnote)
                        .foregroundStyle(Color.veyraInk.opacity(0.8))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    VeyraPrimaryButton(title: "Rate Us") {
                        rateApp()
                    }
                    VeyraQuietButton(title: "Privacy") {
                        if let url = URL(string: VeyraLinkLedger.privacy) {
                            UIApplication.shared.open(url)
                        }
                    }
                    VeyraQuietButton(title: "Terms") {
                        if let url = URL(string: VeyraLinkLedger.terms) {
                            UIApplication.shared.open(url)
                        }
                    }
                    VeyraQuietButton(title: "Reset all data") {
                        confirmReset = true
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .confirmationDialog("Reset all data?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                vault.veyraResetAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Journeys, moments, captions, and highlights stored on this device will be cleared.")
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

enum VeyraPreferenceCanvasQelmDrift {
    static func veyraPreferenceCanvasQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [23, 59, 40, 75, 44, 42]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 23) &+ mark
        }
    }
}
