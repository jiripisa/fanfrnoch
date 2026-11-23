import Foundation
import Testing
import FanfrnochReference
@testable import FanfrnochCore

/// One stroke of a spike score, `time` seconds in, on drum `drum` (an index into the render's
/// drums), with the key held `hold` seconds when the score gives a hold (render 02d).
struct SpikeStroke: Sendable {
    let time: Double
    let drum: Int
    let note: UInt8
    let accent: Float
    var hold: Double? = nil
}

/// A drum of a spike render: the engine's program and the knobs set on top of it (engine
/// identifiers, plain engine values).
struct SpikeDrum: Sendable {
    var program: Int32 = 0
    var knobs: [String: Float] = [:]

    /// What the reference plays: the spike's own values for the program, and the knobs.
    var reference: [String: Float] {
        (PrototypeScores.spikePrograms[Int(program)] ?? [:]).merging(knobs) { $1 }
    }
}

/// One of the spike's renders (`fanfrnoch_spike.cpp`, `main`): its drums and its strokes. One drum
/// is the keyboard's (Drum One); several are pads, drum n on pad n in a group of its own.
struct SpikeRender: Sendable, CustomTestStringConvertible {
    let name: String
    let drums: [SpikeDrum]
    let strokes: [SpikeStroke]

    var testDescription: String { name }
    var isPads: Bool { drums.count > 1 }

    init(_ name: String, _ drums: [SpikeDrum], _ strokes: [SpikeStroke]) {
        self.name = name
        self.drums = drums
        self.strokes = strokes
    }

    init(_ name: String, _ drum: SpikeDrum, _ strokes: [SpikeStroke]) {
        self.init(name, [drum], strokes)
    }

    init(_ name: String, _ strokes: [SpikeStroke]) {
        self.init(name, [SpikeDrum()], strokes)
    }

    /// Seconds: the last stroke and 1.5 s, as the spike renders.
    var seconds: Double { (strokes.map(\.time).max() ?? 0) + 1.5 }

    /// The pitch of a drum: every stroke of a pad's drum is at one pitch, the pad's note.
    func note(ofDrum drum: Int) -> UInt8 {
        strokes.first { $0.drum == drum }!.note
    }
}

/// One MIDI event of a score at a whole frame: a stroke (note-on) or the release of a key
/// (note-off), on a drum of the render, at the pitch `note`; in pad mode by the pad `pad`.
struct ScoreEvent {
    let frame: Int
    let drum: Int
    let note: UInt8
    let velocity: UInt8
    let noteOff: Bool
    var pad: Int = 0
}

/// The spike's scores and renders, and a way to render them through the reference (the spike
/// itself). Shared by the tests that compare the engine with it, the regression references and
/// the listening renders.
enum PrototypeScores {

    static func velocity(_ accent: Float) -> UInt8 {
        UInt8((accent * 127).rounded())
    }

    /// A note's pitch, as the engine works it out (exp2, not pow: see Voice.h).
    static func noteHz(_ note: UInt8) -> Double {
        440.0 * exp2((Double(note) - 69.0) / 12.0)
    }

    // MARK: - The spike's scores (fanfrnoch_spike.cpp:373-421)

    static let B2: UInt8 = 47, A3: UInt8 = 57, Fs2: UInt8 = 42, C2: UInt8 = 36, E2: UInt8 = 40, F4: UInt8 = 65,
               G5: UInt8 = 79, Ds4: UInt8 = 63, Cs2: UInt8 = 37, Cs3: UInt8 = 49, Ds2: UInt8 = 39

    /// Slow alternating pulls, as the loud strokes of the group take (one every 0.465 s).
    static func pulls(_ note: UInt8, count: Int = 10, gap: Double = 0.465, drum: Int = 0) -> [SpikeStroke] {
        (0..<count).map { SpikeStroke(time: 0.3 + Double($0) * gap, drum: drum, note: note, accent: $0 % 2 == 1 ? 0.8 : 0.95) }
    }

    /// A carol-like accompaniment at 110 bpm in eighths, two bars, twice: X . X x X . X x | X . X x X x X .
    static func groove(_ note: UInt8, drum: Int = 0, bpm: Double = 110) -> [SpikeStroke] {
        let bar = Array("X.XxX.XxX.XxXxX.")
        let eighth = 60.0 / bpm / 2.0
        var strokes: [SpikeStroke] = []
        for rep in 0..<2 {
            for (i, c) in bar.enumerated() where c != "." {
                strokes.append(SpikeStroke(time: 0.3 + Double(rep * 16 + i) * eighth, drum: drum, note: note,
                                           accent: c == "X" ? 0.95 : 0.6))
            }
        }
        return strokes
    }

