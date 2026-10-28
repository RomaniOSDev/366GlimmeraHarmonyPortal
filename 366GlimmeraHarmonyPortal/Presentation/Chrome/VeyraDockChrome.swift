import SwiftUI

struct VeyraDockChrome: View {
    @Binding var lane: VeyraDockLane

    var body: some View {
        HStack(spacing: 6) {
            ForEach(VeyraDockLane.allCases) { item in
                Button {
                    lane = item
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.veyraSymbol)
                            .font(.body.weight(.semibold))
                        Text(item.veyraTitle)
                            .font(.caption.weight(.semibold))
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(lane == item ? Color.veyraOnPrimary : Color.veyraInk)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .padding(.vertical, 6)
                    .contentShape(Capsule())
                    .background {
                        if lane == item {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.veyraMint, Color.veyraGlow],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                }
                .buttonStyle(VeyraPressStyle())
                .contentShape(Capsule())
                .accessibilityLabel(item.veyraTitle)
                .accessibilityAddTraits(lane == item ? .isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background {
            Capsule(style: .continuous)
                .fill(Color.veyraCard)
                .shadow(color: Color.black.opacity(0.16), radius: 10, y: 4)
        }
        .padding(.horizontal, 16)
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
