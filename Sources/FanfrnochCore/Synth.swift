import FanfrnochDSP

/// What the keyboard plays: the keyboard's own sound at the pitch of each key, or the sixteen
/// pads, each with a sound and a pitch of its own, hit by notes 36-51.
public enum PlayMode: Int, Codable, Sendable {
    case keyboard = 0
    case pads = 1
}

/// A set of knobs: the keyboard's, or one of the sixteen pads'.
public enum SoundSet: Hashable, Sendable {
    case keyboard
    /// A pad, 0...15. A pad outside that range is no set: `Synth` ignores it.
    case pad(Int)

    /// The engine's index of the set: 0 for the keyboard, 1...16 for a pad, and -1 for a pad
    /// outside 0...15, which the engine ignores.
    var index: Int32 {
        switch self {
        case .keyboard: Int32(FANFRNOCH_KEYBOARD_SET)
        case .pad(let pad): Synth.padIndex(pad).map { $0 + 1 } ?? -1
        }
    }

    /// False for a pad outside 0...15.
    var exists: Bool { index >= 0 }
}

/// One Fanfrnoch: the sound engine with its parameters, pads, MIDI input and audio output.
///
/// Thread rules (the engine's own): `render` belongs to the audio thread; parameters, programs,
/// the mode, the pads and `postMIDI` may be used from any thread while audio runs. `prepare` must
/// not run while `render` does.
///
/// Pads are 0...15. A pad outside that range is ignored, as the engine ignores it: what is set
/// on it, sent to it or loaded into it goes nowhere, and reading it gives each parameter's
/// default value, program 0, and nil for its note and its group.
public final class Synth: @unchecked Sendable {

    /// The engine. Internal, so that the rest of the core can add to what a synth offers.
    let engine: OpaquePointer

    /// False for a synth that wraps an engine somebody else owns.
    private let ownsEngine: Bool

    public init(sampleRate: Double = 44_100) {
        engine = fanfrnoch_create()
        ownsEngine = true
        fanfrnoch_prepare(engine, sampleRate)
        fanfrnoch_reset(engine)
    }

    /// Wraps an engine the caller owns, such as the Audio Unit's: nothing is prepared, and the
    /// engine is not destroyed with the synth, which must not outlive it.
    public init(borrowing engine: OpaquePointer) {
        self.engine = engine
        ownsEngine = false
    }

    deinit {
        if ownsEngine { fanfrnoch_destroy(engine) }
    }

    /// Call before audio starts and whenever the sample rate changes. Like the engine's prepare,
    /// it also resets: every voice falls silent, the wheels go to rest and the last note is
    /// forgotten.
    public func prepare(sampleRate: Double) {
        fanfrnoch_prepare(engine, sampleRate)
    }

    /// Host frames the output lags the MIDI: the delay of the decimator below 88.2 kHz, where the
    /// voices run at twice the rate; 0 from 88.2 kHz up.
    public var latency: Int { Int(fanfrnoch_latency(engine)) }

    // MARK: Parameters

    /// Plain (real) value of a parameter in a set.
    public func value(of parameter: Parameter, in set: SoundSet = .keyboard) -> Float {
        guard set.exists else { return parameter.defaultValue }
        return fanfrnoch_get_plain(engine, set.index, Int32(parameter.index))
    }

    public func setValue(_ plain: Float, of parameter: Parameter, in set: SoundSet = .keyboard) {
        fanfrnoch_set_plain(engine, set.index, Int32(parameter.index), plain)
    }

    /// Knob position, 0...1.
    public func normalisedValue(of parameter: Parameter, in set: SoundSet = .keyboard) -> Float {
        guard set.exists else { return parameter.normalised(parameter.defaultValue) }
        return fanfrnoch_get_normalised(engine, set.index, Int32(parameter.index))
    }

    public func setNormalisedValue(_ normalised: Float, of parameter: Parameter, in set: SoundSet = .keyboard) {
        fanfrnoch_set_normalised(engine, set.index, Int32(parameter.index), normalised)
    }

    // MARK: Programs

    public func program(in set: SoundSet = .keyboard) -> Int {
        Int(fanfrnoch_get_program(engine, set.index))
    }

    /// Loads a built-in program into a set: every parameter but the octave is overwritten. A
    /// number that is no program is ignored.
    public func loadProgram(_ index: Int, into set: SoundSet = .keyboard) {
        guard Programs.names.indices.contains(index) else { return }
        fanfrnoch_set_program(engine, set.index, Int32(index))
    }

    /// Records which built-in program a set came from without loading it: no knob moves. For a set
    /// whose values are put in from elsewhere. A number that is no program is ignored.
    public func recordProgram(_ index: Int, in set: SoundSet = .keyboard) {
        guard Programs.names.indices.contains(index) else { return }
        fanfrnoch_set_program_index(engine, set.index, Int32(index))
    }

    // MARK: Mode and pads