    /// Sixteenths at 120 bpm (125 ms), accents on the beats, two bars.
    static func fast(_ note: UInt8, drum: Int = 0, bpm: Double = 120) -> [SpikeStroke] {
        let sixteenth = 60.0 / bpm / 4.0
        return (0..<32).map { i in
            SpikeStroke(time: 0.3 + Double(i) * sixteenth, drum: drum, note: note,
                        accent: i % 4 == 0 ? 1.0 : (i % 2 == 1 ? 0.55 : 0.75))
        }
    }

    /// Held notes of different lengths (for Key Up = Stop).
    static func held(_ note: UInt8) -> [SpikeStroke] {
        var strokes: [SpikeStroke] = []
        var t = 0.3
        for length in [0.08, 0.16, 0.08, 0.3, 0.08, 0.08, 0.5, 0.16] {
            strokes.append(SpikeStroke(time: t, drum: 0, note: note, accent: 0.9, hold: length))
            t += max(0.25, length + 0.15)
        }
        return strokes
    }

    // MARK: - The spike's programs (fanfrnoch_spike.cpp:432-506), by engine program index

    static let brummtopf: [String: Float] = ["attack": 24, "length": 80, "release": Float(60) / 700, "pot": 540,
                                             "potq": 4, "potlevel": 6, "rub": -10, "wobble": 12, "drift": 0, "drop": 0.25]
    static let zambomba: [String: Float] = ["attack": 31, "length": 100, "release": Float(60) / 440, "stick": 0.80,
                                            "skin": 306, "skinlevel": -12, "jump": 20, "jumpratio": 1.40, "rub": -14,
                                            "drift": 0, "drop": 0.3]
    static let cuica: [String: Float] = ["attack": 20, "length": 90, "release": 0.1, "stick": 0.73, "rub": -20,
                                         "wobble": 8, "alternate": 6, "alttune": 30, "drop": 0.3, "drift": 0, "scrape": 5]
    static let cuicaWhoop = cuica.merging(["scoop": 6.6, "scooptime": 80, "length": 30, "release": 0.3,
                                           "alternate": 0, "alttune": 0]) { $1 }

    /// The programs' values as the spike's program functions set them, in engine units; the
    /// engine's own table (Params.cpp) must give the same sounds.
    static let spikePrograms: [Int: [String: Float]] = [
        0: [:],
        1: ["length": 150, "alternate": 3],
        2: brummtopf,
        3: zambomba,
        4: zambomba.merging(["pot": 250, "potq": 1.5, "potlevel": 6, "release": Float(60) / 190]) { $1 },
        5: ["attack": 170, "length": 150, "release": 1.5, "pot": 470, "potq": 5, "potlevel": 12, "rub": -7,
            "wobble": 8, "drift": -0.5],
        6: cuica,
        7: cuicaWhoop,
        8: ["attack": 70, "length": 200, "release": Float(60) / 110, "split": 70, "wobble": 45, "rub": -5,
            "skin": 100, "skinq": 6, "skinlevel": -3, "drift": 0],
        9: ["creak": 100, "creakrate": 14, "creakring": 40, "skin": 300, "length": 900, "attack": 30,
            "release": 0.15, "rub": -14, "wobble": 0, "drift": 0, "scrape": 0],
        10: ["attack": 5, "length": 0, "release": 0.5, "scrape": 60, "split": 25, "stick": 0.75, "rub": -20,
             "drift": 0, "alternate": 0],
        11: ["attack": 80, "length": 500, "release": 0.4, "rub": -6, "wobble": 30, "stick": 0.9, "drift": -1.0,
             "pot": 250, "potq": 2, "potlevel": 3],
    ]

    // MARK: - The spike's renders (fanfrnoch_spike.cpp:510-664)

