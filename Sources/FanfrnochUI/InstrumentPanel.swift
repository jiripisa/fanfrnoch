import AppKit
import SwiftUI
import FanfrnochCore

/// The instrument's panel, the same in the app's window and in the plug-in's:
/// the header (`HeaderView`), an ornament band, the section cards on glass
/// where `PanelLayout` puts them (Stroke, Hands and Pitch over Friction, Body
/// and Noise, Master the full height on the right), another band, then
/// `footer` (the pads or the keyboard). The knobs show the set the model
/// shows: the keyboard's, or the selected pad's. With LFO 1, LFO 2 or VEL on
/// in the header, they set that source's amounts; with MIDI on, they show
/// their MIDI controllers and learn new ones (`KnobView`). A file's error
/// shows under the header's menus for a few seconds (`ErrorNotice`), never as
/// an alert.
///
/// `trailing` joins the header on the right, after LFO 1, LFO 2, VEL and MIDI
/// (the app's Settings button). It comes after `footer`, so that a single
/// trailing closure is the footer: `InstrumentPanel(model:) { footer } trailing: { … }`.
///
/// The panel asks the model to catch up every 40 ms: a host moves parameters
/// without telling anyone, and pads are hit from MIDI. The same beat takes the
/// error line away when its time is up.
/// The caller gives the panel its frame and `instrumentBackground()`.
public struct InstrumentPanel<Footer: View, Trailing: View>: View {

    /// The panel's width; its groups are laid out for it. Its height follows
    /// from what is in it.
    public static var width: CGFloat { 1100 }

    // A generic type has no stored statics: the measures live in `PanelMeasures`.
    private static var layout: PanelLayout { PanelMeasures.layout }
    private static var gap: CGFloat { PanelMeasures.gap }
    private static var margin: CGFloat { PanelMeasures.margin }
    private static var sideWidth: CGFloat { PanelMeasures.sideWidth }

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
        VStack(spacing: 5) {
            HeaderView(model: model, editing: $editing, notice: notice, trailing: trailing)
                .zIndex(1)              // the error line hangs over what is below
            OrnamentBand()
            // Spacing 0: glass closer than the container's spacing blends into one shape, and
            // the cards are meant to stay apart.
            GlassEffectContainer(spacing: 0) {
                HStack(alignment: .top, spacing: Self.gap) {
                    VStack(spacing: Self.gap) {
                        ForEach(Self.layout.rows.indices, id: \.self) { index in
                            row(Self.layout.rows[index])
                        }
                    }
                    if let side = Self.layout.side {
                        card(side).frame(width: Self.sideWidth)
                    }
                }
                // Master as tall as both rows, or the rows as tall as Master.
                .fixedSize(horizontal: false, vertical: true)
            }
            OrnamentBand()
            footer
                .zIndex(1)              // the drum reaches up over the band
        }
        .padding(.horizontal, Self.margin)
        .padding(.top, 4)
        .padding(.bottom, 8)
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

    /// A row of cards, each as wide as its share of the row (`PanelLayout.widths`) and as tall as
    /// the tallest.
    private func row(_ sections: [ParameterSection]) -> some View {
        let room = Self.width - 2 * Self.margin - (Self.layout.side == nil ? 0 : Self.sideWidth + Self.gap)
        let widths = PanelLayout.widths(of: sections, in: room, spacing: Self.gap, inset: SectionView.inset)
        return HStack(spacing: Self.gap) {
            ForEach(sections.indices, id: \.self) { index in
                card(sections[index]).frame(width: widths[index])
            }
        }
    }

    private func card(_ section: ParameterSection) -> some View {
        SectionView(section: section, set: model.shownSet, model: model, editing: editing)
    }
}

/// Where the panel's cards go, and the room between them.
enum PanelMeasures {
    static let layout = PanelLayout.of(ParameterSection.all)
    static let gap: CGFloat = 8
    static let margin: CGFloat = 10
    /// Master's card: two knobs side by side, and room for "LFO 1 Shape" beside its menu.
    static let sideWidth: CGFloat = 214
}

/// The cream floral band, repeated across the panel (and beside the drum in
/// the footer); nothing where the artwork is missing.
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
