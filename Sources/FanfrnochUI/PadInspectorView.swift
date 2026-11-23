import SwiftUI
import FanfrnochCore

/// Beside the pads: "Pads" between two ornaments, which pad is selected, the
/// drum, and the pad's pitch and group and the Kit menu. The pitch and the
/// group belong to the pad, not to its knobs: all the pads of a group are one
/// drum. A kit is all sixteen pads, their sounds, pitches and groups.
struct PadInspectorView: View {

    let model: any InstrumentModel

    static let width: CGFloat = 300
    private static let menuWidth: CGFloat = 132
    private static let drumHeight: CGFloat = 96

    var body: some View {
        let pad = model.selectedPad
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 10) {
                OrnamentBand().frame(maxWidth: .infinity)
                Text("Pads")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(Artwork.cream)
                    .fixedSize()
                OrnamentBand().frame(maxWidth: .infinity)
            }
            Text("Selected: \(PadLabel.title(pad, name: model.padName(pad)))")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(Artwork.cream)
                .lineLimit(1)
            HStack(alignment: .bottom, spacing: 10) {
                DrumView()
                    .frame(width: DrumView.width(height: Self.drumHeight), height: Self.drumHeight)
                VStack(alignment: .trailing, spacing: 5) {
                    labelled("Pitch") { pitchMenu(pad) }
                    labelled("Group") { groupMenu(pad) }
                    labelled("Kit") { kitMenu }
                }
            }
        }
    }

    /// A menu with its name on the left, as wide as the others.
    private func labelled(_ title: String, @ViewBuilder control: () -> some View) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Artwork.cream)
            control()
                .frame(width: Self.menuWidth)
        }
    }

    /// The player's kits, the engine's own, and the commands that save and delete them.
    private var kitMenu: some View {
        let library = LibraryMenuFiles(
            entries: LibraryMenu.kits(model.kits),
            names: model.kits,
            saveTitle: "Save the pads as a kit",
            saveNote: "All sixteen pads are stored: their sounds, pitches and groups.",
            suggestedName: "",
            load: { try model.loadKit($0) },
            loadStandard: model.loadDefaultKit,
            save: { try model.saveKit(as: $0) },
            delete: { try model.deleteKit($0) })
        // No kit is "in use": a kit loads sixteen pads, which are then edited one by one.
        return LibraryMenuView(library: library, width: Self.menuWidth, opening: model.lookAtPresets) {
            Text("Load or save")
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .help("Your kits: load all sixteen pads from one, save them as one, delete one, or go back to the default kit")
        .accessibilityLabel("Kit")
    }

    /// Every note, an octave to a submenu, the pad's own ticked.
    private func pitchMenu(_ pad: Int) -> some View {
        let note = model.padNote(pad)
        return Menu {
            ForEach(Notes.octaves, id: \.lowerBound) { octave in
                Menu("\(Notes.name(octave.lowerBound)) – \(Notes.name(octave.upperBound))") {
                    ForEach(Array(octave), id: \.self) { candidate in
                        Toggle(Notes.name(candidate), isOn: Binding(get: { candidate == note },
                                                                     set: { _ in model.setPadNote(candidate, pad: pad) }))
                    }
                }
            }
        } label: {
            Text(Notes.name(note))
                .font(.system(size: 13).monospacedDigit())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .menuStyle(.button)
        .buttonStyle(.glass)
        .buttonSizing(.flexible)
        .help("The pad's pitch")
        .accessibilityLabel("Pitch")
    }

    /// Off, or one of sixteen groups: the pads of a group are one drum, and a hit on any of
    /// them goes on from where that drum is.
    private func groupMenu(_ pad: Int) -> some View {
        let group = model.padGroup(pad)
        return Menu {
            Toggle("Off", isOn: Binding(get: { group == nil }, set: { _ in model.setPadGroup(nil, pad: pad) }))
            Divider()
            ForEach(1...16, id: \.self) { candidate in
                Toggle("\(candidate)", isOn: Binding(get: { candidate == group },
                                                    set: { _ in model.setPadGroup(candidate, pad: pad) }))
            }
        } label: {
            Text(group.map(String.init) ?? "Off")
                .font(.system(size: 13).monospacedDigit())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .menuStyle(.button)
        .buttonStyle(.glass)
        .buttonSizing(.flexible)
        .help("Off: the pad is a drum of its own. A group: its pads are one drum, and a hit on any of them goes on from where that drum is")
        .accessibilityLabel("Group")
    }
}