    /// Every render of the spike but 13b (its polyphonic restarts, which the design turned down:
    /// one drum is one head), in the spike's order.
    static let renders: [SpikeRender] = {
        func knobs(_ k: [String: Float]) -> SpikeDrum { SpikeDrum(knobs: k) }
        var r: [SpikeRender] = [
            SpikeRender("01a_fanfrnoch_default_pulls", pulls(B2)),
            SpikeRender("01b_fanfrnoch_default_groove", groove(B2)),
        ]
        var group = pulls(B2, count: 10, gap: 0.93, drum: 0)
        for i in 0..<10 {
            group.append(SpikeStroke(time: 0.3 + 0.465 + Double(i) * 0.93, drum: 1, note: A3 - 2, accent: 0.6))
            group.append(SpikeStroke(time: 0.3 + 0.465 + 0.23 + Double(i) * 0.93, drum: 2, note: A3 + 3, accent: 0.5))
        }
        r.append(SpikeRender("01c_fanfrnoch_group_like_the_recording",
                             [SpikeDrum(), SpikeDrum(program: 1), SpikeDrum(program: 1)], group))
        for length: Float in [100, 230, 450] {
            r.append(SpikeRender("02_length_\(Int(length))ms", knobs(["length": length]), groove(B2)))
        }
        r.append(SpikeRender("02d_keyup_stop_note_lengths", knobs(["length": 600, "keyup": 1]), held(B2)))
        r.append(SpikeRender("03a_rough_smooth_rub-20_wobble5", knobs(["rub": -20, "wobble": 5]), pulls(B2)))
        r.append(SpikeRender("03b_rough_default_rub-10_wobble20", knobs(["rub": -10, "wobble": 20]), pulls(B2)))
        r.append(SpikeRender("03c_rough_rough_rub-6_wobble40", knobs(["rub": -6, "wobble": 40]), pulls(B2)))
        for (stick, name) in [(Float(0.80), "0.80"), (0.88, "0.88"), (0.93, "0.93")] {
            r.append(SpikeRender("04_stick_\(name)", knobs(["stick": stick]), pulls(B2)))
        }
        r.append(SpikeRender("04d_stick_no_darkening_in_tail", knobs(["stickvel": 0]), pulls(B2)))
        r.append(SpikeRender("04e_stick_strong_darkening_in_tail", knobs(["stickvel": 0.05]), pulls(B2)))
        r.append(SpikeRender("05_pot_500Hz_plus6dB", knobs(["potlevel": 6, "pot": 500]), pulls(B2)))
        r.append(SpikeRender("06_drift_0", knobs(["drift": 0]), pulls(B2)))
        r.append(SpikeRender("07_attack_15ms", knobs(["attack": 15]), groove(B2)))
        r.append(SpikeRender("08a_release_600dBps", knobs(["release": 0.1]), groove(B2)))
        r.append(SpikeRender("08b_damp_50", knobs(["damp": 50]), groove(B2)))
        for (alternate, tune, name) in [(Float(0), Float(0), "09a_hands_alt0_tune0"), (2, 10, "09b_hands_alt2_tune10"),
                                        (6, 10, "09c_hands_alt6_tune10")] {
            r.append(SpikeRender(name, knobs(["alternate": alternate, "alttune": tune, "length": 80, "release": 0.12]),
                                 fast(B2)))
        }
        for scrape: Float in [0, 10, 40] {
            r.append(SpikeRender("10_scrape_\(Int(scrape))", knobs(["scrape": scrape]), pulls(B2)))
        }
        r.append(SpikeRender("11a_creak_40", knobs(["creak": 40, "skin": 300]), pulls(B2)))
        r.append(SpikeRender("11b_split_50", knobs(["split": 50]), pulls(B2)))
        let whoops = (0..<6).map { SpikeStroke(time: 0.3 + Double($0) * 0.7, drum: 0, note: F4, accent: 0.9) }
        r.append(SpikeRender("12a_cuica_whoop_soft_2.5st_120ms",
                             SpikeDrum(program: 7, knobs: ["scoop": 2.5, "scooptime": 120]), whoops))
        r.append(SpikeRender("12b_cuica_whoop_6.6st_80ms", SpikeDrum(program: 7),
                             whoops.map { SpikeStroke(time: $0.time, drum: 0, note: G5, accent: $0.accent) }))
        let pattern = Array("LHLLHLHLLHLLHLHH")
        let sx = 60.0 / 100.0 / 4.0
        var samba: [SpikeStroke] = []
        for rep in 0..<3 {
            for (i, c) in pattern.enumerated() {
                samba.append(SpikeStroke(time: 0.3 + Double(rep * 16 + i) * sx, drum: 0, note: c == "L" ? F4 : G5,
                                         accent: i % 4 == 0 ? 1.0 : 0.7))
            }
        }
        r.append(SpikeRender("12c_cuica_samba", SpikeDrum(program: 6), samba))
        r.append(SpikeRender("13a_one_drum_mono", knobs(["length": 80, "release": 0.2]), fast(B2)))
        for (note, hz) in [(Ds4 - 1, 294), (Cs2 - 2, 62)] {
            for track: Float in [0, 100] {
                r.append(SpikeRender("14_range_\(hz)Hz_track\(Int(track))", knobs(["potlevel": 6, "track": track]),
                                     pulls(note)))
            }
        }
        r.append(SpikeRender("P01_brummtopf_two_registers", SpikeDrum(program: 2),
                             groove(Cs3).map { SpikeStroke(time: $0.time, drum: 0, note: $0.accent < 0.9 ? Ds2 : Cs3,
                                                           accent: $0.accent) }))
        r.append(SpikeRender("P02_zambomba", SpikeDrum(program: 3), groove(A3)))
        r.append(SpikeRender("P03_zambomba_grave", SpikeDrum(program: 4), groove(Fs2)))
        r.append(SpikeRender("P04_putipu", SpikeDrum(program: 5),
                             (0..<6).map { SpikeStroke(time: 0.3 + Double($0), drum: 0, note: $0 % 2 == 1 ? E2 : C2, accent: 0.9) }))
        r.append(SpikeRender("P05_furruco", SpikeDrum(program: 8), pulls(Cs2, count: 8, gap: 0.6)))
        r.append(SpikeRender("P06_creak", SpikeDrum(program: 9),
                             [SpikeStroke(time: 0.3, drum: 0, note: B2, accent: 0.9),
                              SpikeStroke(time: 1.6, drum: 0, note: B2, accent: 0.7),
                              SpikeStroke(time: 2.9, drum: 0, note: B2, accent: 1.0)]))
        r.append(SpikeRender("P07_flick", SpikeDrum(program: 10),
                             (0..<5).map { SpikeStroke(time: 0.3 + Double($0) * 0.8, drum: 0, note: Ds4, accent: 0.9) }))
        r.append(SpikeRender("P08_buhai_unmeasured_guess", SpikeDrum(program: 11), pulls(Cs2 - 1, count: 8, gap: 0.75)))
        var kit = groove(B2, drum: 0, bpm: 110)
        let e8 = 60.0 / 110.0 / 2.0
        for i in stride(from: 0, to: 32, by: 4) {
            kit.append(SpikeStroke(time: 0.3 + Double(i + 2) * e8, drum: 1, note: A3 + 2, accent: 0.6))
        }
        for i in stride(from: 0, to: 32, by: 8) {
            kit.append(SpikeStroke(time: 0.3 + Double(i + 7) * e8, drum: 2, note: F4, accent: 0.7))
        }
        r.append(SpikeRender("P09_kit_fanfrnoch_low_high_cuica",
                             [SpikeDrum(), SpikeDrum(knobs: ["length": 120, "release": 0.15]), SpikeDrum(program: 6)], kit))
        return r
    }()

