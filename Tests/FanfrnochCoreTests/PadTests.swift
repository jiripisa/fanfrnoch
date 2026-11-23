import Foundation
import Testing
import FanfrnochDSP
@testable import FanfrnochCore

/// Pad mode: sixteen pads, each a key press frozen with its own knob set and pitch, choked by
/// their mute groups; Send to pad, and the kit the engine starts with.
@Suite("Pads")
struct PadTests: EngineHarness {

    static let pads = Int32(FANFRNOCH_MODE_PADS)
    static let firstPadNote = Int32(FANFRNOCH_FIRST_PAD_NOTE)

    /// `plain` with no breath, so that a choked ring leaves no DC in the bus (EngineTests.dry).
    static let dry = plain.merging(["breath": 0, "puff": 0]) { $1 }

    /// A fresh engine in pad mode. Every pad plays program Fanfrnoch with `plain` and then `knobs`, at
    /// note 36 with its group Off; the keyboard set has the same knobs.
    private func makePads(_ knobs: [String: Float] = [:]) -> OpaquePointer {
        let sound = Self.plain.merging(knobs) { $1 }
        let engine = makeEngine(sound)
        fanfrnoch_set_mode(engine, Self.pads)
        for pad: Int32 in 0..<Int32(FANFRNOCH_NUM_PADS) {
            fanfrnoch_set_program(engine, pad + 1, 0)
            setKnobs(engine, sound, set: pad + 1)
            fanfrnoch_set_pad_note(engine, pad, 36)
            fanfrnoch_set_pad_group(engine, pad, 0)
        }
        return engine
    }

    private func hitPad(_ engine: OpaquePointer, _ pad: Int32, velocity: Int32 = 110) {
        fanfrnoch_midi(engine, 0x90, Self.firstPadNote + pad, velocity, 0)
    }

    /// `seconds` of a fresh pad engine with `knobs`, prepared by `setup`, playing `hits`: each a
    /// pad and the time it is hit at, in order.
    private func play(_ hits: [(pad: Int32, at: Double)], seconds: Double = 1.5, _ knobs: [String: Float] = [:],
                      setup: (OpaquePointer) -> Void = { _ in }) -> [Float] {
        let engine = makePads(knobs)
        defer { fanfrnoch_destroy(engine) }
        setup(engine)
        var out: [Float] = []
        for hit in hits {
            out += render(engine, frames: Self.frames(hit.at) - out.count)
            hitPad(engine, hit.pad)
        }
        return out + render(engine, frames: Self.frames(seconds) - out.count)
    }

    private func sum(_ a: [Float], _ b: [Float]) -> [Float] { zip(a, b).map { $0 + $1 } }

    // MARK: - A pad is a frozen key press

