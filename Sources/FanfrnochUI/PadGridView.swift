import SwiftUI
import FanfrnochCore

/// The sixteen pads, 4 × 4, pad 01 top left. A click selects a pad and hits
/// it: soft near its top, firmer further down (`KeyStrip`); letting go ends
/// the note. Each tile shows the pad's number and name, its pitch and its
/// group; the selected pad has an aurora outline, and a pad lights up for a
/// moment whenever it is hit, from the screen or from MIDI.
struct PadGridView: View {

    let model: any InstrumentModel

    static let rowHeight: CGFloat = 51
    static let spacing: CGFloat = 6
    /// The grid's height: four rows and the gaps between them.
    static var height: CGFloat { CGFloat(PadGrid.rows) * rowHeight + CGFloat(PadGrid.rows - 1) * spacing }

    /// The pads lit by a hit, each with the number of its latest flash: a
    /// flash ends only if no newer hit has lit the pad again.
    @State private var lit: [Int: Int] = [:]

    var body: some View {
        // The counters the panel's 40 ms refresh brings up to date.
        let hits = (0..<PadGrid.rows * PadGrid.columns).map(model.padHits)
        Grid(horizontalSpacing: Self.spacing, verticalSpacing: Self.spacing) {
            ForEach(0..<PadGrid.rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<PadGrid.columns, id: \.self) { column in
                        let pad = PadGrid.pad(row: row, column: column)
                        PadTile(pad: pad, model: model, lit: lit[pad] != nil)
                    }
                }
            }
        }
        .onChange(of: hits) { old, new in
            for pad in PadGrid.hit(between: old, and: new) { flash(pad) }
        }
    }

    private func flash(_ pad: Int) {
        let flash = (lit[pad] ?? 0) + 1
        lit[pad] = flash
        Task {
            try? await Task.sleep(for: PadGrid.flash)
            if lit[pad] == flash {
                withAnimation(.easeOut(duration: 0.1)) { lit[pad] = nil }
            }
        }
    }
}

/// One pad on glass: "05 Zambomba" over "C2  G1".
private struct PadTile: View {

    let pad: Int
    let model: any InstrumentModel
    let lit: Bool

    /// True from the mouse going down on the pad until it goes up.
    @State private var down = false
    /// True while the mouse is down; SwiftUI puts it back however the press stops.
    @GestureState private var pressing = false

    private static let corner: CGFloat = 10

    var body: some View {
        let selected = model.selectedPad == pad
        let name = model.padName(pad)
        VStack(spacing: 3) {
            HStack(spacing: 6) {
                Text(PadLabel.number(pad))
                Text(name)
            }
            .font(.system(size: 17, weight: .semibold, design: .serif))
            .foregroundStyle(Artwork.silver)
            .lineLimit(1)
            Text(PadLabel.pitchAndGroup(note: model.padNote(pad), group: model.padGroup(pad)))
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(Artwork.bone)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: PadGridView.rowHeight)
        // The outline is part of what the glass carries, as the name is: inside the footer's
        // GlassEffectContainer an overlay after the glass is drawn under it and does not show.
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: Self.corner)
                    .strokeBorder(Artwork.aurora, lineWidth: 2)
                    .shadow(color: Artwork.aurora.opacity(0.6), radius: 4)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(.rect(cornerRadius: Self.corner))
        .glassEffect(.regular.tint(lit ? Artwork.aurora.opacity(0.6) : Artwork.midnight.opacity(0.35)).interactive(),
                     in: .rect(cornerRadius: Self.corner))
        .shadow(color: lit ? Artwork.aurora.opacity(0.8) : .clear, radius: 10)
        .gesture(hit)
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { release() }
        }
        .onDisappear(perform: release)
        .help("Click to select the pad and play it: near the top for a soft hit, further down for a harder one")
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { model.selectedPad = pad }
    }

    /// Down selects the pad and hits it; up lets it go.
    private var hit: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, isPressing, _ in isPressing = true }
            .onChanged { drag in
                guard !down else { return }
                down = true
                model.selectedPad = pad
                model.hitPad(pad, velocity: KeyStrip.velocity(at: drag.startLocation.y, height: PadGridView.rowHeight))
            }
            .onEnded { _ in release() }
    }

    private func release() {
        guard down else { return }
        down = false
        model.releasePad(pad)
    }
}
