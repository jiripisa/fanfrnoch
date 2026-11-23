import SwiftUI
import FanfrnochCore

/// The top of the panel: the emblem and the wordmark, the Program and Preset
/// menus (both load into the set the knobs show), the mode switch (Keyboard |
/// Pads) and the buttons LFO 1, LFO 2 and VEL, which turn the knobs into that
/// source's amounts, and MIDI, which shows their controllers (its menu under a
/// secondary click gives every control its standard controller back).
/// `trailing` comes last, on the right. `notice`, a file's error, shows in a
/// line under the menus.
struct HeaderView<Trailing: View>: View {

    let model: any InstrumentModel
    @Binding var editing: KnobEditing
    let notice: String?
    let trailing: Trailing

    /// The width of the Program and Preset menus: one for every name, so that
    /// the header stands still. A menu button takes its width from the ticked
    /// item's name, whatever its label says, so the menu itself gets the width
    /// and fills it (`buttonSizing(.flexible)`). 150 lets the header fit the
    /// panel with the app's Settings button.
    static var menuWidth: CGFloat { 150 }

    var body: some View {
        HStack(spacing: 12) {
            wordmark
            separator
            HStack(spacing: 10) {
                programMenu
                presetMenu
            }
            // Each group at its own width: offered an even share of the header, the buttons'
            // titles would wrap and the Preset menu's title would vanish.
            .fixedSize()
            .overlay(alignment: .bottomLeading) {
                // A line of no height on the menus' bottom edge, the error hanging from it: just
                // under the menus, over what is below, and nothing in the header moves.
                Color.clear
                    .frame(height: 0)
                    .overlay(alignment: .topLeading) {
                        if let notice {
                            ErrorLine(message: notice)
                                .padding(.top, 4)
                        }
                    }
            }
            Spacer(minLength: 8)
            GlassSegments(label: "Mode", titles: ["Keyboard", "Pads"], selected: model.mode.rawValue, fontSize: 13) { index in
                model.mode = PlayMode(rawValue: index) ?? .keyboard
            }
            .help("Keyboard: the keys play the keyboard's sound. Pads: notes 36–51 hit the sixteen pads")
            separator
            HStack(spacing: 8) {
                // One at a time: the knobs can be one thing.
                ForEach(0..<LFOs.count, id: \.self) { lfo in
                    sourceButton("LFO \(lfo + 1)", .amount(lfo: lfo),
                                 help: "Drag the knobs to set how far LFO \(lfo + 1) moves them")
                }
                sourceButton("VEL", .velocity, help: "Drag the knobs to set how far a softer hit moves them")
                sourceButton("MIDI", .controller,
                             help: "Click a control, then move a control of your MIDI controller to give it to that control")
                    .contextMenu { ControllerHandling.resetButton(model: model) }
            }
            .fixedSize()
            trailing
        }
        .frame(height: 44)
    }

    private var wordmark: some View {
        HStack(spacing: 10) {
            LogoView().frame(width: LogoView.width(height: 38), height: 38)
            Text("Fanfrnoch")
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .foregroundStyle(Artwork.cream)
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }

    private var separator: some View {
        Rectangle().fill(Artwork.cream.opacity(0.3)).frame(width: 1, height: 34)
    }

    /// A menu with its name above it.
    private func titled(_ title: String, @ViewBuilder menu: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Artwork.cream)
                .padding(.leading, 6)
            menu()
        }
    }

    /// What a menu shows of the name in use, a dash for none.
    private func menuName(_ name: String?) -> some View {
        Text(name ?? "—")
            .font(.system(size: 13))
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The built-in programs, the one the shown set came from ticked.
    private var programMenu: some View {
        let set = model.shownSet
        let program = model.program(in: set)
        return titled("Program") {
            Menu {
                ForEach(Programs.names.indices, id: \.self) { index in
                    Toggle(Programs.names[index], isOn: Binding(get: { program == index },
                                                                set: { _ in model.loadProgram(index, into: set) }))
                }
            } label: {
                menuName(Programs.names.indices.contains(program) ? Programs.names[program] : nil)
            }
            .menuStyle(.button)
            .buttonStyle(.glass)
            .buttonSizing(.flexible)
            .frame(width: Self.menuWidth)
            .help(set == .keyboard ? "Load a built-in program into the keyboard's sound"
                                   : "Load a built-in program into the selected pad")
            .accessibilityLabel("Program")
        }
    }

    /// The player's presets, the shown set's preset in use ticked, and the
    /// commands that save and delete them.
    private var presetMenu: some View {
        let set = model.shownSet
        let inUse = model.presetInUse(in: set)
        let library = LibraryMenuFiles(
            entries: LibraryMenu.presets(model.presets, inUse: inUse),
            names: model.presets,
            saveTitle: set == .keyboard ? "Save the keyboard's sound as a preset" : "Save the pad's sound as a preset",
            saveNote: "Every knob of the set is stored, the octave and the LFO and velocity amounts included.",
            suggestedName: inUse ?? "",
            load: { try model.loadPreset($0, into: set) },
            save: { try model.savePreset(as: $0, from: set) },
            delete: { try model.deletePreset($0) })
        return titled("Preset") {
            LibraryMenuView(library: library, width: Self.menuWidth, opening: model.lookAtPresets) {
                menuName(inUse)
            }
            .help(set == .keyboard ? "Your presets: load one into the keyboard's sound, save it as one, delete one"
                                   : "Your presets: load one into the selected pad, save its sound as one, delete one")
            .accessibilityLabel("Preset")
        }
    }

    /// A button that turns the knobs into a source's amounts (or their
    /// controllers) and back: its colour as a dot, and filled with it while it
    /// is on. The fill sits under the glass rather than tinting it: a tint
    /// turns grey in a window that is not in front (a plug-in's, in a host).
    private func sourceButton(_ title: String, _ source: KnobEditing, help: String) -> some View {
        let on = editing == source
        return Button {
            if editing == .controller { model.learn(nil) }      // leaving the controllers: nobody is left listening
            editing = on ? .value : source
        } label: {
            HStack(spacing: 6) {
                Circle().fill(on ? Artwork.indigo.opacity(0.7) : source.colour).frame(width: 7, height: 7)
                Text(title)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(on ? Artwork.indigo : Artwork.cream)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Capsule())
            .background(on ? source.colour : Color.clear, in: Capsule())
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
        .help(on ? "Back to the knobs" : help)
        .accessibilityLabel(title)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// A file's error, for a while, in a small capsule under the header's menus:
/// cream on indigo, one line.
struct ErrorLine: View {

    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Artwork.cream)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Artwork.indigo.opacity(0.92), in: Capsule())
            .overlay(Capsule().stroke(Artwork.terracotta.opacity(0.6), lineWidth: 1))
            .fixedSize()
            .allowsHitTesting(false)            // it hangs over the controls below
            .accessibilityElement()
            .accessibilityLabel(message)
            .accessibilityAddTraits(.updatesFrequently)
    }
}
