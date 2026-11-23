import Foundation
import Testing
import FanfrnochDSP
import FanfrnochReference
@testable import FanfrnochCore

/// The engine against the listening prototype the author approved: the engine renders the
/// prototype's scores, in keyboard mode and in pad mode, and must give the prototype's samples,
/// up to one output scale. At 96 kHz the voices run at the host's rate; at 48 kHz they run at
/// twice it, and the reference goes through the same decimator.
@Suite("Prototype equivalence")
struct PrototypeEquivalenceTests: EngineHarness {

    /// The engine's output scale against the prototype's raw sum: kLevel times Volume -12 dB.
    static let expectedScale = level * 0.251188643150958

    /// The spike's renders the engine is compared with at 96 kHz. Left out as duplicates of 01a
    /// (the pulls with the defaults): 03b, 04_stick_0.88 and 10_scrape_10; of 01b (the groove
    /// with the defaults): 02_length_230ms.
    static let duplicates: Set<String> = ["03b_rough_default_rub-10_wobble20", "04_stick_0.88", "10_scrape_10",
                                          "02_length_230ms"]
    static let renders = PrototypeScores.renders.filter { !duplicates.contains($0.name) }

    /// At 48 kHz, through the decimator: one of each kind of score.
    static let oversampledRenders = ["01a_fanfrnoch_default_pulls", "01c_fanfrnoch_group_like_the_recording",
                                     "02d_keyup_stop_note_lengths", "11a_creak_40", "12c_cuica_samba", "P07_flick",
                                     "P09_kit_fanfrnoch_low_high_cuica"].map(PrototypeScores.render(named:))

    // MARK: - Rendering and comparing

    /// Renders `events` in `mode` at `rate`, in blocks of 128 frames, each block's events given
    /// with `fanfrnoch_midi` before it is processed: a stroke is a note-on of `noteOf(event)` and
    /// a release a note-off.
    func engineRender(_ events: [ScoreEvent], frames: Int, rate: Double, mode: Int32,
                      noteOf: (ScoreEvent) -> UInt8, set: (OpaquePointer) -> Void) -> (left: [Float], right: [Float]) {
        let engine = fanfrnoch_create()!
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_prepare(engine, rate)
        fanfrnoch_reset(engine)
        fanfrnoch_set_mode(engine, mode)
        set(engine)

        var left = [Float](repeating: 0, count: frames)
        var right = [Float](repeating: 0, count: frames)
        var next = 0
        var start = 0
        while start < frames {
            let count = min(128, frames - start)
            while next < events.count && events[next].frame < start + count {
                let e = events[next]
                let offset = Int32(e.frame - start), note = Int32(noteOf(e))
                if e.noteOff { fanfrnoch_midi(engine, 0x80, note, 0, offset) }
                else { fanfrnoch_midi(engine, 0x90, note, Int32(e.velocity), offset) }
                next += 1
            }
            left.withUnsafeMutableBufferPointer { l in
                right.withUnsafeMutableBufferPointer { r in
                    fanfrnoch_process(engine, l.baseAddress! + start, r.baseAddress! + start, Int32(count))
                }
            }
            start += count
        }
        return (left, right)
    }

    /// The least-squares scale of `reference` onto `engine` (<e,r>/<r,r>), and what is left of
    /// the engine's output after it, in dB re the scaled reference.
    func matches(_ engine: [Float], _ reference: [Float]) -> (scale: Double, residualDb: Double) {
        precondition(engine.count == reference.count)
        var er = 0.0, rr = 0.0
        for i in engine.indices { er += Double(engine[i]) * Double(reference[i]); rr += Double(reference[i]) * Double(reference[i]) }
        let scale = er / rr
        var residual = 0.0, signal = 0.0
        for i in engine.indices {
            let s = scale * Double(reference[i])
            residual += (Double(engine[i]) - s) * (Double(engine[i]) - s)
            signal += s * s
        }
        return (scale, 10 * log10(residual / signal))
    }

    /// Puts a drum's sound into `set`: its program, its knobs, and Volume -12 dB, which keeps the
    /// peaks under the limiter's 0.6.
    func load(_ drum: SpikeDrum, into set: Int32, of engine: OpaquePointer) {
        fanfrnoch_set_program(engine, set, drum.program)
        setKnobs(engine, drum.knobs, set: set)
        setKnobs(engine, ["volume": -12], set: set)
    }

    /// A spike render through the engine and through the reference at `rate`. One drum plays on
    /// the keyboard (Drum One); several play pads 1, 2, ... in groups 1, 2, ..., each at its drum's
    /// pitch.
    func compare(_ render: SpikeRender, rate: Double) -> (out: (left: [Float], right: [Float]), scale: Double, residualDb: Double) {
        let events = PrototypeScores.events(render, rate: rate)
        let frames = PrototypeScores.frames(render, rate: rate)
        let reference = PrototypeScores.referenceRender(events, frames: frames,
                                                        params: render.drums.map { PrototypeScores.referenceParams($0.reference) },
                                                        drumCount: render.drums.count, rate: rate, oversampled: rate < 88_200)
        let out: (left: [Float], right: [Float])
        if render.isPads {
            out = engineRender(events, frames: frames, rate: rate, mode: Int32(FANFRNOCH_MODE_PADS),
                               noteOf: { UInt8(FANFRNOCH_FIRST_PAD_NOTE + $0.drum) }) { engine in
                for (pad, drum) in render.drums.enumerated() {
                    load(drum, into: Int32(pad + 1), of: engine)
                    fanfrnoch_set_pad_note(engine, Int32(pad), Int32(render.note(ofDrum: pad)))
                    fanfrnoch_set_pad_group(engine, Int32(pad), Int32(pad + 1))
                }
            }
        } else {
            out = engineRender(events, frames: frames, rate: rate, mode: Int32(FANFRNOCH_MODE_KEYBOARD),
                               noteOf: { $0.note }) { engine in load(render.drums[0], into: Self.keyboard, of: engine) }
        }
        let m = matches(out.left, reference)
        return (out, m.scale, m.residualDb)
    }

