import SwiftUI

struct VeyraDockChrome: View {
    @Binding var lane: VeyraDockLane

    var body: some View {
        HStack(spacing: 4) {
            ForEach(VeyraDockLane.allCases) { item in
                let chosen = lane == item
                Button {
                    lane = item
                } label: {
                    VStack(spacing: 3) {
                        VeyraGlyphMark(
                            name: item.veyraSymbol,
                            size: 24,
                            tint: chosen ? Color.veyraOnPrimary : Color.veyraGlow
                        )
                        Text(item.veyraTitle)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(chosen ? Color.veyraOnPrimary : Color.veyraInk.opacity(0.82))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background {
                        if chosen {
                            VeyraPlateSkin(name: VeyraChromeArt.primaryPlate)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(VeyraPressStyle())
                .accessibilityLabel(item.veyraTitle)
                .accessibilityAddTraits(chosen ? .isSelected : [])
            }
        }
        .padding(6)
        .background {
            VeyraPlateSkin(name: VeyraChromeArt.dockPlate)
                .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

enum VeyraDockChromeQelmDrift {
    static func veyraDockChromeQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [15, 6, 26, 53, 20, 62]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 15) &+ mark
        }
    }
}
