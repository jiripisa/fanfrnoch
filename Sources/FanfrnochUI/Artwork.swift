import AppKit
import SwiftUI

/// The panel's artwork (Resources/Art, copied into the bundle by build.sh) and its colours: the
/// palette of concept 2, "Polar Khomus".
@MainActor
public enum Artwork {

    /// The bundle that holds the artwork: the app, or the plug-in when the
    /// panel is shown in a host, where `Bundle.main` is the host's. Set it
    /// before the first panel is made.
    public static var bundle = Bundle.main

    /// Leather, bone and fur behind the whole panel.
    public static let background = image("background")
    /// The silver khomus over its bone strap, for the footer.
    public static let khomus = image("khomus")
    /// The emblem beside the wordmark.
    public static let logo = image("logo")
    /// A knob's brushed-metal cap, without a pointer: the cap stands still and the pointer is drawn.
    public static let knob = image("knob")
    /// The engraved diamond band, tileable from left to right.
    public static let ornament = image("ornament")

    /// Blue-black: the glass panels' tint and the dark text on lit controls.
    public static let midnight = rgb(0x111C29)
    public static let slate = rgb(0x24374A)
    /// Icy silver: the wordmark, section titles and values.
    public static let silver = rgb(0xCBDCE4)
    /// Bone: the names of the knobs.
    public static let bone = rgb(0xE9DEC4)
    /// Aurora cyan: value arcs and what is selected.
    public static let aurora = rgb(0x67D6D3)

    /// The colour of an LFO (0 for the first): its button in the header and its
    /// arcs on the knobs it moves. Aurora cyan for LFO 1, bone for LFO 2.
    public static func lfo(_ index: Int) -> Color {
        index == 0 ? aurora : bone
    }

    /// The colour of the velocity: the VEL button and its arcs on the knobs.
    public static let vel = silver

    private static func rgb(_ hex: UInt32) -> Color {
        Color(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    private static func image(_ name: String) -> NSImage? {
        guard let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "Art") else { return nil }
        return NSImage(contentsOf: url)
    }
}

public extension View {
    /// The leather and fur behind the panel, covering the view's whole frame;
    /// plain midnight where the artwork is missing.
    func instrumentBackground() -> some View {
        background {
            if let background = Artwork.background {
                Image(nsImage: background).resizable().scaledToFill()
            } else {
                Artwork.midnight
            }
        }
        .clipped()
        .preferredColorScheme(.dark)
    }
}