    public var mode: PlayMode {
        get { PlayMode(rawValue: Int(fanfrnoch_get_mode(engine))) ?? .keyboard }
        set { fanfrnoch_set_mode(engine, Int32(newValue.rawValue)) }
    }

    /// The pitch of a pad, a MIDI note; nil for a pad outside 0...15.
    public func padNote(_ pad: Int) -> Int? {
        guard let index = Self.padIndex(pad) else { return nil }
        return Int(fanfrnoch_pad_note(engine, index))
    }

    /// A note outside 0...127 is ignored: the pad keeps its pitch.
    public func setPadNote(_ note: Int, pad: Int) {
        guard let index = Self.padIndex(pad), (0...127).contains(note) else { return }
        fanfrnoch_set_pad_note(engine, index, Int32(note))
    }

    /// The mute group of a pad, 1...16; nil for Off, and for a pad outside 0...15.
    public func padGroup(_ pad: Int) -> Int? {
        guard let index = Self.padIndex(pad) else { return nil }
        let group = Int(fanfrnoch_pad_group(engine, index))
        return group > 0 ? group : nil
    }

    /// A group outside 1...16 means Off.
    public func setPadGroup(_ group: Int?, pad: Int) {
        guard let index = Self.padIndex(pad) else { return }
        let valid = group.flatMap { (1...16).contains($0) ? $0 : nil }
        fanfrnoch_set_pad_group(engine, index, Int32(valid ?? 0))
    }

    /// How many times a pad has been hit since the engine was created, counted on the audio
    /// thread; 0 for a pad outside 0...15. The panel flashes a pad when it changes.
    public func padHits(_ pad: Int) -> Int {
        guard let index = Self.padIndex(pad) else { return 0 }
        return Int(fanfrnoch_pad_hits(engine, index))
    }

    /// The last note played in keyboard mode since the last reset; nil if none.
    public var lastNote: Int? {
        let note = Int(fanfrnoch_last_note(engine))
        return note >= 0 ? note : nil
    }

    /// Copies the keyboard's sound (and its program) and the pitch of the last note (36 if none)
    /// to a pad; the pad keeps its group. The copy goes value by value, not as a whole: a pad hit
    /// landing mid-copy freezes a mix of old and new values for that one hit.
    public func sendToPad(_ pad: Int) {
        guard let index = Self.padIndex(pad) else { return }
        fanfrnoch_send_to_pad(engine, index)
    }

    /// Puts the built-in kit into every pad (sound, pitch and group). Copies value by value like
    /// `sendToPad`: a pad hit landing mid-load freezes a mix of old and new values for that hit.
    public func loadDefaultKit() {
        fanfrnoch_load_default_kit(engine)
    }

    /// Voices playing and not being choked (at most 16).
    public var soundingVoices: Int { Int(fanfrnoch_sounding_voices(engine)) }

    /// The engine's index of a pad; nil outside 0...15.
    fileprivate static func padIndex(_ pad: Int) -> Int32? {
        pad >= 0 && pad < Int(FANFRNOCH_NUM_PADS) ? Int32(pad) : nil
    }

    // MARK: MIDI

    /// A MIDI channel-voice message from any thread; it plays at the start of the next rendered
    /// block.
    public func postMIDI(status: UInt8, data1: UInt8, data2: UInt8) {
        fanfrnoch_post_midi(engine, Int32(status), Int32(data1), Int32(data2), 0)
    }

    /// Notes and velocities outside 0...127 count as the nearest valid one; the softest hit is
    /// velocity 1, because 0 means note-off in MIDI.
    public func noteOn(_ note: Int, velocity: Int = 100) {
        postMIDI(status: 0x90, data1: Self.dataByte(note), data2: max(1, Self.dataByte(velocity)))
    }

    public func noteOff(_ note: Int) {
        postMIDI(status: 0x80, data1: Self.dataByte(note), data2: 0)
    }

    /// A MIDI data byte: 0...127.
    private static func dataByte(_ value: Int) -> UInt8 {
        UInt8(min(max(value, 0), 127))
    }

    public func allNotesOff() {
        postMIDI(status: 0xB0, data1: 123, data2: 0)
    }

    /// Lets go of everything a MIDI source may have left behind when it went away: every note,
    /// pitch bend, the mod wheel and aftertouch.
    public func releaseAll() {
        allNotesOff()
        postMIDI(status: 0xE0, data1: 0, data2: 0x40)       // pitch bend centred
        postMIDI(status: 0xB0, data1: 1, data2: 0)          // mod wheel down
        postMIDI(status: 0xD0, data1: 0, data2: 0)          // no aftertouch
    }

    // MARK: Audio

    /// Renders `frames` samples in stereo: Pan places each voice between the two buffers.
    /// `right` may be nil: `left` then gets the left channel. Audio thread only.
    public func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>?, frames: Int) {
        fanfrnoch_process(engine, left, right, Int32(frames))
    }
}
