import SwiftUI
import UIKit

extension Color {
    static let veyraBackdrop = Color("AppBackground")
    static let veyraCard = Color("AppSurface")
    static let veyraMint = Color("AppPrimary")
    static let veyraGlow = Color("AppAccent")
    static let veyraInk = Color("AppInk")
    static let veyraOnPrimary = Color("AppOnPrimary")
}

enum VeyraStampText {
    static func day(_ date: Date) -> String {
        formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

struct VeyraPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
    }
}

struct VeyraScreen<Content: View>: View {
    let still: String
    private let content: Content

    init(still: String, @ViewBuilder content: () -> Content) {
        self.still = still
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                VeyraUndoLine()
            }
            .background {
                Color.veyraBackdrop
                    .overlay {
                        Image("veyraNightGround")
                            .resizable()
                            .scaledToFill()
                    }
                    .overlay {
                        Image(still)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.22)
                    }
                    .overlay {
                        LinearGradient(
                            colors: [Color.veyraBackdrop.opacity(0.2), Color.veyraBackdrop.opacity(0.88)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

struct VeyraStillFrame: View {
    let key: String
    var height: CGFloat = 148

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                Image(key)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.16), radius: 8, y: 4)
    }
}

struct VeyraCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.veyraCard.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.28), radius: 10, y: 6)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.veyraMint)
                    .frame(height: 3)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
            }
    }
}

enum VeyraChromeArt {
    static let primaryPlate = "veyraBtnPrimary"
    static let quietPlate = "veyraBtnQuiet"
    static let dockPlate = "veyraBtnDock"
    static let check = "veyraIconCheck"
    static let up = "veyraIconUp"
    static let down = "veyraIconDown"
    static let edit = "veyraIconEdit"
    static let delete = "veyraIconDelete"
    static let emptyRoute = "veyraIconEmptyRoute"
    static let emptyPlus = "veyraIconEmptyPlus"
    static let emptyCarry = "veyraIconEmptyCarry"
}

struct VeyraPlateSkin: View {
    let name: String

    private var cap: CGFloat {
        name == VeyraChromeArt.dockPlate ? 26 : 18
    }

    var body: some View {
        Image(name)
            .resizable(
                capInsets: EdgeInsets(top: cap, leading: cap, bottom: cap, trailing: cap),
                resizingMode: .stretch
            )
            .accessibilityHidden(true)
    }
}

struct VeyraPlateLabel: View {
    let title: String
    let plate: String
    var titleColor: Color
    var minHeight: CGFloat = 52

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(titleColor)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background {
                VeyraPlateSkin(name: plate)
                    .shadow(color: Color.black.opacity(0.28), radius: 8, y: 4)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct VeyraPrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VeyraPlateLabel(title: title, plate: VeyraChromeArt.primaryPlate, titleColor: Color.veyraOnPrimary)
        }
        .buttonStyle(VeyraPressStyle())
    }
}

struct VeyraQuietButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VeyraPlateLabel(
                title: title,
                plate: VeyraChromeArt.quietPlate,
                titleColor: Color.veyraGlow,
                minHeight: 48
            )
        }
        .buttonStyle(VeyraPressStyle())
    }
}

struct VeyraGlyphMark: View {
    let name: String
    var size: CGFloat = 28
    var tint: Color = .veyraGlow

    var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }
}

struct VeyraIconChip: View {
    let title: String
    let art: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                VeyraGlyphMark(name: art, size: 18)
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.veyraGlow)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(minWidth: 44, minHeight: 40)
            .background {
                VeyraPlateSkin(name: VeyraChromeArt.quietPlate)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(VeyraPressStyle())
        .disabled(enabled == false)
    }
}

struct VeyraEmptyMark: View {
    let art: String

    var body: some View {
        Image(art)
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 72)
            .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
            .accessibilityHidden(true)
    }
}

struct VeyraQuietLinkLabel: View {
    let title: String

    var body: some View {
        VeyraPlateLabel(
            title: title,
            plate: VeyraChromeArt.quietPlate,
            titleColor: Color.veyraGlow,
            minHeight: 48
        )
    }
}