    @Test("A pad hit is a frozen key press")
    func frozenKeyPress() {
        // A set unlike the defaults, at a pitch moved by its own Octave and Tune.
        let sound = Self.plain.merging(["ring": 2, "vowel": 1200, "edge": 26, "octave": -1, "tune": 30]) { $1 }
        let key = makeEngine(sound)
        defer { fanfrnoch_destroy(key) }
        fanfrnoch_midi(key, 0x90, 43, 110, 0)
        let played = render(key, seconds: 1.5)

        let engine = makeEngine(sound)
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, 43, 110, 0)
        _ = render(engine, frames: 128)
        fanfrnoch_send_to_pad(engine, 5)
        fanfrnoch_reset(engine)                       // silence; the pads stay as they are
        fanfrnoch_set_mode(engine, Self.pads)
        hitPad(engine, 5)
        let r = residualDb(render(engine, seconds: 1.5), played)
        #expect(r < -100, "residual \(r) dB")
    }

    // With the vowel held still and the throat and the buzz turned down, Close shuts most of the
    // sound (ModulationTests.liveKnobs).
    @Test("Pads ignore later knob changes; keyboard voices follow them")
    func padsAreFrozen() {
        func play(_ mode: Int32, closeAtHalf: Bool) -> [Float] {
            let engine = makePads(["sweep": 0, "throat": -30, "buzz": 0])
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_set_mode(engine, mode)
            fanfrnoch_midi(engine, 0x90, 36, 110, 0)
            var out = render(engine, seconds: 0.5)
            if closeAtHalf {
                for set: Int32 in 0..<Int32(FANFRNOCH_NUM_SETS) { fanfrnoch_set_plain(engine, set, Self.index("close"), 100) }
            }
            out += render(engine, seconds: 0.5)
            return out
        }
        let pad = play(Self.pads, closeAtHalf: true)
        #expect(rms(pad) > 0.001)
        #expect(pad == play(Self.pads, closeAtHalf: false))
        let half = Self.frames(0.5)
        let keyboard = Int32(FANFRNOCH_MODE_KEYBOARD)
        let drop = 20 * log10(rms(play(keyboard, closeAtHalf: true)[half...]) / rms(play(keyboard, closeAtHalf: false)[half...]))
        #expect(drop < -6, "the keyboard voice changed by \(drop) dB")
    }

    @Test("Pad mode ignores notes outside 36–51")
    func padModeIgnoresOtherNotes() {
        let engine = makePads()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, 35, 110, 0)
        fanfrnoch_midi(engine, 0x90, 52, 110, 0)
        #expect(render(engine, seconds: 0.5).allSatisfy { $0 == 0 })
        #expect(fanfrnoch_sounding_voices(engine) == 0)
        fanfrnoch_midi(engine, 0x90, 36, 110, 0)
        fanfrnoch_midi(engine, 0x90, 51, 110, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_sounding_voices(engine) == 2)
    }

    // MARK: - Mute groups

    // Volume -12 dB keeps the two rings under the limiter, so that the bus adds them linearly.
    @Test("Same-pitch pads with Group Off ring over each other")
    func groupOffRingsOver() {
        let knobs = Self.dry.merging(["volume": -12]) { $1 }
        let both = play([(0, 0), (1, 0.5)], knobs)
        let lone = sum(play([(0, 0)], knobs), play([(1, 0.5)], knobs))
        let r = residualDb(both, lone)
        #expect(r < -100, "residual \(r) dB")
    }

    @Test("A hit chokes the other pads of its group")
    func groupChokes() {
        let from = Self.frames(0.5 + 0.020)                  // 20 ms after the second hit: Damp is 10 ms
        for note: Int32 in [36, 43] {                         // whatever the pitch
            let grouped = play([(0, 0), (1, 0.5)], Self.dry) { engine in
                fanfrnoch_set_pad_group(engine, 0, 1); fanfrnoch_set_pad_group(engine, 1, 1)
                fanfrnoch_set_pad_note(engine, 1, note)
            }
            let second = play([(1, 0.5)], Self.dry) { fanfrnoch_set_pad_note($0, 1, note) }
            let r = residualDb(grouped[from...], second[from...])
            #expect(r < -60, "note \(note): residual \(r) dB")
        }
        // Without the group the first ring is still there.
        let ungrouped = play([(0, 0), (1, 0.5)], Self.dry), second = play([(1, 0.5)], Self.dry)
        #expect(residualDb(ungrouped[from...], second[from...]) > -30)
    }

    @Test("Stroke Alternate alternates across a group")
    func alternateAcrossGroup() {
        let alternate = Self.dry.merging(["stroke": 2, "volume": -12]) { $1 }
        let group1: (OpaquePointer) -> Void = { fanfrnoch_set_pad_group($0, 0, 1); fanfrnoch_set_pad_group($0, 1, 1) }
        // In a group the two pads are one harp: the second hit strokes the other way.
        #expect(play([(0, 0), (1, 0.5)], alternate, setup: group1) == play([(0, 0), (0, 0.5)], alternate, setup: group1))
        // With Group Off each pad alternates on its own: pad 1's first hit strokes out, as a
        // lone first hit does.
        let both = play([(0, 0), (1, 0.5)], alternate)
        #expect(both != play([(0, 0), (0, 0.5)], alternate))
        let r = residualDb(both, sum(play([(0, 0)], alternate), play([(1, 0.5)], alternate)))
        #expect(r < -100, "residual \(r) dB")
    }

    /// `first` rings from 0 s and `second` is hit at 0.5 s, with Volume -12 dB and no breath:
    /// what the two play together is the sum of the two alone, so the second chokes nothing.
    private func ringOver(_ first: Int32, _ second: Int32, setup: @escaping (OpaquePointer) -> Void) -> Double {
        let knobs = Self.dry.merging(["volume": -12]) { $1 }
        let both = play([(first, 0), (second, 0.5)], knobs, setup: setup)
        return residualDb(both, sum(play([(first, 0)], knobs, setup: setup), play([(second, 0.5)], knobs, setup: setup)))
    }

    @Test("A hit chokes no pad of another group")
    func otherGroupRingsOn() {
        let r = ringOver(0, 1) { fanfrnoch_set_pad_group($0, 0, 2); fanfrnoch_set_pad_group($0, 1, 1) }
        #expect(r < -100, "residual \(r) dB")
    }

    @Test("A grouped hit leaves a pad with Group Off alone, and the other way round")
    func groupOffIsApart() {
        let grouped = ringOver(0, 1) { fanfrnoch_set_pad_group($0, 1, 1) }      // pad 1 Off rings, pad 2 in group 1 hits
        #expect(grouped < -100, "residual \(grouped) dB")
        let off = ringOver(0, 1) { fanfrnoch_set_pad_group($0, 0, 1) }          // pad 1 in group 1 rings, pad 2 Off hits
        #expect(off < -100, "residual \(off) dB")
    }

    @Test("After a reset Stroke Alternate starts again from the first direction")
    func alternateRestartsAtReset() {
        let alternate = Self.dry.merging(["stroke": 2]) { $1 }
        for mode in [Int32(FANFRNOCH_MODE_KEYBOARD), Self.pads] {
            let engine = makePads(alternate)
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_set_mode(engine, mode)
            fanfrnoch_midi(engine, 0x90, 36, 110, 0)
            let first = render(engine, seconds: 0.5)
            fanfrnoch_reset(engine)
            fanfrnoch_midi(engine, 0x90, 36, 110, 0)
            #expect(render(engine, seconds: 0.5) == first, "mode \(mode)")
        }
    }

    @Test("A velocity-0 note-on is a note-off")
    func velocityZeroIsNoteOff() {
        // The pad's own Key Up decides; the keyboard set's is Ring.
        func release(_ status: Int32, keyUp: Float) -> (sounding: Int32, tail: [Float]) {
            let engine = makePads(Self.dry)
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_set_plain(engine, 1, Self.index("keyup"), keyUp)
            hitPad(engine, 0)
            _ = render(engine, seconds: 0.5)
            fanfrnoch_midi(engine, status, 36, 0, 0)
            _ = render(engine, seconds: 0.05)
            return (fanfrnoch_sounding_voices(engine), render(engine, seconds: 0.2))
        }
        let noteOn0 = release(0x90, keyUp: 1), noteOff = release(0x80, keyUp: 1)
        #expect(noteOn0.sounding == 0 && noteOff.sounding == 0)
        #expect(noteOn0.tail == noteOff.tail)
        #expect(release(0x90, keyUp: 0).sounding == 1)
    }

    // MARK: - Send to pad and the kit

    @Test("Send to pad copies the set and the last note, and keeps the group")
    func sendToPad() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_set_program(engine, Self.keyboard, 2)
        setKnobs(engine, ["ring": 2, "vowel": 1200, "octave": 1, "lfo1vowel": 40])

        fanfrnoch_send_to_pad(engine, 2)                       // no note played yet: C2
        #expect(fanfrnoch_pad_note(engine, 2) == 36)

        fanfrnoch_set_pad_group(engine, 3, 5)
        fanfrnoch_midi(engine, 0x90, 43, 110, 0)
        _ = render(engine, frames: 128)
        fanfrnoch_send_to_pad(engine, 3)
        #expect(fanfrnoch_pad_note(engine, 3) == 43 && fanfrnoch_pad_group(engine, 3) == 5)
        #expect(fanfrnoch_get_program(engine, 4) == 2)
        for i in 0..<fanfrnoch_num_params() {
            #expect(fanfrnoch_get_normalised(engine, 4, i) == fanfrnoch_get_normalised(engine, Self.keyboard, i), "parameter \(i)")
        }

        fanfrnoch_reset(engine)                                // forgets the last note
        #expect(fanfrnoch_last_note(engine) == -1)
        fanfrnoch_send_to_pad(engine, 4)
        #expect(fanfrnoch_pad_note(engine, 4) == 36)
    }

    /// The kit of the engine design (§7): pads 9–16 are pads 1–8 a fifth higher, in groups 5–8.
    static let kit: [(note: Int32, program: Int32, group: Int32)] = [
        (36, 0, 1), (36, 0, 1), (39, 5, 0), (43, 1, 2), (48, 3, 3), (38, 2, 4), (39, 4, 0), (41, 6, 0),
        (43, 0, 5), (43, 0, 5), (46, 5, 0), (50, 1, 6), (55, 3, 7), (45, 2, 8), (46, 4, 0), (48, 6, 0),
    ]

    /// The kit's programs by name, as the design's table gives them.
    static let kitPrograms = ["Fanfrnoch", "Fanfrnoch", "Bamboo", "Molln", "Morsing", "Khomus", "Đàn Môi", "Genggong"]

    private func expectDefaultKit(_ engine: OpaquePointer) {
        let ring = Self.index("ring"), octave = Self.index("octave")
        #expect(Self.kit.map { Programs.names[Int($0.program)] } == Self.kitPrograms + Self.kitPrograms)
        for (pad, expected) in Self.kit.enumerated() {
            let p = Int32(pad), set = p + 1
            #expect(fanfrnoch_pad_note(engine, p) == expected.note, "pad \(pad + 1)")
            #expect(fanfrnoch_pad_group(engine, p) == expected.group, "pad \(pad + 1)")
            #expect(fanfrnoch_get_program(engine, set) == expected.program, "pad \(pad + 1)")
            for i in 0..<fanfrnoch_num_params() {
                var want = fanfrnoch_program_value(expected.program, i)
                if i == ring && (pad == 1 || pad == 9) { want = 0.6 }       // the short Fanfrnoch
                if i == octave { want = 0 }
                let got = fanfrnoch_get_plain(engine, set, i)
                #expect(abs(got - want) <= 1e-4 * max(1, abs(want)), "pad \(pad + 1), parameter \(i): \(got), not \(want)")
            }
        }
    }

    @Test("The default kit is loaded at creation")
    func defaultKit() {
        let engine = fanfrnoch_create()!
        defer { fanfrnoch_destroy(engine) }
        expectDefaultKit(engine)
    }

    @Test("A reset leaves the pads alone; Load Default Kit puts the kit back")
    func resetKeepsPads() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        for set: Int32 in 1...16 { fanfrnoch_set_program(engine, set, 6); fanfrnoch_set_plain(engine, set, Self.index("octave"), 2) }
        for pad: Int32 in 0..<16 { fanfrnoch_set_pad_note(engine, pad, 60); fanfrnoch_set_pad_group(engine, pad, 16) }
        fanfrnoch_reset(engine)
        #expect(fanfrnoch_get_program(engine, 1) == 6 && fanfrnoch_get_plain(engine, 1, Self.index("octave")) == 2)
        #expect(fanfrnoch_pad_note(engine, 0) == 60 && fanfrnoch_pad_group(engine, 0) == 16)
        fanfrnoch_load_default_kit(engine)
        expectDefaultKit(engine)
    }

    // MARK: - Modes and wheels

    @Test("Mode switch leaves ringing voices alone")
    func modeSwitch() {
        func play(from: Int32, switching: Bool) -> [Float] {
            let engine = makePads()
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_set_mode(engine, from)
            fanfrnoch_midi(engine, 0x90, 37, 110, 0)
            var out = render(engine, seconds: 0.5)
            if switching { fanfrnoch_set_mode(engine, 1 - from) }
            out += render(engine, seconds: 1.0)
            return out
        }
        for mode in [Int32(FANFRNOCH_MODE_KEYBOARD), Self.pads] {
            let switched = play(from: mode, switching: true)
            #expect(rms(switched[Self.frames(0.5)...]) > 0.001, "from mode \(mode)")
            #expect(switched == play(from: mode, switching: false), "from mode \(mode)")
        }
    }

    /// A hit on note 36 in `first` mode, and at 0.5 s another on note 36 in the other mode: with
    /// Volume -12 dB and no breath, the sum of the two alone.
    private func acrossModes(from first: Int32) -> Double {
        func play(firstHit: Bool, secondHit: Bool) -> [Float] {
            let engine = makePads(Self.dry.merging(["volume": -12]) { $1 })
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_set_mode(engine, first)
            if firstHit { fanfrnoch_midi(engine, 0x90, 36, 110, 0) }
            var out = render(engine, seconds: 0.5)
            fanfrnoch_set_mode(engine, 1 - first)
            if secondHit { fanfrnoch_midi(engine, 0x90, 36, 110, 0) }
            out += render(engine, seconds: 1.0)
            return out
        }
        return residualDb(play(firstHit: true, secondHit: true),
                          sum(play(firstHit: true, secondHit: false), play(firstHit: false, secondHit: true)))
    }

    @Test("A pad hit leaves a ringing key of the same note alone, and the other way round")
    func keysAndPadsApart() {
        let padOverKey = acrossModes(from: Int32(FANFRNOCH_MODE_KEYBOARD))
        #expect(padOverKey < -100, "residual \(padOverKey) dB")
        let keyOverPad = acrossModes(from: Self.pads)
        #expect(keyOverPad < -100, "residual \(keyOverPad) dB")
    }

    @Test("Wheels change keyboard voices, not ringing pad voices")
    func wheelsLeavePadsAlone() {
        func play(_ mode: Int32, wheels: Bool) -> [Float] {
            let engine = makePads(["sweep": 0])
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_set_mode(engine, mode)
            fanfrnoch_midi(engine, 0x90, 36, 110, 0)
            var out = render(engine, seconds: 0.3)
            if wheels {
                fanfrnoch_midi(engine, 0xB0, 1, 127, 0)        // mod wheel: Close
                fanfrnoch_midi(engine, 0xD0, 127, 0, 0)        // aftertouch: Breath
                fanfrnoch_midi(engine, 0xE0, 0x7F, 0x7F, 0)    // pitch bend: Vowel
            }
            out += render(engine, seconds: 1.0)
            return out
        }
        let pad = play(Self.pads, wheels: true)
        #expect(rms(pad) > 0.001)
        #expect(pad == play(Self.pads, wheels: false))
        #expect(play(Int32(FANFRNOCH_MODE_KEYBOARD), wheels: true) != play(Int32(FANFRNOCH_MODE_KEYBOARD), wheels: false))
    }
}
