import AppKit
import SwiftUI
import FanfrnochCore

/// The bottom of the panel, the same in the app's window and in the
/// plug-in's: one glass card that follows the mode, as in the mockups.
///
/// - Keyboard: "Keyboard", an ornament band with the drum standing on the
///   keys, the last note played, the "Send to pad" button (`SendToPadView`)
///   and three octaves of keys (`KeyboardStripView`).
/// - Pads: the sixteen pads on the left (`PadGridView`) and the selected
///   pad's pitch and group and the Kit menu on the right (`PadInspectorView`).
///
/// Both modes are the same height, so the window keeps its size when the
/// mode changes.
public struct ModeFooterView: View {

    private let model: any InstrumentModel

    /// The footer's height in either mode.
    public static var height: CGFloat { PadGridView.height + 2 * padding }

    private static let padding: CGFloat = 10
    private static let keyboardRow: CGFloat = 60
    /// How tall the drum stands: taller than its row, it reaches up over the card's edge.
    private static let drumHeight: CGFloat = 100

    @State private var sending = false

    public init(model: any InstrumentModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch model.mode {
            case .keyboard: keyboard
            case .pads: pads
            }
        }
        .padding(Self.padding)
        .frame(height: Self.height)
        .instrumentCard(cornerRadius: 16)
    }

    private var keyboard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 14) {
                Text("Keyboard")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(Artwork.cream)
                    .fixedSize()
                    .padding(.leading, 8)
                OrnamentBand()
                    .frame(maxWidth: .infinity)
                // A box as wide as the drum, which stands on the keys and reaches up out of it.
                Color.clear
                    .frame(width: DrumView.width(height: Self.drumHeight), height: Self.keyboardRow)
                    .overlay(alignment: .bottom) {
                        DrumView()
                            .frame(height: Self.drumHeight)
                            .offset(y: 6)
                    }
                OrnamentBand()
                    .frame(maxWidth: .infinity)
                Rectangle().fill(Artwork.cream.opacity(0.3)).frame(width: 1, height: 40)
                lastNote
                sendButton
            }
            .frame(height: Self.keyboardRow)
            .zIndex(1)
            KeyboardStripView(model: model)
                .frame(maxHeight: .infinity)
        }
    }

    /// The pitch "Send to pad" gives a pad, in a box as the mockup draws it.
    private var lastNote: some View {
        VStack(spacing: 3) {
            Text("Last note")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Artwork.cream)
            Text(Notes.name(PadLabel.sendPitch(lastNote: model.lastNote)))
                .font(.system(size: 22, weight: .semibold, design: .serif).monospacedDigit())
                .foregroundStyle(Artwork.cream)
                .frame(width: 76, height: 34)
                .background(Artwork.indigo.opacity(0.6), in: .rect(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Artwork.cream.opacity(0.25), lineWidth: 1))
        }
        .accessibilityElement(children: .combine)
        .help("The pitch Send to pad gives a pad: the last note played, C2 before any")
    }

    private var sendButton: some View {
        Button {
            sending = true
        } label: {
            Text("Send to pad")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Artwork.cream)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(.glass)
        .help("Copy the keyboard's sound, at the last note played, to a pad")
        .popover(isPresented: $sending) {
            SendToPadView(model: model, isPresented: $sending)
        }
        .padding(.trailing, 6)
    }

    private var pads: some View {
        HStack(alignment: .top, spacing: 12) {
            PadGridView(model: model)
                .frame(maxWidth: .infinity)
            Rectangle().fill(Artwork.cream.opacity(0.25)).frame(width: 1)
            PadInspectorView(model: model)
                .frame(width: PadInspectorView.width)
        }
    }
}

/// The fanfrnoch standing upright, cropped to the jug and its tufts: the
/// artwork is a square with transparent margins around them.
struct DrumView: View {

    /// The jug's bounds in the square artwork (`Resources/Art/drum.png`, 1200 px, measured
    /// on its alpha): x 293…920, y 147…1054.
    static let bounds = CGRect(x: 0.244, y: 0.122, width: 0.523, height: 0.757)

    /// The width the drum takes at a height.
    static func width(height: CGFloat) -> CGFloat {
        height * bounds.width / bounds.height
    }

    var body: some View {
        if let drum = Artwork.drum {
            CroppedArt(image: drum, bounds: Self.bounds)
        }
    }
}

/// The cream jug beside the wordmark, cropped to its bounds as the drum is.
struct LogoView: View {

    /// The emblem's bounds in its square (`Resources/Art/logo.png`, 512 px): x 119…391, y 68…455.
    static let bounds = CGRect(x: 0.232, y: 0.133, width: 0.534, height: 0.758)

    /// The width the emblem takes at a height.
    static func width(height: CGFloat) -> CGFloat {
        height * bounds.width / bounds.height
    }

    var body: some View {
        if let logo = Artwork.logo {
            CroppedArt(image: logo, bounds: Self.bounds)
        }
    }
}

/// A part of an artwork, `bounds` in parts of its size from the top left, at
/// the proportions of that part. Only a picture: it never takes a click, so
/// whatever it reaches over (the drum over a card's edge) keeps working.
struct CroppedArt: View {

    let image: NSImage
    let bounds: CGRect

    var body: some View {
        let size = image.size
        let aspect = size.height > 0 && bounds.height > 0 ? size.width * bounds.width / (size.height * bounds.height) : 1
        Color.clear
            .aspectRatio(aspect, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                GeometryReader { geometry in
                    let width = geometry.size.width / bounds.width
                    let height = geometry.size.height / bounds.height
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: width, height: height)
                        .offset(x: -bounds.minX * width, y: -bounds.minY * height)
                }
            }
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