    static func render(named name: String) -> SpikeRender {
        guard let render = renders.first(where: { $0.name == name }) else { preconditionFailure("no render \(name)") }
        return render
    }

    // MARK: - Events and the reference

    /// The render's strokes and releases at whole frames of `rate`, in time order (in the
    /// render's order at one frame).
    static func events(_ render: SpikeRender, rate: Double) -> [ScoreEvent] {
        func frame(_ t: Double) -> Int { Int((t * rate).rounded()) }
        var events: [ScoreEvent] = []
        for s in render.strokes {
            events.append(ScoreEvent(frame: frame(s.time), drum: s.drum, note: s.note, velocity: velocity(s.accent),
                                     noteOff: false))
            if let hold = s.hold {
                events.append(ScoreEvent(frame: frame(s.time + hold), drum: s.drum, note: s.note, velocity: 0, noteOff: true))
            }
        }
        return events.enumerated().sorted { ($0.element.frame, $0.offset) < ($1.element.frame, $1.offset) }.map(\.element)
    }

    static func frames(_ render: SpikeRender, rate: Double) -> Int { Int(render.seconds * rate) }

    /// A render as MIDI events, in seconds, for a `Synth`: one drum on the keyboard, several on
    /// pads 1, 2, ... (a stroke on drum n is a note-on of 36 + n); a key let go is a note-off.
    static func midiEvents(_ render: SpikeRender) -> [GrooveEvent] {
        var events: [(GrooveEvent, Int)] = []
        for (i, s) in render.strokes.enumerated() {
            let note = render.isPads ? UInt8(36 + s.drum) : s.note
            events.append((GrooveEvent(s.time, 0x90, note, velocity(s.accent)), i))
            if let hold = s.hold { events.append((GrooveEvent(s.time + hold, 0x80, note, 0), i)) }
        }
        return events.sorted { ($0.0.time, $0.1) < ($1.0.time, $1.1) }.map(\.0)
    }

