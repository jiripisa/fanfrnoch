import FanfrnochReference

/// One note-on (or, with `chokeOnly`, one stop of the ringing reed) at a whole frame.
struct ScoreHit {
    let frame: Int
    let note: UInt8
    let velocity: UInt8
    let chokeOnly: Bool
}

struct Score {
    var hits: [ScoreHit]
    var frames: Int
}

/// The prototype's scores (`fanfrnoch_spike.cpp`, `phrase()`) in frames, and a way to render
/// them through the prototype itself. Shared by the tests that compare the engine with it.
enum PrototypeScores {
    static let sampleRate = 96_000.0

    private static let accent8: [Float] = [1.0, 0.5, 0.75, 0.5, 0.9, 0.5, 0.75, 0.6]
    private static let accent16: [Float] = [1, 0.45, 0.6, 0.45, 0.85, 0.45, 0.6, 0.5,
                                            0.95, 0.45, 0.6, 0.45, 0.85, 0.5, 0.7, 0.55]

    /// Seconds: the lead-in, two bars at 112 BPM, and the tail.
    static let phraseLength: Double = 2.7 + 2 * 4 * 60.0 / 112.0 + 1.5

    static func velocity(_ accent: Float) -> UInt8 {
        UInt8((accent * 127).rounded())
    }

    private static func frame(_ seconds: Double) -> Int {
        Int((seconds * sampleRate).rounded(.up))
    }

    /// One hit, then a groove from 2.5 s later: two bars of 8ths (`sub` 2) or 16ths (`sub` 4).
    /// `chokeAhead` > 0 stops the reed that many seconds before each next stroke.
    static func phrase(note: UInt8, sub: Int = 2, chokeAhead: Double = 0) -> Score {
        let t0 = 0.2
        let first = Int((t0 * sampleRate).rounded())
        var hits = [ScoreHit(frame: first, note: note, velocity: velocity(0.85), chokeOnly: false)]
        let step = 60.0 / 112.0 / Double(sub)
        let g0 = t0 + 2.5
        for i in 0..<(8 * sub) {
            let t = g0 + Double(i) * step
            if chokeAhead > 0 && i > 0 {
                hits.append(ScoreHit(frame: frame(t - chokeAhead), note: note, velocity: 0, chokeOnly: true))
            }
            let accent = sub == 4 ? accent16[i % 16] : accent8[i % 8]
            hits.append(ScoreHit(frame: frame(t), note: note, velocity: velocity(accent), chokeOnly: false))
        }
        return Score(hits: hits, frames: Int((phraseLength * sampleRate).rounded(.down)))
    }

    /// Engine identifiers with no counterpart in the prototype.
    private static let notInPrototype: Set<String> = ["keyup", "volume", "pan", "tune", "octave", "bendvowel"]

    /// The prototype's defaults with `overrides` applied. Keys are engine identifiers and values
    /// are plain engine values (%, dB, Hz, ms, choice index); percent knobs become fractions.
    static func referenceParams(_ overrides: [String: Float]) -> FanfrnochRefParams {
        var p = FanfrnochRefParams()
        fanfrnoch_ref_default_params(&p)
        for (key, v) in overrides {
            switch key {
            case "ring": p.ring = v
            case "edge": p.edge = v
            case "offset": p.offset = v
            case "body": p.bodyDb = v
            case "buzz": p.buzz = v / 100
            case "clang": p.clang = v / 100
            case "velsens": p.velsens = v / 100
            case "stroke": p.stroke = Int32(v)
            case "damp": p.damp = v
            case "vary": p.vary = v / 100
            case "vowel": p.vowel = v
            case "sweep": p.sweep = v
            case "sweeptime": p.sweeptime = v
            case "curve": p.curve = Int32(v)
            case "reso": p.reso = v
            case "throat": p.throatDb = v
            case "throattune": p.throattune = v
            case "open": p.open = v / 100
            case "close": p.close = v / 100
            case "breath": p.breath = v / 100
            case "puff": p.puff = v / 100
            case "pufftime": p.pufftime = v
            case "air": p.air = v / 100
            case "levelOnly": p.levelOnlyVelocity = v != 0 ? 1 : 0
            default:
                precondition(notInPrototype.contains(key) || key.hasPrefix("lfo"),
                             "Unknown engine identifier '\(key)'")
            }
        }
        return p
    }

    /// Renders `score` through the prototype. `paramOf` picks the entry of `params` for a hit.
    static func referenceRender(_ score: Score, params: [FanfrnochRefParams],
                                paramOf: (ScoreHit) -> Int) -> [Float] {
        let events = score.hits.map { hit in
            FanfrnochRefEvent(time: Double(hit.frame) / sampleRate, note: Int32(hit.note),
                           velocity: Float(hit.velocity) / 127, params: Int32(paramOf(hit)),
                           chokeOnly: hit.chokeOnly ? 1 : 0)
        }
        var out = [Float](repeating: 0, count: score.frames)
        fanfrnoch_ref_render(events, Int32(events.count), params, Int32(params.count),
                          &out, Int32(score.frames))
        return out
    }
}
