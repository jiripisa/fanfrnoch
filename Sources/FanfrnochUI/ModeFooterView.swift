import SwiftUI
import FanfrnochCore

/// The bottom of the panel, the same in the app's window and in the
/// plug-in's; it follows the mode.
///
/// - Keyboard: the khomus over an ornament band, "Keyboard", the last note
///   played, the "Send to pad" button (`SendToPadView`) and the keys
///   (`KeyboardStripView`).
/// - Pads: the sixteen pads on the left (`PadGridView`) and the selected
///   pad's pitch and group on the right (`PadInspectorView`).
///
/// Both modes are the same height, so the window keeps its size when the
/// mode changes.
public struct ModeFooterView: View {

    private let model: any InstrumentModel

    /// The footer's height in either mode.
    public static var height: CGFloat { PadGridView.height }

    private static let inspectorWidth: CGFloat = 390
    private static let keyboardRow: CGFloat = 80

    @State private var sending = false

    public init(model: any InstrumentModel) {
        self.model = model
    }

    public var body: some View {
        // Spacing 0: the tiles and panels are meant to stay apart, not blend.
        GlassEffectContainer(spacing: 0) {
            switch model.mode {
            case .keyboard: keyboard
            case .pads: pads
            }
        }
        .frame(height: Self.height)
    }

    private var keyboard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                Text("Keyboard")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(Artwork.silver)
                    .padding(.leading, 6)
                ZStack {
                    OrnamentBand()
                    KhomusView()
                }
                .frame(maxWidth: .infinity)
                lastNote
                sendButton
            }
            .frame(height: Self.keyboardRow)
            KeyboardStripView(model: model)
                .frame(maxHeight: .infinity)
        }
        .padding(8)
        .glassEffect(.regular.tint(Artwork.midnight.opacity(0.35)), in: .rect(cornerRadius: 16))
    }

    /// The pitch "Send to pad" gives a pad.
    private var lastNote: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Last note")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Artwork.bone)
            Text(Notes.name(PadLabel.sendPitch(lastNote: model.lastNote)))
                .font(.system(size: 17, weight: .semibold).monospacedDigit())
                .foregroundStyle(Artwork.silver)
        }
        .accessibilityElement(children: .combine)
        .help("The pitch Send to pad gives a pad: the last note played, C2 before any")
    }

    private var sendButton: some View {
        Button {
            sending = true
        } label: {
            Text("Send to pad")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Artwork.silver)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
        }
        .buttonStyle(.glass)
        .help("Copy the keyboard's sound, at the last note played, to a pad")
        .popover(isPresented: $sending) {
            SendToPadView(model: model, isPresented: $sending)
        }
        .padding(.trailing, 6)
    }

    private var pads: some View {
        HStack(alignment: .top, spacing: 10) {
            PadGridView(model: model)
                .frame(maxWidth: .infinity)
            PadInspectorView(model: model)
                .frame(width: Self.inspectorWidth, height: Self.height)
        }
    }
}

/// The silver khomus, its transparent margins cropped: the artwork is a
/// square with the harp lying across its middle.
struct KhomusView: View {

    /// The harp's width for its height, as it lies in the artwork.
    private static let aspect: CGFloat = 2.6

    var body: some View {
        if let khomus = Artwork.khomus {
            // A box of the harp's proportions; the square, as wide as the box, overflows it
            // above and below, where the artwork is empty.
            Color.clear
                .aspectRatio(Self.aspect, contentMode: .fit)
                .overlay {
                    Image(nsImage: khomus).resizable().interpolation(.high).scaledToFill()
                }
                .clipped()
                // Only a picture: its square, cropped for the eye but not for the mouse, would
                // take the clicks meant for the controls above it (Curve's row).
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