    /// Puts a render's drums into `synth`: the keyboard set, or pads 1, 2, ... each in a group of
    /// its own at its drum's pitch. The mode is the caller's.
    static func setUp(_ render: SpikeRender, in synth: Synth) {
        for (n, drum) in render.drums.enumerated() {
            let set: SoundSet = render.isPads ? .pad(n) : .keyboard
            synth.loadProgram(Int(drum.program), into: set)
            for (id, value) in drum.knobs { synth.setValue(value, of: Parameters.named(id)!, in: set) }
            if render.isPads {
                synth.setPadNote(Int(render.note(ofDrum: n)), pad: n)
                synth.setPadGroup(n + 1, pad: n)
            }
        }
    }

    /// The knobs the prototype has, by engine identifier.
    private static let prototypeKnobs: [String] = [
        "attack", "length", "release", "damp", "keyup", "velsens", "vary", "alternate", "alttune", "scoop", "scooptime",
        "drift", "drop", "wobble", "jump", "jumpratio", "velpitch", "stick", "stickvel", "split", "creak", "creakrate",
        "creakring", "pot", "potq", "potlevel", "skin", "skinq", "skinlevel", "track", "rub", "scrape", "shimmer",
    ]

    /// Engine identifiers with no counterpart in the prototype.
    private static let notInPrototype: Set<String> = ["volume", "pan", "tune", "octave", "bendup", "benddown", "drum",
                                                      "lfostart"]

    /// The prototype's parameters for a sound given as engine knobs: the engine's defaults with
    /// `overrides` applied (identifiers and plain engine values: %, dB, Hz, ms, choice index),
    /// each value as the engine holds it (a knob stores its position, and a position gives the
    /// value back to within a rounding). Percent knobs become fractions, and a level at the bottom
    /// of its knob (-40 dB) the prototype's off (-200 dB).
    static func referenceParams(_ overrides: [String: Float]) -> FanfrnochRefParams {
        for key in overrides.keys where !prototypeKnobs.contains(key) {
            precondition(notInPrototype.contains(key) || key.hasPrefix("lfo") || key.hasPrefix("vel"),
                         "Unknown engine identifier '\(key)'")
        }
        var p = FanfrnochRefParams()
        func level(_ v: Float) -> Float { v <= -40 ? -200 : v }
        for key in prototypeKnobs {
            let knob = Parameters.named(key)!
            let v = knob.plain(knob.normalised(overrides[key] ?? knob.defaultValue))
            switch key {
            case "attack": p.attack = v
            case "length": p.length = v
            case "release": p.release = v
            case "damp": p.damp = v / 100
            case "keyup": p.keyupStop = v != 0 ? 1 : 0
            case "velsens": p.velsens = v / 100
            case "vary": p.vary = v / 100
            case "alternate": p.alternate = v
            case "alttune": p.alttune = v
            case "scoop": p.scoop = v
            case "scooptime": p.scooptime = v
            case "drift": p.drift = v
            case "drop": p.drop = v
            case "wobble": p.wobble = v
            case "jump": p.jump = v / 100
            case "jumpratio": p.jumpratio = v
            case "velpitch": p.veltune = v
            case "stick": p.stick = v
            case "stickvel": p.stickvel = v
            case "split": p.split = v / 100
            case "creak": p.creak = v / 100
            case "creakrate": p.creakrate = v
            case "creakring": p.creakring = v
            case "pot": p.pot = v
            case "potq": p.potq = v
            case "potlevel": p.potlevel = level(v)
            case "skin": p.skin = v
            case "skinq": p.skinq = v
            case "skinlevel": p.skinlevel = level(v)
            case "track": p.track = v / 100
            case "rub": p.rub = level(v)
            case "scrape": p.scrape = v / 100
            case "shimmer": p.shimmer = v
            default: preconditionFailure("no prototype parameter for \(key)")
            }
        }
        return p
    }

    /// Renders `events` through the reference at `rate`. With `oversampled` the voices run at
    /// twice `rate` and the engine's decimator brings them back. `paramsOf` picks a stroke's entry
    /// of `params` (by default its drum's).
    static func referenceRender(_ events: [ScoreEvent], frames: Int, params: [FanfrnochRefParams], drumCount: Int,
                                rate: Double, oversampled: Bool,
                                paramsOf: (ScoreEvent) -> Int = { $0.drum }) -> [Float] {
        let refEvents = events.map { e in
            FanfrnochRefEvent(time: Double(e.frame) / rate, drum: Int32(e.drum), hz: noteHz(e.note),
                              velocity: Float(e.velocity) / 127, params: Int32(paramsOf(e)), noteOff: e.noteOff ? 1 : 0)
        }
        var out = [Float](repeating: 0, count: frames)
        fanfrnoch_ref_render(refEvents, Int32(refEvents.count), params, Int32(params.count), Int32(drumCount),
                             oversampled ? 2 * rate : rate, oversampled ? 1 : 0, &out, Int32(frames))
        return out
    }
}
