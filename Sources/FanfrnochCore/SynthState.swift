import FanfrnochDSP
import Foundation

/// A set of knobs saved by name: the keyboard's or a pad's.
public struct SetState: Codable, Equatable, Sendable {
    /// The built-in program the set last loaded.
    public var program: Int
    /// Plain values by parameter identifier.
    public var values: [String: Float]
    /// The preset the set came from, nil for a built-in program or a sound made by hand.
    public var preset: String?

    public init(program: Int, values: [String: Float], preset: String? = nil) {
        self.program = program
        self.values = values
        self.preset = preset
    }

    /// A field the data lacks gets its default (program 0, no values: every knob takes its
    /// program's value, no preset); a field this version does not know is ignored.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        program = try container.decodeIfPresent(Int.self, forKey: .program) ?? 0
        values = try container.decodeIfPresent([String: Float].self, forKey: .values) ?? [:]
        preset = try container.decodeIfPresent(String.self, forKey: .preset)
    }
}

/// A pad saved with its sound.
public struct PadState: Codable, Equatable, Sendable {
    public var note: Int
    /// The mute group, 1...16; nil for Off.
    public var group: Int?
    public var set: SetState

    public init(note: Int, group: Int?, set: SetState) {
        self.note = note
        self.group = group
        self.set = set
    }

    /// A field the data lacks gets its default (C2, Off, an empty set); a field this version does
    /// not know is ignored.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        note = try container.decodeIfPresent(Int.self, forKey: .note) ?? 36
        group = try container.decodeIfPresent(Int.self, forKey: .group)
        set = try container.decodeIfPresent(SetState.self, forKey: .set) ?? SetState(program: 0, values: [:])
    }
}

/// Everything a host or the app saves of a Fanfrnoch: the mode, the keyboard's sound and the sixteen pads.
public struct SynthState: Codable, Equatable, Sendable {
    public var mode: PlayMode
    public var keyboard: SetState
    /// The sixteen pads, in order.
    public var pads: [PadState]

    public init(mode: PlayMode, keyboard: SetState, pads: [PadState]) {
        self.mode = mode
        self.keyboard = keyboard
        self.pads = pads
    }

    /// A saved sound survives the format growing: a field the data lacks gets its default
    /// (keyboard mode, an empty keyboard set, no pads, which leaves the pads alone), and a field
    /// this version does not know is ignored.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decodeIfPresent(PlayMode.self, forKey: .mode) ?? .keyboard
        keyboard = try container.decodeIfPresent(SetState.self, forKey: .keyboard) ?? SetState(program: 0, values: [:])
        pads = try container.decodeIfPresent([PadState].self, forKey: .pads) ?? []
    }
}

extension Synth {

    /// The engine keeps knobs as 0...1 positions, so a plain value comes back a few ulps off what
    /// was set (429.99997 for 430). Six significant digits make the saved value stable: reading a
    /// state and writing it back reads the same state again.
    private static func stable(_ plain: Float) -> Float {
        Float(String(format: "%.6g", Double(plain))) ?? plain
    }

    /// One set's knobs as they are now, with no preset: the models remember that.
    public func state(of set: SoundSet) -> SetState {
        SetState(program: program(in: set),
                 values: Dictionary(uniqueKeysWithValues: Parameters.all.map {
                     ($0.identifier, Self.stable(value(of: $0, in: set)))
                 }))
    }

    /// Everything that is saved: read each part separately, so a state taken while audio runs may
    /// mix values from different moments.
    public var state: SynthState {
        SynthState(mode: mode,
                   keyboard: state(of: .keyboard),
                   pads: (0..<Int(FANFRNOCH_NUM_PADS)).map { pad in
                       PadState(note: padNote(pad) ?? 0, group: padGroup(pad), set: state(of: .pad(pad)))
                   })
    }

    /// Puts a saved state in. A value for a name this version does not know is ignored, a knob the
    /// state does not mention takes the value of the state's program, and fewer than sixteen pads
    /// leave the rest alone.
    public func apply(_ state: SynthState) {
        mode = state.mode
        apply(state.keyboard, to: .keyboard)
        for (pad, saved) in state.pads.prefix(Int(FANFRNOCH_NUM_PADS)).enumerated() {
            setPadNote(saved.note, pad: pad)
            setPadGroup(saved.group, pad: pad)
            apply(saved.set, to: .pad(pad))
        }
    }

    /// Puts one set's saved knobs in: its program first, then each value; a knob the set does not
    /// mention takes the program's value (the octave too, which loading a program leaves alone).
    /// The set's `preset` is not the engine's to keep: the models remember it.
    public func apply(_ saved: SetState, to set: SoundSet) {
        // A program number that is no program (a damaged or newer file) leaves the set's own.
        let program = Programs.names.indices.contains(saved.program) ? saved.program : self.program(in: set)
        if program != self.program(in: set) { loadProgram(program, into: set) }
        for parameter in Parameters.all where saved.values[parameter.identifier] == nil {
            setValue(Programs.value(program: program, parameter: parameter), of: parameter, in: set)
        }
        for (identifier, plain) in saved.values {
            if let parameter = Parameters.named(identifier) { setValue(plain, of: parameter, in: set) }
        }
    }
}

extension SetState {

    /// Every knob's plain value as `Synth.apply(_:to:)` puts the set in, by parameter index, with
    /// the program it loads: the set's own values, kept within each knob's range and on the steps
    /// of integers and choices, and the program's value for a knob the set does not mention. A
    /// program number that is no program leaves `currentProgram`. For a set that goes in value by
    /// value from outside the engine: the plug-in window sets the keyboard's as the unit's
    /// parameters, so that a host hears of each.
    public func resolved(currentProgram: Int) -> (program: Int, values: [Float]) {
        let program = Programs.names.indices.contains(self.program) ? self.program : currentProgram
        let values = Parameters.all.map { parameter -> Float in
            guard let plain = values[parameter.identifier], plain.isFinite else {
                return Programs.value(program: program, parameter: parameter)
            }
            let stepped = parameter.kind == .continuous ? plain : plain.rounded()
            return min(max(stepped, parameter.range.lowerBound), parameter.range.upperBound)
        }
        return (program, values)
    }
}

extension SynthState {

    /// The preset each set came from: the keyboard's first, then the pads' in order; nil for
    /// none. Setting it names as many pads as the state has and ignores the rest.
    public var presetNames: [String?] {
        get { [keyboard.preset] + pads.map(\.set.preset) }
        set {
            keyboard.preset = newValue.first ?? nil
            for (pad, name) in newValue.dropFirst().prefix(pads.count).enumerated() { pads[pad].set.preset = name }
        }
    }
}
