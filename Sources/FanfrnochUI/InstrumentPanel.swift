import AppKit
import SwiftUI
import FanfrnochCore

/// The instrument's panel, the same in the app's window and in the plug-in's:
/// the header (`HeaderView`), an ornament band, the five groups of controls
/// (Reed, Stroke, Mouth, Breath, Master) side by side on glass, then `footer`
/// (the pads or the keyboard). The knobs show the set the model shows: the
/// keyboard's, or the selected pad's. With LFO 1, LFO 2 or VEL on in the
/// header, they set that source's amounts; with MIDI on, they show their MIDI
/// controllers and learn new ones (`KnobView`). A file's error shows under the
/// header's menus for a few seconds (`ErrorNotice`), never as an alert.
///
/// `trailing` joins the header on the right, after LFO 1, LFO 2 and VEL (the
/// app's Settings button). It comes after `footer`, so that a single trailing
/// closure is the footer: `InstrumentPanel(model:) { footer } trailing: { … }`.
///
/// The panel asks the model to catch up every 40 ms: a host moves parameters
/// without telling anyone, and pads are hit from MIDI. The same beat takes the
/// error line away when its time is up.
/// The caller gives the panel its frame and `instrumentBackground()`.
public struct InstrumentPanel<Footer: View, Trailing: View>: View {

    /// The panel's width; its groups are laid out for it. Its height follows
    /// from what is in it.
    public static var width: CGFloat { 1100 }

    private let model: any InstrumentModel
    private let trailing: Trailing
    private let footer: Footer

    /// What the knobs edit at the moment: their values, a source's amounts, or
    /// their controllers.
    @State private var editing: KnobEditing

    /// The error line's message while it shows.
    @State private var notice: String?

    /// `editing` is what the panel opens with, and `notice` an error line it
    /// opens with, for a picture of that state; a window opens with the knobs
    /// as knobs and no error.
    public init(model: any InstrumentModel,
                showing editing: KnobEditing = .value,
                notice: String? = nil,
                @ViewBuilder footer: () -> Footer = { EmptyView() },
                @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.model = model
        _editing = State(initialValue: editing)
        _notice = State(initialValue: notice)
        self.trailing = trailing()
        self.footer = footer()
    }

    public var body: some View {
        VStack(spacing: 10) {
            HeaderView(model: model, editing: $editing, notice: notice, trailing: trailing)
                .zIndex(1)              // the error line hangs over what is below
            OrnamentBand()
            // Spacing 0: glass closer than the container's spacing blends into one shape, and
            // the five groups are meant to stay apart.
            GlassEffectContainer(spacing: 0) {
                HStack(alignment: .top, spacing: 6) {
                    ForEach(ParameterSection.all) { section in
                        SectionView(section: section, set: model.shownSet, model: model, editing: editing)
                    }
                }
                // Every group as tall as the tallest.
                .fixedSize(horizontal: false, vertical: true)
            }
            footer
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(width: Self.width)
        .task {
            while !Task.isCancelled {
                model.refresh()
                let shown = ErrorNotice.message(model.lastError, at: model.lastErrorTime, now: .now)
                if shown != notice { notice = shown }
                try? await Task.sleep(for: .milliseconds(40))
            }
        }
    }
}

/// The engraved diamond band, repeated across the panel (and behind the
/// khomus in the footer); nothing where the artwork is missing.
struct OrnamentBand: View {

    private static let height: CGFloat = 12

    /// The ornament's artwork at the band's height, ready to be tiled.
    @MainActor
    private static let image: NSImage? = {
        guard let ornament = Artwork.ornament, ornament.size.height > 0 else { return nil }
        let band = ornament.copy() as! NSImage
        band.size = NSSize(width: ornament.size.width * height / ornament.size.height, height: height)
        return band
    }()

    var body: some View {
        if let image = Self.image {
            Image(nsImage: image)
                .resizable(resizingMode: .tile)
                .frame(height: Self.height)
                .opacity(0.85)
                .accessibilityHidden(true)
        }
    }
}