    func expectEquivalent(_ render: SpikeRender, rate: Double) {
        let c = compare(render, rate: rate)
        #expect(c.out.left == c.out.right)                                   // Pan at the centre
        let peak = c.out.left.map(abs).max() ?? 0
        #expect(peak < 0.6, "\(render.name): peak \(peak)")                  // the limiter stays out of it
        #expect(c.residualDb < -60, "\(render.name) at \(Int(rate)) Hz: residual \(c.residualDb) dB")
        #expect(abs(c.scale - Self.expectedScale) / Self.expectedScale < 1e-3, "\(render.name): scale \(c.scale)")
        print(String(format: "equivalence %@ at %d Hz: residual %.1f dB", render.name, Int(rate), c.residualDb))
    }

    // MARK: - Tests

    @Test("The engine plays the approved prototype's renders at 96 kHz", arguments: PrototypeEquivalenceTests.renders)
    func at96k(_ render: SpikeRender) {
        expectEquivalent(render, rate: 96_000)
    }

    @Test("At 48 kHz the oversampled engine plays them through the decimator",
          arguments: PrototypeEquivalenceTests.oversampledRenders)
    func at48k(_ render: SpikeRender) {
        expectEquivalent(render, rate: 48_000)
    }

    // The default kit in pad mode: each group of pads is one drum and each pad with Group Off is
    // one, every hit with its pad's own set (read back from the engine, Volume -12 dB) at its
    // pad's note.
    @Test("Pad mode plays the default kit's groups as drums")
    func defaultKitGroups() {
        let rate = 96_000.0
        let probe = fanfrnoch_create()!
        defer { fanfrnoch_destroy(probe) }
        let pads = 0..<Int(FANFRNOCH_NUM_PADS)
        let groups = pads.map { Int(fanfrnoch_pad_group(probe, Int32($0))) }
        let drumOf = pads.map { pad in groups[pad] != 0 ? groups[pad] - 1 : Int(FANFRNOCH_NUM_GROUPS) + pad }
        let params = pads.map { pad -> FanfrnochRefParams in
            var knobs: [String: Float] = [:]
            for p in Parameters.all where Controllers.standard(for: p) != nil {
                knobs[p.identifier] = fanfrnoch_get_plain(probe, Int32(pad + 1), Int32(p.index))
            }
            return PrototypeScores.referenceParams(knobs)
        }
        let events = Grooves.defaultKitHits.map { hit in
            ScoreEvent(frame: Self.frames(hit.time, at: rate), drum: drumOf[hit.pad],
                       note: UInt8(fanfrnoch_pad_note(probe, Int32(hit.pad))), velocity: Grooves.velocity(hit.accent),
                       noteOff: false, pad: hit.pad)
        }
        let frames = Self.frames(Grooves.defaultKitLength, at: rate)
        let reference = PrototypeScores.referenceRender(events, frames: frames, params: params,
                                                        drumCount: Int(FANFRNOCH_NUM_GROUPS + FANFRNOCH_NUM_PADS),
                                                        rate: rate, oversampled: false, paramsOf: { $0.pad })
        let out = engineRender(events, frames: frames, rate: rate, mode: Int32(FANFRNOCH_MODE_PADS),
                               noteOf: { UInt8(FANFRNOCH_FIRST_PAD_NOTE + $0.pad) }) { engine in
            for pad in pads { setKnobs(engine, ["volume": -12], set: Int32(pad + 1)) }
        }
        let peak = out.left.map(abs).max() ?? 0
        #expect(peak < 0.6, "peak \(peak)")
        let m = matches(out.left, reference)
        #expect(m.residualDb < -60, "residual \(m.residualDb) dB")
        #expect(abs(m.scale - Self.expectedScale) / Self.expectedScale < 1e-3, "scale \(m.scale)")
        print(String(format: "equivalence default kit groups at 96000 Hz: residual %.1f dB", m.residualDb))
    }

    // Drum = Many: every note is a drum of its own, which its next stroke continues; the drums
    // are seeded in the order of their first strokes.
    @Test("Drum Many makes every note a drum of its own")
    func drumMany() {
        let rate = 96_000.0
        let low = PrototypeScores.groove(PrototypeScores.B2)
        let high = PrototypeScores.groove(PrototypeScores.B2 + 7).map {
            SpikeStroke(time: $0.time + 0.136, drum: 1, note: $0.note, accent: $0.accent * 0.7)
        }
        let render = SpikeRender("drum many", [SpikeDrum(), SpikeDrum()], low + high)
        let events = PrototypeScores.events(render, rate: rate)
        let frames = PrototypeScores.frames(render, rate: rate)
        let reference = PrototypeScores.referenceRender(events, frames: frames,
                                                        params: [PrototypeScores.referenceParams([:])] ,
                                                        drumCount: 2, rate: rate, oversampled: false, paramsOf: { _ in 0 })
        let out = engineRender(events, frames: frames, rate: rate, mode: Int32(FANFRNOCH_MODE_KEYBOARD),
                               noteOf: { $0.note }) { engine in
            setKnobs(engine, ["volume": -12, "drum": 1])
        }
        let m = matches(out.left, reference)
        #expect(m.residualDb < -60, "residual \(m.residualDb) dB")
        #expect(abs(m.scale - Self.expectedScale) / Self.expectedScale < 1e-3, "scale \(m.scale)")
        print(String(format: "equivalence drum many at 96000 Hz: residual %.1f dB", m.residualDb))
    }
}
