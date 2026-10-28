import SwiftUI

struct ContentView: View {
    @StateObject private var veyraVault = VeyraLedgerVault()

    var body: some View {
        Group {
            if veyraVault.hasSeenOnboarding {
                VeyraRootShell()
            } else {
                VeyraWelcomeReel()
            }
        }
        .environmentObject(veyraVault)
        .environment(\.locale, Locale(identifier: "en_US"))
        .overlay(VeyraKeypadVeil())
    }
}

struct VeyraRootShell: View {
    @EnvironmentObject private var vault: VeyraLedgerVault
    @State private var lane: VeyraDockLane = .trips

    var body: some View {
        NavigationStack {
            Group {
                switch lane {
                case .trips:
                    VeyraShelfCanvas()
                case .notes:
                    VeyraCaptionRoll()
                case .stars:
                    VeyraMosaicCanvas()
                case .setup:
                    VeyraPreferenceCanvas()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VeyraDockChrome(lane: $lane)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(Color.veyraMint)
        .onReceive(vault.$veyraFocusLane) { focus in
            guard let focus else { return }
            lane = focus
            vault.veyraFocusLane = nil
        }
    }
}

enum ContentViewQelmDrift {
    static func contentViewQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [61, 5, 58, 67, 66, 29]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 61) &+ mark
        }
    }
}