struct VeyraHeaderBlock: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.title, design: .serif).weight(.bold))
                .foregroundStyle(Color.veyraInk)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Color.veyraInk.opacity(0.78))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VeyraBannerLine: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.veyraOnPrimary)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                VeyraPlateSkin(name: VeyraChromeArt.primaryPlate)
            }
    }
}

struct VeyraFieldShell<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.veyraCard)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
            )
    }
}

extension View {
    @ViewBuilder
    func veyraHoldSheetOpen() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationContentInteraction(.scrolls)
        } else {
            self
        }
    }
}

struct VeyraCoverThumb: View {
    let key: String
    var width: CGFloat = 84
    var height: CGFloat = 72

    var body: some View {
        Image(key)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct VeyraPhotoFrame: View {
    let fileName: String
    var height: CGFloat = 160

    var body: some View {
        if let image = VeyraPhotoStore.image(named: fileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

struct VeyraPlaceLink: View {
    let glyph: String
    let placeLine: String
    var font: Font = .headline

    var body: some View {
        NavigationLink {
            VeyraPlaceLeaf(placeLine: placeLine)
        } label: {
            Text("\(glyph)  \(placeLine)")
                .font(font)
                .foregroundStyle(Color.veyraInk)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows every stop at this corner")
    }
}

struct VeyraUndoLine: View {
    @EnvironmentObject private var vault: VeyraLedgerVault

    var body: some View {
        if let note = vault.undoNote {
            HStack(alignment: .center, spacing: 12) {
                Text(note)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.veyraOnPrimary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Button {
                    vault.veyraUndoMomentDelete()
                } label: {
                    Text("Undo")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.veyraGlow)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 40)
                        .background {
                            VeyraPlateSkin(name: VeyraChromeArt.quietPlate)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(VeyraPressStyle())
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background {
                VeyraPlateSkin(name: VeyraChromeArt.primaryPlate)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

struct VeyraKeypadVeil: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let veil = UIView(frame: .zero)
        veil.isUserInteractionEnabled = false
        veil.backgroundColor = .clear
        return veil
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard context.coordinator.attached == false, let window = uiView.window else { return }
            let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.veyraFoldKeys(_:)))
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delaysTouchesEnded = false
            tap.delegate = context.coordinator
            tap.name = "veyraFoldKeys"
            window.addGestureRecognizer(tap)
            context.coordinator.attached = true
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var attached = false
        var keyboardVisible = false

        override init() {
            super.init()
            let center = NotificationCenter.default
            center.addObserver(self, selector: #selector(veyraKeyboardShown), name: UIResponder.keyboardWillShowNotification, object: nil)
            center.addObserver(self, selector: #selector(veyraKeyboardHidden), name: UIResponder.keyboardWillHideNotification, object: nil)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc func veyraKeyboardShown() {
            keyboardVisible = true
        }

        @objc func veyraKeyboardHidden() {
            keyboardVisible = false
        }

        @objc func veyraFoldKeys(_ gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            let host = gesture.view
            DispatchQueue.main.async {
                let hit = host?.hitTest(point, with: nil)
                guard Self.veyraIsTyping(hit) == false else { return }
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            keyboardVisible
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            keyboardVisible && Self.veyraIsTyping(touch.view) == false
        }

        private static func veyraIsTyping(_ view: UIView?) -> Bool {
            var node = view
            while let current = node {
                if current is UITextField || current is UITextView || current is UITextInput {
                    return true
                }
                let name = NSStringFromClass(type(of: current))
                if name.contains("TextField") || name.contains("TextView") || name.contains("FieldEditor") {
                    return true
                }
                node = current.superview
            }
            return false
        }
    }
}

enum VeyraSurfaceKitQelmDrift {
    static func veyraSurfaceKitQelmDriftFold(_ basis: Int) -> Int {
        let ribbon = [20, 12, 75, 16, 62, 26]
        return ribbon.reduce(basis) { partial, mark in
            (partial &* 20) &+ mark
        }
    }
}
