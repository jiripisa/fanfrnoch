import SwiftUI
import FanfrnochCore

/// Three octaves of keys, C2 to B4, for playing the keyboard's sound with the
/// mouse. Where a key is pressed sets the velocity: soft near the top, firmer
/// further down (`KeyStrip`). A key sounds while the mouse holds it, tinted
/// terracotta, and stops when the mouse lets go or leaves it.
struct KeyboardStripView: View {

    let model: any InstrumentModel

    /// The key sounding from the mouse; nil once it is let go or left.
    @State private var held: Int?
    /// True from the mouse going down until it goes up: a key left during a
    /// press stays silent, and the keys passed over do not sound.
    @State private var pressed = false
    /// True while the mouse is down; SwiftUI puts it back however the press
    /// stops, also when the gesture is cancelled without `onEnded`.
    @GestureState private var pressing = false

    var body: some View {
        GeometryReader { geometry in
            let layout = KeyboardLayout(width: geometry.size.width, height: geometry.size.height)
            ZStack(alignment: .topLeading) {
                ForEach(layout.whiteKeys, id: \.note) { whiteKey($0) }
                ForEach(layout.blackKeys, id: \.note) { blackKey($0) }
            }
            // The keys are placed by offset, which leaves the stack one key in size: the
            // whole strip takes the clicks, and the layout finds the key.
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(press(on: layout))
        }
        .clipShape(.rect(cornerRadius: 6))
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { release() }
        }
        .onDisappear(perform: release)
        .help("Click a key to play it: near the top for a soft hit, further down for a harder one")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Keyboard, C2 to B4")
    }

    private func whiteKey(_ key: KeyboardLayout.Key) -> some View {
        UnevenRoundedRectangle(bottomLeadingRadius: 4, bottomTrailingRadius: 4)
            .fill(held == key.note ? Artwork.terracotta : Artwork.cream)
            .overlay {
                UnevenRoundedRectangle(bottomLeadingRadius: 4, bottomTrailingRadius: 4)
                    .strokeBorder(Artwork.indigo.opacity(0.45), lineWidth: 0.75)
            }
            .overlay(alignment: .bottomLeading) {
                if let label = KeyboardLayout.label(key.note) {
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Artwork.indigo.opacity(0.7))
                        .padding(.leading, 6)
                        .padding(.bottom, 5)
                }
            }
            .frame(width: key.width, height: key.height)
            .offset(x: key.x, y: key.y)
    }

    private func blackKey(_ key: KeyboardLayout.Key) -> some View {
        UnevenRoundedRectangle(bottomLeadingRadius: 3, bottomTrailingRadius: 3)
            .fill(held == key.note ? Artwork.terracotta : Artwork.indigo)
            .overlay {
                UnevenRoundedRectangle(bottomLeadingRadius: 3, bottomTrailingRadius: 3)
                    .strokeBorder(Artwork.cream.opacity(0.25), lineWidth: 0.75)
            }
            .shadow(color: .black.opacity(0.4), radius: 1.5, y: 1.5)
            .frame(width: key.width, height: key.height)
            .offset(x: key.x, y: key.y)
    }

    /// Down plays the key under the mouse; leaving the key or letting go stops it.
    private func press(on layout: KeyboardLayout) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, isPressing, _ in isPressing = true }
            .onChanged { drag in
                if !pressed {
                    pressed = true
                    if let press = layout.press(at: drag.startLocation.x, y: drag.startLocation.y) {
                        held = press.note
                        model.keyDown(press.note, velocity: press.velocity)
                    }
                } else if let note = held, layout.press(at: drag.location.x, y: drag.location.y)?.note != note {
                    held = nil
                    model.keyUp(note)
                }
            }
            .onEnded { _ in release() }
    }

    private func release() {
        if let held { model.keyUp(held) }
        held = nil
        pressed = false
    }
}
