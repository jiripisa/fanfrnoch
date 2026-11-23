import AppKit
import SwiftUI

/// The panel's artwork (Resources/Art, copied into the bundle by build.sh) and its colours: the
/// palette of concept 1, "Modrotisk" (`.planning/design/concepts/concepts.md`).
@MainActor
public enum Artwork {

    /// The bundle that holds the artwork: the app, or the plug-in when the
    /// panel is shown in a host, where `Bundle.main` is the host's. Set it
    /// before the first panel is made.
    public static var bundle = Bundle.main

    /// Indigo modrotisk cloth behind the whole panel.
    public static let background = image("background")
    /// The fanfrnoch: a terracotta jug standing upright, its bladder and two tufts of horsehair.
    public static let drum = image("drum")
    /// The cream jug emblem beside the wordmark.
    public static let logo = image("logo")
    /// A knob's pearl-graphite cap, without a pointer: the cap stands still and the pointer is drawn.
    public static let knob = image("knob")
    /// The cream floral-and-dot band, tileable from left to right.
    public static let ornament = image("ornament")

    /// Midnight indigo: the glass cards' tint, the dark text on lit controls, the black keys.
    public static let indigo = rgb(0x101D38)
    /// Blue glass: the fill of what sits on a card (the pads, the Last note box).
    public static let glass = rgb(0x233653)
    /// Cream: the wordmark, the titles, the names of the controls and their values.
    public static let cream = rgb(0xF6ECD8)
    /// Terracotta, the jug's clay: value arcs and what is chosen, held or listening.
    public static let terracotta = rgb(0xD88C5B)
    /// Parchment, the drum's skin: captions and the second line of a pad.
    public static let parchment = rgb(0xDBC79F)
    /// Light sky blue: LFO 1.
    public static let sky = rgb(0x8EC9EF)
    /// Mint: LFO 2.
    public static let mint = rgb(0x93D6B4)

    /// The colour of an LFO (0 for the first): its button in the header and its
    /// arcs on the knobs it moves. Sky blue for LFO 1, mint for LFO 2: cool
    /// colours, apart from the terracotta of the knobs' own arcs.
    public static func lfo(_ index: Int) -> Color {
        index == 0 ? sky : mint
    }

    /// The colour of the velocity, the warm hand: the VEL button and its arcs on the knobs.
    public static let vel = parchment

    private static func rgb(_ hex: UInt32) -> Color {
        Color(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    private static func image(_ name: String) -> NSImage? {
        guard let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "Art") else { return nil }
        return NSImage(contentsOf: url)
    }
}

public extension View {
    /// The modrotisk cloth behind the panel, covering the view's whole frame;
    /// plain indigo where the artwork is missing.
    func instrumentBackground() -> some View {
        background {
            if let background = Artwork.background {
                Image(nsImage: background).resizable().scaledToFill()
            } else {
                Artwork.indigo
            }
        }
        .clipped()
        .preferredColorScheme(.dark)
    }

    /// A card of the panel: blue glass over the cloth, the mockup's rounded corners.
    func instrumentCard(cornerRadius: CGFloat = 14) -> some View {
        glassEffect(.regular.tint(Artwork.glass.opacity(0.45)), in: .rect(cornerRadius: cornerRadius))
    }
}
