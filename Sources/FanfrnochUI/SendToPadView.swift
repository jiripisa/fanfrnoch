import SwiftUI
import FanfrnochCore

/// What the "Send to pad" button opens: the sixteen pads, each with its
/// number, name and pitch. A click on one asks, right here, whether to
/// replace that pad's sound with the keyboard's at the last note played (C2
/// before any); Replace copies it and closes. No alert: alerts misbehave in a
/// plug-in's window.
struct SendToPadView: View {

    let model: any InstrumentModel
    @Binding var isPresented: Bool

    /// The pad chosen, waiting for Replace or Cancel; nil before a choice.
    @State private var asking: Int?

    private static let tileWidth: CGFloat = 104
    private static let spacing: CGFloat = 6

    /// `asking` is the pad the view opens asking about, for a picture of that
    /// state; the button opens it with no pad chosen.
    init(model: any InstrumentModel, isPresented: Binding<Bool>, asking: Int? = nil) {
        self.model = model
        _isPresented = isPresented
        _asking = State(initialValue: asking)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Send to pad")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Artwork.cream)
                Text("Choose the pad that takes the keyboard's sound.")
                    .font(.system(size: 12))
                    .foregroundStyle(Artwork.parchment)
            }
            Grid(horizontalSpacing: Self.spacing, verticalSpacing: Self.spacing) {
                ForEach(0..<PadGrid.rows, id: \.self) { row in
                    GridRow {
                        ForEach(0..<PadGrid.columns, id: \.self) { column in
                            tile(PadGrid.pad(row: row, column: column))
                        }
                    }
                }
            }
            if let pad = asking {
                question(pad)
            }
        }
        .padding(14)
        .fixedSize()
        // The popover in the panel's dark look, whatever the system's.
        .preferredColorScheme(.dark)
    }

    private func tile(_ pad: Int) -> some View {
        let chosen = asking == pad
        return Button {
            asking = pad
        } label: {
            VStack(spacing: 2) {
                Text("\(PadLabel.number(pad))  \(model.padName(pad))")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(Artwork.cream)
                    .lineLimit(1)
                Text(Notes.name(model.padNote(pad)))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Artwork.parchment)
            }
            .padding(.horizontal, 4)
            .frame(width: Self.tileWidth, height: 38)
            .background(chosen ? Artwork.terracotta.opacity(0.25) : Artwork.indigo.opacity(0.5),
                        in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(chosen ? Artwork.terracotta : Artwork.cream.opacity(0.2), lineWidth: chosen ? 2 : 1)
            }
            .contentShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PadLabel.title(pad, name: model.padName(pad)))
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    /// "Replace pad 05 · Zambomba with the keyboard's sound at C3?" [Cancel] [Replace]
    private func question(_ pad: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(PadLabel.sendQuestion(pad: pad, name: model.padName(pad), lastNote: model.lastNote))
                .font(.system(size: 13))
                .foregroundStyle(Artwork.cream)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("Cancel") { asking = nil }
                    .keyboardShortcut(.cancelAction)
                Button("Replace") {
                    model.sendToPad(pad)
                    asking = nil
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .tint(Artwork.terracotta)
            }
            .controlSize(.large)
        }
        .frame(width: CGFloat(PadGrid.columns) * Self.tileWidth + CGFloat(PadGrid.columns - 1) * Self.spacing,
               alignment: .leading)
    }
}
