import Accelerate
import Foundation
import Testing
import FanfrnochDSP
import FanfrnochReference
@testable import FanfrnochCore

/// What the sound engine promises beyond matching the prototype: its level, how strokes on a drum
/// run into each other and stop, how it keeps its pitch and its sound at every sample rate, how
/// it shares its voices, and how its C interface copes with what callers hand it.
@Suite("Engine")
struct EngineTests: EngineHarness {

    private static let B2: Int32 = 47

    @Test("The default stroke at full velocity peaks around -6 dBFS")
    func level() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, Self.B2, 127, 0)
        let peak = render(engine, seconds: 2).map(abs).max() ?? 0
        #expect(peak > 0.42 && peak < 0.58, "peak \(peak)")
    }

    // MARK: - Drums

    // Drum One: every note is the one drum. A second stroke while the first still sounds goes on
    // from where the head is: one voice, and the level does not fall back to silence to rise again.
    @Test("A stroke on a sounding drum continues its voice and its envelope")
    func strokeContinuesTheDrum() {
        let engine = makeEngine(Self.plain)
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, Self.B2, 110, 0)
        let first = render(engine, seconds: 0.15)
        fanfrnoch_midi(engine, 0x90, Self.B2 + 5, 110, 0)
        let second = render(engine, seconds: 0.15)
        #expect(fanfrnoch_sounding_voices(engine) == 1)
        let before = rms(first.suffix(Self.frames(0.01))), after = rms(second.prefix(Self.frames(0.01)))
        #expect(20 * log10(after / before) > -3, "the level fell from \(before) to \(after) at the second stroke")

        // A fresh voice would start from silence: the first 5 ms of a stroke on a silent drum.
        let fresh = makeEngine(Self.plain)
        defer { fanfrnoch_destroy(fresh) }
        fanfrnoch_midi(fresh, 0x90, Self.B2 + 5, 110, 0)
        let start = rms(render(fresh, seconds: 0.01))
        #expect(20 * log10(start / before) < -10)
    }

    @Test("Drum Many makes a drum of every note; Drum One makes one of them all")
    func drumOneAndMany() {
        for (drum, voices) in [(Float(0), Int32(1)), (1, 3)] {
            let engine = makeEngine(Self.plain.merging(["drum": drum]) { $1 })
            defer { fanfrnoch_destroy(engine) }
            for note: Int32 in [47, 52, 47, 59, 52] {
                fanfrnoch_midi(engine, 0x90, note, 100, 0)
                _ = render(engine, seconds: 0.05)
            }
            #expect(fanfrnoch_sounding_voices(engine) == voices, "Drum \(drum)")
        }
    }

    @Test("Key Up = Stop ends the rubbing at note-off; Ignore lets the stroke run its Length")
    func keyUp() {
        func afterRelease(_ keyUp: Float) -> Double {
            let engine = makeEngine(Self.plain.merging(["keyup": keyUp, "length": 2000]) { $1 })
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, Self.B2, 110, 0)
            _ = render(engine, seconds: 0.3)
            fanfrnoch_midi(engine, 0x80, Self.B2, 0, 0)
            _ = render(engine, seconds: 0.3)              // Release 0.3 s: 60 dB down
            return rms(render(engine, seconds: 0.1))
        }
        let ignore = afterRelease(0), stop = afterRelease(1)
        #expect(ignore > 0.01)
        #expect(20 * log10(stop / ignore) < -50, "stopped \(stop), rubbing \(ignore)")
    }

    // With Drum One the hand belongs to the last stroke: letting go of an earlier key leaves it.
    @Test("Only the note-off of the stroke's own key stops the hand")
    func noteOffOfAnotherKey() {
        func level(releasing note: Int32) -> Double {
            let engine = makeEngine(Self.plain.merging(["keyup": 1, "length": 2000]) { $1 })
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, Self.B2, 110, 0)
            _ = render(engine, seconds: 0.2)
            fanfrnoch_midi(engine, 0x90, Self.B2 + 7, 110, 0)
            _ = render(engine, seconds: 0.2)
            fanfrnoch_midi(engine, 0x80, note, 0, 0)
            _ = render(engine, seconds: 0.4)
            return rms(render(engine, seconds: 0.1))
        }
        let earlier = level(releasing: Self.B2), own = level(releasing: Self.B2 + 7)
        #expect(earlier > 0.01)
        #expect(20 * log10(own / earlier) < -50)
    }

    @Test("All Sound Off and All Notes Off fade every voice out")
    func allOff() {
        for controller: Int32 in [120, 123] {
            let engine = makeEngine(Self.plain.merging(["drum": 1]) { $1 })
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, 47, 110, 0)
            fanfrnoch_midi(engine, 0x90, 54, 110, 0)
            _ = render(engine, seconds: 0.2)
            #expect(fanfrnoch_sounding_voices(engine) == 2)
            fanfrnoch_midi(engine, 0xB0, controller, 0, 0)
            _ = render(engine, seconds: 0.001)
            #expect(fanfrnoch_sounding_voices(engine) == 0, "CC \(controller)")
        }
    }

    // A voice fades 40 dB in 10 ms and leaves at -100 dB, 25 ms on; each voice's DC blocker
    // leaves with it, so nothing is left in the bus.
    @Test("After All Sound Off or All Notes Off the output is silent within 50 ms")
    func allOffFallsSilent() {
        for controller: Int32 in [120, 123] {
            let engine = makeEngine(["drum": 1])
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, 47, 110, 0)
            fanfrnoch_midi(engine, 0x90, 54, 110, 0)
            #expect((render(engine, seconds: 0.2).map(abs).max() ?? 0) > 0.05)
            fanfrnoch_midi(engine, 0xB0, controller, 0, 0)
            _ = render(engine, seconds: 0.05)
            #expect(render(engine, seconds: 0.1).allSatisfy { $0 == 0 }, "CC \(controller): still sounding 50 ms after it")
        }
    }

    // The voice retires once its ring-out is 100 dB down (and Release three times over): what
    // stops then is far below hearing, at full velocity and at the softest.
    @Test("A stroke ends without a step when its voice retires")
    func retireIsSilent() throws {
        for velocity: Int32 in [127, 1] {
            let engine = makeEngine(["velsens": 0])
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, Self.B2, velocity, 0)
            var y: [Float] = [], retired: Int?
            while y.count < Self.frames(4) {
                y += render(engine, frames: 128)
                if retired == nil && fanfrnoch_sounding_voices(engine) == 0 { retired = y.count }
            }
            let retire = try #require(retired, "the voice has not retired within 4 s")
            #expect(Double(retire) / Self.rate < 1.6, "retired after \(Double(retire) / Self.rate) s")
            let around = y[(retire - Self.frames(0.05))..<(retire + Self.frames(0.05))]
            let step = zip(around.dropFirst(), around).map { abs($0 - $1) }.max() ?? 0
            #expect(step == 0 || 20 * log10(step) < -90, "velocity \(velocity): a step of \(20 * log10(step)) dBFS at retire")
        }
    }

    @Test("Silence is exact 20 s after the last stroke")
    func silenceIsExact() {
        let engine = makeEngine(["drum": 1])
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, 47, 127, 0)
        fanfrnoch_midi(engine, 0x90, 54, 90, 64)
        _ = render(engine, seconds: 20)
        #expect(fanfrnoch_sounding_voices(engine) == 0)
        let tail = render(engine, seconds: 1)
        #expect(tail.allSatisfy { $0 == 0 && $0.sign == .plus })
    }

    @Test("A requested reset silences at the next block")
    func requestedReset() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_post_midi(engine, 0x90, Self.B2, 127, 0)
        #expect((render(engine, seconds: 0.5).map(abs).max() ?? 0) > 0.05)
        fanfrnoch_request_reset(engine)             // what a host's AudioUnitReset does, from any thread
        #expect(render(engine, frames: 128).allSatisfy { $0 == 0 })
        #expect(render(engine, seconds: 0.5).allSatisfy { $0 == 0 })
        #expect(fanfrnoch_sounding_voices(engine) == 0)
    }

    @Test("A reset forgets the last note; MIDI posted before a requested reset plays after it")
    func resetAndPostedMidi() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, 43, 110, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_last_note(engine) == 43)
        fanfrnoch_reset(engine)
        #expect(fanfrnoch_last_note(engine) == -1)

        fanfrnoch_post_midi(engine, 0x90, 36, 110, 0)
        fanfrnoch_request_reset(engine)
        #expect((render(engine, seconds: 0.2).map(abs).max() ?? 0) > 0.05)
        #expect(fanfrnoch_last_note(engine) == 36)
    }

    // A reset starts every drum's alternation again: the stroke after it is the first hand's,
    // as on a fresh engine.
    @Test("After a reset the hands alternate again from the first")
    func resetRestartsTheHands() {
        func play(_ engine: OpaquePointer) -> [Float] {
            fanfrnoch_midi(engine, 0x90, Self.B2, 110, 0)
            return render(engine, seconds: 0.5)
        }
        let used = makeEngine(Self.plain.merging(["alternate": 12]) { $1 })
        defer { fanfrnoch_destroy(used) }
        _ = play(used)
        fanfrnoch_reset(used)
        let fresh = makeEngine(Self.plain.merging(["alternate": 12]) { $1 })
        defer { fanfrnoch_destroy(fresh) }
        #expect(play(used) == play(fresh))
    }

    // A block plays at most 256 events. Posted ones beyond that wait for the next block, so a
    // dense controller stream (a large offline block) does not lose the note at its end.
    @Test("MIDI posted beyond a block's 256 events plays in the next block")
    func postedMidiBeyondABlock() {
        let engine = makeEngine(Self.plain)
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_post_midi(engine, 0x90, 47, 110, 0)
        for _ in 0..<298 { fanfrnoch_post_midi(engine, 0xB0, 1, 0, 0) }    // the mod wheel at rest
        fanfrnoch_post_midi(engine, 0x90, 52, 110, 0)                       // the 300th event
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_last_note(engine) == 47, "the first note did not play, or the last one played in the first block")
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_last_note(engine) == 52, "the last note was lost")
    }

    @Test("MIDI at a sample offset starts the stroke at that sample")
    func sampleOffset() {
        let engine = makeEngine(Self.plain)
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, Self.B2, 110, 37)
        let out = render(engine, frames: 128)
        #expect(out[..<37].allSatisfy { $0 == 0 })
        #expect(out[37...].contains { $0 != 0 })
    }

    @Test("Each set keeps its own knobs and program")
    func setsAreSeparate() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let release = Self.index("release")
        fanfrnoch_set_plain(engine, 5, release, 1)
        fanfrnoch_set_program(engine, 3, 3)
        #expect(abs(fanfrnoch_get_plain(engine, Self.keyboard, release) - 0.3) < 1e-5)   // stored normalised
        #expect(abs(fanfrnoch_get_plain(engine, 5, release) - 1) < 1e-5)
        #expect(fanfrnoch_get_program(engine, 3) == 3 && fanfrnoch_get_program(engine, Self.keyboard) == 0)
        #expect(abs(fanfrnoch_get_plain(engine, 3, release) - 60.0 / 440) < 1e-5)     // the Zambomba rings 0.14 s
        fanfrnoch_set_normalised(engine, 16, release, 0.25)
        #expect(fanfrnoch_get_normalised(engine, 16, release) == 0.25)
    }

    @Test("Recording a set's program changes no knob")
    func programIndexOnly() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let release = Self.index("release")
        fanfrnoch_set_plain(engine, 4, release, 1)
        fanfrnoch_set_program_index(engine, 4, 2)
        #expect(fanfrnoch_get_program(engine, 4) == 2)
        #expect(abs(fanfrnoch_get_plain(engine, 4, release) - 1) < 1e-5)
        fanfrnoch_set_program_index(engine, 4, -1)
        fanfrnoch_set_program_index(engine, 4, fanfrnoch_num_programs())
        #expect(fanfrnoch_get_program(engine, 4) == 2)
        fanfrnoch_set_program_index(engine, -1, 1)
        fanfrnoch_set_program_index(engine, 17, 1)
        fanfrnoch_set_program_index(nil, 0, 1)
        #expect(fanfrnoch_get_program(engine, Self.keyboard) == 0)
    }

    @Test("The C interface tolerates a null engine and indices out of range")
    func outOfRange() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let release = Self.index("release")
        for set: Int32 in [-1, 17] {
            fanfrnoch_set_plain(engine, set, release, 1)
            fanfrnoch_set_normalised(engine, set, release, 1)
            fanfrnoch_set_program(engine, set, 1)
            #expect(fanfrnoch_get_plain(engine, set, release) == 0 && fanfrnoch_get_normalised(engine, set, release) == 0)
            #expect(fanfrnoch_get_program(engine, set) == 0)
        }
        for index: Int32 in [-1, Int32(fanfrnoch_num_params())] {
            fanfrnoch_set_plain(engine, Self.keyboard, index, 1)
            #expect(fanfrnoch_get_plain(engine, Self.keyboard, index) == 0)
        }
        fanfrnoch_set_program(engine, Self.keyboard, -1)
        fanfrnoch_set_program(engine, Self.keyboard, fanfrnoch_num_programs())
        #expect(fanfrnoch_get_program(engine, Self.keyboard) == 0)
        fanfrnoch_set_mode(engine, 7)
        #expect(fanfrnoch_get_mode(engine) == Int32(FANFRNOCH_MODE_KEYBOARD))
        for pad: Int32 in [-1, 16] {
            fanfrnoch_set_pad_note(engine, pad, 40)
            fanfrnoch_set_pad_group(engine, pad, 2)
            fanfrnoch_send_to_pad(engine, pad)
            #expect(fanfrnoch_pad_note(engine, pad) == -1 && fanfrnoch_pad_group(engine, pad) == 0)
        }
        let group = fanfrnoch_pad_group(engine, 0)
        fanfrnoch_set_pad_group(engine, 0, 17)
        fanfrnoch_set_pad_group(engine, 0, -1)
        #expect(fanfrnoch_pad_group(engine, 0) == group)
        #expect(abs(fanfrnoch_get_plain(engine, Self.keyboard, release) - 0.3) < 1e-5)

        // A null engine: every call returns quietly.
        var left = [Float](repeating: 1, count: 16)
        fanfrnoch_destroy(nil)
        fanfrnoch_prepare(nil, 48_000); fanfrnoch_reset(nil); fanfrnoch_request_reset(nil)
        fanfrnoch_set_plain(nil, 0, release, 1); fanfrnoch_set_normalised(nil, 0, release, 1); fanfrnoch_set_program(nil, 0, 1)
        fanfrnoch_set_mode(nil, 1); fanfrnoch_set_pad_note(nil, 0, 40); fanfrnoch_set_pad_group(nil, 0, 1)
        fanfrnoch_send_to_pad(nil, 0); fanfrnoch_load_default_kit(nil)
        fanfrnoch_post_midi(nil, 0x90, 36, 100, 0); fanfrnoch_midi(nil, 0x90, 36, 100, 0)
        left.withUnsafeMutableBufferPointer { fanfrnoch_process(nil, $0.baseAddress, nil, 16) }
        #expect(left.allSatisfy { $0 == 0 })
        #expect(fanfrnoch_get_plain(nil, 0, release) == 0 && fanfrnoch_get_program(nil, 0) == 0 && fanfrnoch_get_mode(nil) == 0)
        #expect(fanfrnoch_latency(nil) == 0 && fanfrnoch_sounding_voices(nil) == 0 && fanfrnoch_last_note(nil) == -1)
        #expect(fanfrnoch_pad_note(nil, 0) == -1 && fanfrnoch_pad_group(nil, 0) == 0)

        var info = FanfrnochParamInfo()
        fanfrnoch_param_info(release, &info)
        fanfrnoch_param_info(-1, &info)
        #expect(info.identifier == nil && info.kind == 0 && info.maxValue == 0)
    }

    // MARK: - Sample rates and oversampling

    /// A steady stroke on note 57, A3, rendered by `engine` at `rate`: its fundamental from 0.3 s
    /// to 0.55 s.
    private func steadyPitch(_ engine: OpaquePointer, rate: Double) -> Double {
        fanfrnoch_midi(engine, 0x90, 57, 110, 0)
        let out = render(engine, seconds: 0.55, at: rate)
        return fundamental(Array(out[Self.frames(0.3, at: rate)...]), rate: rate, expected: 220)
    }

    @Test("The pitch is right at every rate", arguments: [44_100.0, 48_000, 88_200, 96_000, 192_000])
    func pitchAtEveryRate(rate: Double) {
        let engine = makeEngine(Self.steady, rate: rate)
        defer { fanfrnoch_destroy(engine) }
        let hz = steadyPitch(engine, rate: rate)
        #expect(abs(hz / 220 - 1) < 0.001, "\(rate) Hz: \(hz) Hz")
    }

    /// The share of the power below 20 kHz that lies more than 20 Hz from every harmonic of
    /// `f0`, in dB: what aliasing folds between the harmonics. A Blackman-Harris window over
    /// 0.68-0.74 s from 0.3 s into the stroke, when the attack is over.
    private func aliasDb(_ x: [Float], rate: Double, f0: Double) -> Double {
        let log2n = vDSP_Length(rate < 88_200 ? 15 : 16)
        let n = 1 << Int(log2n)
        let start = Self.frames(0.3, at: rate)
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { preconditionFailure("no FFT") }
        defer { vDSP_destroy_fftsetup(setup) }
        let frame = (0..<n).map { i -> Float in
            let p = 2 * Double.pi * Double(i) / Double(n - 1)
            let w = 0.35875 - 0.48829 * cos(p) + 0.14128 * cos(2 * p) - 0.01168 * cos(3 * p)
            return x[start + i] * Float(w)
        }
        var real = [Float](repeating: 0, count: n / 2), imag = [Float](repeating: 0, count: n / 2)
        var power = [Float](repeating: 0, count: n / 2)
        real.withUnsafeMutableBufferPointer { r in
            imag.withUnsafeMutableBufferPointer { i in
                var split = DSPSplitComplex(realp: r.baseAddress!, imagp: i.baseAddress!)
                frame.withUnsafeBytes { bytes in
                    vDSP_ctoz(bytes.bindMemory(to: DSPComplex.self).baseAddress!, 2, &split, 1, vDSP_Length(n / 2))
                }
                vDSP_fft_zrip(setup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                power.withUnsafeMutableBufferPointer { m in vDSP_zvmags(&split, 1, m.baseAddress!, 1, vDSP_Length(n / 2)) }
            }
        }
        var between = 0.0, total = 0.0
        for bin in 1..<(n / 2) {
            let hz = Double(bin) * rate / Double(n)
            guard hz < 20_000 else { break }
            total += Double(power[bin])
            if abs(hz - f0 * (hz / f0).rounded()) > 20 { between += Double(power[bin]) }
        }
        return 10 * log10(between / total)
    }

    // The brightest steady tone (Stick 0.95, no darkening) at 860 Hz (A5 tuned 40 cents down):
    // the warped cosine's corners reach far above the band. Played at the host's rate, as the
    // prototype does (through the reference), what folds back at 44.1 kHz is over the -60 dB the
    // design allows; with the engine's 2x stage it is far under it.
    @Test("At 44.1 kHz the brightest tone's alias products stay 60 dB down; without the 2x stage they would not")
    func aliasing() {
        let rate = 44_100.0
        let bright: [String: Float] = Self.steady.merging(["stick": 0.95, "stickvel": 0, "tune": -40]) { $1 }
        let f0 = 440 * pow(2, (81 - 40.0 / 100 - 69) / 12)
        let engine = makeEngine(bright, rate: rate)
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, 81, 127, 0)
        let oversampled = aliasDb(render(engine, seconds: 1.2, at: rate), rate: rate, f0: f0)

        var p = PrototypeScores.referenceParams(bright)
        let stroke = FanfrnochRefEvent(time: 0, drum: 0, hz: f0, velocity: 1, params: 0, noteOff: 0)
        var direct = [Float](repeating: 0, count: Self.frames(1.2, at: rate))
        fanfrnoch_ref_render([stroke], 1, &p, 1, 1, rate, 0, &direct, Int32(direct.count))
        let atHostRate = aliasDb(direct, rate: rate, f0: f0)
        print(String(format: "aliasing at 44.1 kHz, Stick 0.95, 860 Hz: %.1f dB with the 2x stage, %.1f dB without", oversampled, atHostRate))
        #expect(oversampled < -60, "with the 2x stage: \(oversampled) dB")
        #expect(atHostRate > -60, "without it: \(atHostRate) dB")
    }

    // Below 88.2 kHz the output is the voices at twice the rate, decimated: the same stroke at the
    // doubled rate, taken every second sample, lags behind by the decimator's delay. The stroke is
    // 37 frames into the block at the host rate and 74 at the doubled rate: the same instant.
    @Test("Latency is the decimator's delay")
    func latency() {
        for rate in [44_100.0, 48_000] {
            let host = makeEngine(Self.plain, rate: rate), doubled = makeEngine(Self.plain, rate: 2 * rate)
            defer { fanfrnoch_destroy(host); fanfrnoch_destroy(doubled) }
            #expect(fanfrnoch_latency(doubled) == 0)
            let latency = Int(fanfrnoch_latency(host))
            #expect(latency == 29, "\(rate) Hz: the 119-tap filter's centre is 59 samples, 29 pairs and one, in")
            fanfrnoch_midi(host, 0x90, Self.B2, 110, 37)
            fanfrnoch_midi(doubled, 0x90, Self.B2, 110, 74)
            let y = render(host, seconds: 0.5, at: rate), z = render(doubled, seconds: 0.5, at: 2 * rate)
            func correlation(_ lag: Int) -> Double {
                var sum = 0.0
                for m in lag..<(y.count - 64) { sum += Double(y[m]) * Double(z[2 * (m - lag)]) }
                return sum
            }
            let best = (0...64).max { correlation($0) < correlation($1) }!
            #expect(abs(best - latency) <= 1, "\(rate) Hz: best lag \(best), latency \(latency)")
            // The decimator has unit gain: the host-rate output is the doubled-rate output taken every
            // second sample and delayed by the latency, to within -60 dB.
            let aligned = (latency..<(y.count - 64)).map { y[$0] }
            let taken = (latency..<(y.count - 64)).map { z[2 * ($0 - latency)] }
            let residual = residualDb(aligned, taken)
            #expect(residual < -60, "\(rate) Hz: the decimated output differs from the doubled-rate one by \(residual) dB")
        }
        for rate in [88_200.0, 96_000, 192_000] {
            let engine = makeEngine(rate: rate)
            defer { fanfrnoch_destroy(engine) }
            #expect(fanfrnoch_latency(engine) == 0, "\(rate) Hz")
        }
    }

    // A rate change mid-stroke starts from silence: the first block is exactly zero, and what is
    // played then is what a fresh engine at that rate plays, sample for sample.
    @Test("Re-preparing changes the rate cleanly")
    func rePrepareChangesRate() {
        let engine = makeEngine(Self.steady, rate: 96_000)
        defer { fanfrnoch_destroy(engine) }
        #expect(abs(steadyPitch(engine, rate: 96_000) / 220 - 1) < 0.001)
        for rate in [44_100.0, 96_000] {
            fanfrnoch_prepare(engine, rate)                       // the last stroke still sounds
            let first = render(engine, frames: 128)
            #expect(first.allSatisfy { $0 == 0 }, "\(rate) Hz: the first block after prepare")
            let hz = steadyPitch(engine, rate: rate)
            #expect(abs(hz / 220 - 1) < 0.001, "\(rate) Hz: \(hz) Hz")
            fanfrnoch_reset(engine)
            fanfrnoch_midi(engine, 0x90, 57, 110, 0)
            let again = render(engine, seconds: 0.5, at: rate)
            let fresh = makeEngine(Self.steady, rate: rate)
            defer { fanfrnoch_destroy(fresh) }
            fanfrnoch_midi(fresh, 0x90, 57, 110, 0)
            #expect(again == render(fresh, seconds: 0.5, at: rate), "\(rate) Hz: differs from a fresh engine")
        }
    }

    // Every knob at its minimum, every knob at its maximum (Pan too: one channel is silent), and
    // the sharpest body following the pitch up on a high note. Each is played from the lowest note
    // to the highest, hard and soft. (At the minimum every amount is -100 %: the soft strokes'
    // VEL amounts lengthen the stroke, and the LFOs turn Volume up.)
    @Test("Extreme knobs stay finite", arguments: [44_100.0, 96_000])
    func extremeKnobsStayFinite(rate: Double) {
        func play(_ setKnobs: (OpaquePointer) -> Void, notes: [Int32]) -> (left: [Float], right: [Float]) {
            let engine = makeEngine(rate: rate)
            defer { fanfrnoch_destroy(engine) }
            setKnobs(engine)
            var out: (left: [Float], right: [Float]) = ([], [])
            for note in notes {
                for velocity: Int32 in [127, 1] {
                    fanfrnoch_midi(engine, 0x90, note, velocity, 0)
                    let part = renderStereo(engine, frames: Self.frames(0.25, at: rate))
                    out.left += part.left; out.right += part.right
                }
            }
            let tail = renderStereo(engine, frames: Self.frames(1, at: rate))
            return (out.left + tail.left, out.right + tail.right)
        }
        let everyNote: [Int32] = [0, 24, 36, 60, 84, 96, 108, 127]
        let all: (Float) -> (OpaquePointer) -> Void = { n in
            { engine in for i in 0..<fanfrnoch_num_params() { fanfrnoch_set_normalised(engine, Self.keyboard, i, n) } }
        }
        let cases: [(name: String, render: (left: [Float], right: [Float]))] = [
            ("all at minimum", play(all(0), notes: everyNote)),
            ("all at maximum", play(all(1), notes: everyNote)),
            ("Pot Q 20 at 1500 Hz +18 dB, Skin Q 40 at 1500 Hz +6 dB, Track 100 %",
             play({ self.setKnobs($0, ["potq": 20, "pot": 1500, "potlevel": 18, "skinq": 40, "skin": 1500, "skinlevel": 6,
                                       "track": 100]) }, notes: [96])),
        ]
        for c in cases {
            let samples = c.render.left + c.render.right
            #expect(samples.allSatisfy { $0.isFinite }, "\(rate) Hz, \(c.name): NaN or Inf")
            let peak = samples.map(abs).max() ?? 0
            #expect(peak <= 1, "\(rate) Hz, \(c.name): peak \(peak)")
            #expect(peak > 0, "\(rate) Hz, \(c.name): silent")
        }
    }

    // MARK: - The voice pool

    /// The longest sound: the hand rubs for 2 s and the head rings 3 s.
    private static let long: [String: Float] = ["length": 2000, "release": 3]

    /// Plays `hits` (note, velocity) at every 32nd note at 120 BPM for 4 s, in `mode`, with the
    /// longest Fanfrnoch in every set and every pad on C2 with its group Off, and checks the pool
    /// after every block.
    private func flood(rate: Double, mode: Int32, knobs: [String: Float] = [:], hits: (Int) -> [(note: Int32, velocity: Int32)]) {
        let engine = makeEngine(rate: rate)
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_set_mode(engine, mode)
        for set: Int32 in 0..<Int32(FANFRNOCH_NUM_SETS) {
            fanfrnoch_set_program(engine, set, 0)
            setKnobs(engine, Self.long.merging(["scrape": 0]) { $1 }.merging(knobs) { $1 }, set: set)
        }
        for pad: Int32 in 0..<Int32(FANFRNOCH_NUM_PADS) { fanfrnoch_set_pad_group(engine, pad, 0); fanfrnoch_set_pad_note(engine, pad, 36) }
        let step = 60.0 / 120 / 8, total = Self.frames(4, at: rate)
        var out = [Float](repeating: 0, count: total)
        var nextStep = 0, start = 0, mostSounding: Int32 = 0
        out.withUnsafeMutableBufferPointer { buffer in
            while start < total {
                let count = min(128, total - start)
                while Self.frames(Double(nextStep) * step, at: rate) < start + count {
                    let offset = Int32(Self.frames(Double(nextStep) * step, at: rate) - start)
                    for hit in hits(nextStep) { fanfrnoch_midi(engine, 0x90, hit.note, hit.velocity, offset) }
                    nextStep += 1
                }
                fanfrnoch_process(engine, buffer.baseAddress! + start, nil, Int32(count))
                mostSounding = max(mostSounding, fanfrnoch_sounding_voices(engine))
                start += count
            }
        }
        let name = mode == Int32(FANFRNOCH_MODE_PADS) ? "pads" : "keyboard"
        #expect(mostSounding <= Int32(FANFRNOCH_MAX_VOICES), "\(rate) Hz, \(name): \(mostSounding) voices sounded")
        #expect(mostSounding == Int32(FANFRNOCH_MAX_VOICES), "\(rate) Hz, \(name): the pool was never full")
        #expect(out.allSatisfy { $0.isFinite }, "\(rate) Hz, \(name): NaN or Inf")
        // No voice is cut: a stolen voice fades in 3 ms, and a stroke on a sounding drum goes on
        // from where the head is. The biggest step is then the slips of sixteen loud voices at
        // once. (No Scrape and low notes here: sixteen strokes starting together would make their
        // sixteen bursts of noise the biggest step, and high notes slip faster.)
        let biggestStep = zip(out.dropFirst(), out).map { abs($0 - $1) }.max() ?? 0
        let bound: Float = rate < 88_200 ? 0.45 : 0.25
        #expect(biggestStep <= bound, "\(rate) Hz, \(name): a step of \(biggestStep)")
    }

    // All 16 pads, each a drum of its own (Group Off), on every 32nd note, each a little softer than
    // the one before it in turn: sixteen drums keep their sixteen voices. And the keyboard with Drum
    // Many running up 24 keys, a key per 32nd note: 24 drums would sound.
    @Test("A flood of strokes stays within 16 voices", arguments: [44_100.0, 96_000])
    func stealingStaysBounded(rate: Double) {
        flood(rate: rate, mode: Int32(FANFRNOCH_MODE_PADS)) { step in
            (0..<Int32(FANFRNOCH_NUM_PADS)).map { (Int32(FANFRNOCH_FIRST_PAD_NOTE) + $0, Int32(127 - 3 * ((Int($0) + step) % 16))) }
        }
        flood(rate: rate, mode: Int32(FANFRNOCH_MODE_KEYBOARD), knobs: ["drum": 1]) { step in [(Int32(36 + step % 24), Int32(127))] }
    }

    // Twelve keys sound for 5 s while the pads are flooded: the pool of 16 is shared by both
    // origins, so the pads steal keyboard voices and one another, and never more than 16 sound.
    @Test("Pads flooded over sounding keys stay within 16 voices", arguments: [44_100.0, 96_000])
    func mixedFloodStaysBounded(rate: Double) {
        let engine = makeEngine(rate: rate)
        defer { fanfrnoch_destroy(engine) }
        for set: Int32 in 0..<Int32(FANFRNOCH_NUM_SETS) { setKnobs(engine, Self.long, set: set) }
        setKnobs(engine, ["drum": 1])
        for pad: Int32 in 0..<Int32(FANFRNOCH_NUM_PADS) { fanfrnoch_set_pad_group(engine, pad, 0) }
        for key: Int32 in 0..<12 { fanfrnoch_midi(engine, 0x90, 48 + key, 100, 0) }       // twelve drums sound
        var out = render(engine, seconds: 0.2, at: rate)
        #expect(fanfrnoch_sounding_voices(engine) == 12)
        fanfrnoch_set_mode(engine, Int32(FANFRNOCH_MODE_PADS))
        let step = 60.0 / 120 / 8, total = Self.frames(3, at: rate)
        var nextStep = 0, start = 0, mostSounding: Int32 = 0
        var padOut = [Float](repeating: 0, count: total)
        padOut.withUnsafeMutableBufferPointer { buffer in
            while start < total {
                let count = min(128, total - start)
                while Self.frames(Double(nextStep) * step, at: rate) < start + count {
                    let offset = Int32(Self.frames(Double(nextStep) * step, at: rate) - start)
                    for pad: Int32 in 0..<Int32(FANFRNOCH_NUM_PADS) {
                        fanfrnoch_midi(engine, 0x90, Int32(FANFRNOCH_FIRST_PAD_NOTE) + pad, Int32(127 - 3 * ((Int(pad) + nextStep) % 16)), offset)
                    }
                    nextStep += 1
                }
                fanfrnoch_process(engine, buffer.baseAddress! + start, nil, Int32(count))
                mostSounding = max(mostSounding, fanfrnoch_sounding_voices(engine))
                #expect(fanfrnoch_sounding_voices(engine) <= Int32(FANFRNOCH_MAX_VOICES))
                start += count
            }
        }
        out += padOut
        #expect(mostSounding <= Int32(FANFRNOCH_MAX_VOICES), "\(rate) Hz: \(mostSounding) voices sounded")
        #expect(mostSounding == Int32(FANFRNOCH_MAX_VOICES), "\(rate) Hz: the pool was never full")
        #expect(out.allSatisfy { $0.isFinite }, "\(rate) Hz: NaN or Inf")
    }

    // Sixteen drums sound (Drum Many), the first one soft, and a 17th steals the soft drum's voice:
    // it fades out in 3 ms as the 17th is struck, and from then on what is heard is the other
    // fifteen and the 17th, as if the soft one had never been struck. No randomness, so the voices'
    // seeds do not matter.
    @Test("The quietest voice is stolen, with a 3 ms fade")
    func stealsTheQuietest() {
        func play(withSoft: Bool) -> [Float] {
            let engine = makeEngine(Self.plain.merging(Self.long) { $1 }.merging(["drum": 1, "volume": -24]) { $1 })
            defer { fanfrnoch_destroy(engine) }
            if withSoft { fanfrnoch_midi(engine, 0x90, 40, 20, 0) }
            for note: Int32 in 41..<56 { fanfrnoch_midi(engine, 0x90, note, 127, 0) }
            _ = render(engine, seconds: 0.2)
            #expect(fanfrnoch_sounding_voices(engine) == (withSoft ? 16 : 15))
            fanfrnoch_midi(engine, 0x90, 60, 127, 0)
            let out = render(engine, seconds: 0.3)
            #expect(fanfrnoch_sounding_voices(engine) == 16)
            return out
        }
        let stolen = play(withSoft: true), without = play(withSoft: false)
        let fade = Self.frames(0.010)
        #expect(residualDb(stolen[fade...], without[fade...]) < -100, "after the fade")
        #expect(residualDb(stolen[..<Self.frames(0.002)], without[..<Self.frames(0.002)]) > -60, "the soft drum was cut, not faded")
    }

    @Test("Pad hits are counted per pad, in pad mode only")
    func padHitsCount() {
        let synth = Synth(sampleRate: Self.rate)
        func play(_ frames: Int = 512) {
            var out = [Float](repeating: 0, count: frames)
            out.withUnsafeMutableBufferPointer { synth.render(left: $0.baseAddress!, right: nil, frames: frames) }
        }
        synth.noteOn(36)                                   // keyboard mode: no pad is hit
        play()
        #expect((0..<16).allSatisfy { synth.padHits($0) == 0 })
        synth.mode = .pads
        synth.noteOn(36); play()
        synth.noteOn(36); play()
        synth.noteOn(37); play()
        #expect(synth.padHits(0) == 2 && synth.padHits(1) == 1 && synth.padHits(2) == 0)
        synth.noteOn(60); play()                           // outside 36-51: ignored in pad mode
        #expect(synth.padHits(0) == 2)
        synth.prepare(sampleRate: Self.rate)               // a reset leaves the count alone
        #expect(synth.padHits(0) == 2)
        #expect(synth.padHits(-1) == 0 && synth.padHits(16) == 0)
        #expect(fanfrnoch_pad_hits(nil, 0) == 0)
    }

    // Not a promise but a measure: sixteen voices of the longest default sound (every pad a drum of
    // its own) for 2 s at 48 kHz, where they run at 96 kHz. The time per voice is printed for the
    // phase's records; it is meaningful in a release build (`swift test -c release`).
    @Test("Sixteen voices render, and the time each takes is measured")
    func cpuPerVoice() {
        let rate = 48_000.0
        let engine = makeEngine(rate: rate)
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_set_mode(engine, Int32(FANFRNOCH_MODE_PADS))
        for pad: Int32 in 0..<Int32(FANFRNOCH_NUM_PADS) {
            fanfrnoch_set_program(engine, pad + 1, 0)
            setKnobs(engine, Self.long.merging(["potlevel": 0, "skinlevel": 0]) { $1 }, set: pad + 1)
            fanfrnoch_set_pad_group(engine, pad, 0)
            fanfrnoch_midi(engine, 0x90, Int32(FANFRNOCH_FIRST_PAD_NOTE) + pad, 100, 0)
        }
        let seconds = 2.0
        let clock = ContinuousClock()
        let elapsed = clock.measure { _ = render(engine, seconds: seconds, at: rate) }
        #expect(fanfrnoch_sounding_voices(engine) == 16)
        let share = Double(elapsed.components.attoseconds) / 1e18 + Double(elapsed.components.seconds)
        print(String(format: "CPU: 16 voices for %.0f s at 48 kHz took %.3f s: %.2f %% of one core per voice",
                     seconds, share, 100 * share / seconds / 16))
    }

    // MARK: - MIDI controllers

    /// Every knob of every pad's set, normalised.
    private func padSets(_ engine: OpaquePointer) -> [[Float]] {
        (1...Int32(FANFRNOCH_NUM_PADS)).map { set in (0..<fanfrnoch_num_params()).map { fanfrnoch_get_normalised(engine, set, $0) } }
    }

    /// The knobs: the parameters that come with a controller.
    private static let numKnobs = Int32(Parameters.all.filter { Controllers.standard(for: $0) != nil }.count)

    @Test("A controller moves its keyboard knob: 127 the top, 64 the middle of a bipolar knob; no pad moves")
    func controllerMovesKnob() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_set_mode(engine, Int32(FANFRNOCH_MODE_PADS))         // a controller moves the keyboard set in pad mode too
        let pads = padSets(engine)
        let stick = Self.index("stick"), pan = Self.index("pan")
        let before = fanfrnoch_changes(engine)

        fanfrnoch_midi(engine, 0xB0, 74, 127, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, stick) == 1)
        #expect(abs(fanfrnoch_get_plain(engine, Self.keyboard, stick) - 0.95) < 1e-5)
        #expect(fanfrnoch_changes(engine) != before)

        let moved = fanfrnoch_changes(engine)
        #expect(fanfrnoch_get_controller(engine, pan) == 10)
        fanfrnoch_midi(engine, 0xB5, 10, 64, 0)                     // channel 6: any channel will do
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, pan) == 0.5)
        #expect(fanfrnoch_get_plain(engine, Self.keyboard, pan) == 0)
        #expect(fanfrnoch_changes(engine) != moved)

        for controller: Int32 in 0...127 where ![120, 121, 123].contains(controller) {
            fanfrnoch_midi(engine, 0xB0, controller, 127 - controller, 0)
        }
        _ = render(engine, frames: 128)
        #expect(padSets(engine) == pads)
    }

    @Test("A controller is applied at its sample offset, in the order of the block's events")
    func controllerAtItsOffset() {
        let volume = Self.index("volume")
        func sounding() -> OpaquePointer {
            let engine = makeEngine(Self.plain)
            fanfrnoch_midi(engine, 0x90, Self.B2, 120, 0)
            _ = render(engine, seconds: 0.1)
            return engine
        }
        let atOffset = sounding(), split = sounding(), atStart = sounding(), untouched = sounding()
        defer { for engine in [atOffset, split, atStart, untouched] { fanfrnoch_destroy(engine) } }

        fanfrnoch_midi(atOffset, 0xB0, 7, 0, 50)
        let a = render(atOffset, frames: 128)
        var b = render(split, frames: 50)
        fanfrnoch_midi(split, 0xB0, 7, 0, 0)
        b += render(split, frames: 78)
        fanfrnoch_midi(atStart, 0xB0, 7, 0, 0)
        let c = render(atStart, frames: 128)

        #expect(fanfrnoch_get_normalised(atOffset, Self.keyboard, volume) == 0)
        #expect(a == b, "the controller did not land at frame 50")
        #expect(Array(a[..<50]) == render(untouched, frames: 50), "the controller acted before frame 50")
        #expect(a != c)
    }

    @Test("A note after a controller in the same block plays the controller's knob")
    func controllerBeforeANote() {
        let stick = Self.index("stick")
        let engine = makeEngine(Self.plain)
        defer { fanfrnoch_destroy(engine) }
        let cc = fanfrnoch_get_controller(engine, stick)
        fanfrnoch_midi(engine, 0x90, Self.B2, 110, 20)
        fanfrnoch_midi(engine, 0xB0, cc, 0, 10)                       // Stick 0.5, before the note
        let played = render(engine, frames: 4_096)

        let reference = makeEngine(Self.plain.merging(["stick": 0.5]) { $1 })
        defer { fanfrnoch_destroy(reference) }
        fanfrnoch_midi(reference, 0x90, Self.B2, 110, 20)
        #expect(played == render(reference, frames: 4_096))
    }

    @Test("A knob that learns takes the next controller that moves, and its value")
    func learnTakesNextCC() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let split = Self.index("split")
        let standard = fanfrnoch_standard_controller(split)
        #expect(fanfrnoch_learning(engine) == -1)
        fanfrnoch_learn(engine, split)
        #expect(fanfrnoch_learning(engine) == split)
        let before = fanfrnoch_changes(engine)

        fanfrnoch_midi(engine, 0xB3, 40, 127, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_learning(engine) == -1)
        #expect(fanfrnoch_get_controller(engine, split) == 40)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, split) == 1)
        #expect(fanfrnoch_changes(engine) != before)

        fanfrnoch_midi(engine, 0xB0, standard, 0, 0)                 // the one it came with moves it no more
        fanfrnoch_midi(engine, 0xB0, 41, 0, 0)                       // nor does the next one: learning is over
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, split) == 1)
        #expect(fanfrnoch_get_controller(engine, split) == 40)

        fanfrnoch_learn(engine, split)
        fanfrnoch_learn(engine, -1)                                   // called off
        fanfrnoch_midi(engine, 0xB0, 42, 0, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_controller(engine, split) == 40)
        for param: Int32 in [Int32(fanfrnoch_lfo_amount(0, Self.index("stick"))), fanfrnoch_num_params(), -2] {
            fanfrnoch_learn(engine, param)                            // an amount, or no parameter: nobody learns
            #expect(fanfrnoch_learning(engine) == -1)
        }
    }

    @Test("A reserved controller is not given to a knob, and does not end a learn")
    func reservedNotTaken() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let split = Self.index("split")
        let standard = fanfrnoch_standard_controller(split)
        let reserved: [Int32] = [0, 1, 6, 32, 38, 64] + Array(96...101) + Array(120...127)
        for controller in reserved {
            #expect(fanfrnoch_controller_reserved(controller) == 1, "CC \(controller)")
            fanfrnoch_set_controller(engine, split, controller)
            #expect(fanfrnoch_get_controller(engine, split) == standard, "CC \(controller)")
        }
        #expect(fanfrnoch_controller_reserved(-1) == 1 && fanfrnoch_controller_reserved(128) == 1)
        fanfrnoch_set_controller(engine, split, 128)
        #expect(fanfrnoch_get_controller(engine, split) == standard)

        fanfrnoch_learn(engine, split)
        for controller in reserved where ![120, 121, 123].contains(controller) { fanfrnoch_midi(engine, 0xB0, controller, 100, 0) }
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_learning(engine) == split)
        #expect(fanfrnoch_get_controller(engine, split) == standard)
    }

    @Test("One controller serves one knob")
    func oneControllerOneKnob() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let split = Self.index("split"), stick = Self.index("stick")
        fanfrnoch_set_controller(engine, split, 74)                   // Stick's
        #expect(fanfrnoch_get_controller(engine, split) == 74)
        #expect(fanfrnoch_get_controller(engine, stick) == -1)
        let stickBefore = fanfrnoch_get_normalised(engine, Self.keyboard, stick)
        fanfrnoch_midi(engine, 0xB0, 74, 127, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, split) == 1)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, stick) == stickBefore)

        fanfrnoch_learn(engine, stick)                                // learnt back
        fanfrnoch_midi(engine, 0xB0, 74, 0, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_controller(engine, stick) == 74 && fanfrnoch_get_controller(engine, split) == -1)

        fanfrnoch_set_controller(engine, stick, -1)
        #expect(fanfrnoch_get_controller(engine, stick) == -1)
        fanfrnoch_reset_controllers(engine)
        for knob: Int32 in 0..<Self.numKnobs {
            #expect(fanfrnoch_get_controller(engine, knob) == fanfrnoch_standard_controller(knob))
        }
    }

    @Test("Controllers nobody listens to, a changed map and a learn called off leave the sound bit for bit")
    func sameSoundWithoutCC() {
        let events = PrototypeScores.events(PrototypeScores.render(named: "01b_fanfrnoch_default_groove"), rate: Self.rate)
        func play(_ engine: OpaquePointer, noise: Bool) -> [Float] {
            var out: [Float] = []
            var next = 0
            for block in 0..<Self.frames(3) / 128 {
                let start = block * 128
                while next < events.count, events[next].frame < start + 128 {
                    let e = events[next]
                    fanfrnoch_midi(engine, e.noteOff ? 0x80 : 0x90, Int32(e.note), Int32(e.velocity), Int32(e.frame - start))
                    next += 1
                }
                if noise {
                    for controller: Int32 in [3, 40, 116, 119, 0, 6, 64, 127] {
                        fanfrnoch_midi(engine, 0xB0, controller, Int32(block % 128), Int32(block % 128))
                    }
                }
                out += render(engine, frames: 128)
            }
            return out
        }
        let quiet = makeEngine()
        defer { fanfrnoch_destroy(quiet) }
        let busy = makeEngine()
        defer { fanfrnoch_destroy(busy) }
        fanfrnoch_set_controller(busy, Self.index("split"), 74)
        fanfrnoch_set_controller(busy, Self.index("release"), -1)
        fanfrnoch_reset_controllers(busy)
        fanfrnoch_learn(busy, Self.index("release"))
        fanfrnoch_learn(busy, -1)
        let before = fanfrnoch_changes(busy)
        #expect(play(busy, noise: true) == play(quiet, noise: false))
        #expect(fanfrnoch_changes(busy) == before)
    }

    @Test("The controller calls tolerate a null engine and parameters out of range")
    func controllersOutOfRange() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        for param: Int32 in [-1, fanfrnoch_num_params(), Int32(fanfrnoch_vel_amount(Self.index("release")))] {
            #expect(fanfrnoch_standard_controller(param) == -1)
            fanfrnoch_set_controller(engine, param, 40)
            #expect(fanfrnoch_get_controller(engine, param) == -1)
        }
        fanfrnoch_set_controller(nil, 0, 40); fanfrnoch_reset_controllers(nil); fanfrnoch_learn(nil, 0)
        #expect(fanfrnoch_get_controller(nil, 0) == -1 && fanfrnoch_learning(nil) == -1 && fanfrnoch_changes(nil) == 0)
    }
}
