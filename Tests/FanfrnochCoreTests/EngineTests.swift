import Accelerate
import Foundation
import Testing
import FanfrnochDSP
@testable import FanfrnochCore

/// What the sound engine promises beyond matching the prototype: its level, how it chokes and
/// stops, how it keeps its pitch and its sound at every sample rate, how it shares its voices, and
/// how its C interface copes with what callers hand it.
@Suite("Engine")
struct EngineTests: EngineHarness {

    /// The same with no breath. The breath gives the bursts a DC component, and the DC blocker
    /// takes ~20 ms to forget it after a voice stops: that would hide what the reed does.
    private static let dry = plain.merging(["breath": 0, "puff": 0]) { $1 }

    @Test("The default hit at full velocity peaks around -6 dBFS")
    func level() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, 36, 127, 0)
        let peak = render(engine, seconds: 2).map(abs).max() ?? 0
        #expect(peak > 0.42 && peak < 0.56, "peak \(peak)")
    }

    @Test("A note re-struck chokes its own ring within Damp")
    func restrike() {
        let length = Int(Self.rate)
        let twice = makeEngine(Self.dry)
        defer { fanfrnoch_destroy(twice) }
        fanfrnoch_midi(twice, 0x90, 36, 110, 0)
        _ = render(twice, frames: length)
        fanfrnoch_midi(twice, 0x90, 36, 110, 0)
        let second = render(twice, frames: length)

        let once = makeEngine(Self.dry)
        defer { fanfrnoch_destroy(once) }
        fanfrnoch_midi(once, 0x90, 36, 110, 0)
        let lone = render(once, frames: length)

        // The first ring is gone after Damp (10 ms): from then on the two are the same hit.
        let damp = Int(0.010 * Self.rate)
        let r = residualDb(second[damp...], lone[damp...])
        #expect(r < -60, "residual \(r) dB")
    }

    @Test("Key Up = Damp stops the note at note-off; Ring lets it ring")
    func keyUp() {
        func afterRelease(_ keyUp: Float) -> (sounding: Int32, rms: Double) {
            let engine = makeEngine(Self.dry.merging(["keyup": keyUp]) { $1 })
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, 36, 110, 0)
            _ = render(engine, seconds: 0.5)
            fanfrnoch_midi(engine, 0x80, 36, 0, 0)
            _ = render(engine, seconds: 0.05)           // Damp is 10 ms: 100 dB down in 25 ms
            let sounding = fanfrnoch_sounding_voices(engine)
            return (sounding, rms(render(engine, seconds: 0.2)))
        }
        let ring = afterRelease(0), damp = afterRelease(1)
        #expect(ring.sounding == 1 && damp.sounding == 0)
        #expect(ring.rms > 0.001)
        #expect(20 * log10(damp.rms / ring.rms) < -60, "damped \(damp.rms), ringing \(ring.rms)")
    }

    @Test("All Sound Off and All Notes Off choke every voice")
    func allOff() {
        for controller: Int32 in [120, 123] {
            let engine = makeEngine(Self.plain)
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, 36, 110, 0)
            fanfrnoch_midi(engine, 0x90, 43, 110, 0)
            _ = render(engine, seconds: 0.2)
            #expect(fanfrnoch_sounding_voices(engine) == 2)
            fanfrnoch_midi(engine, 0xB0, controller, 0, 0)
            _ = render(engine, seconds: 0.05)
            #expect(fanfrnoch_sounding_voices(engine) == 0, "CC \(controller)")
        }
    }

    /// The bus's DC blocker, as the engine computes it at 96 kHz.
    private static let dcCoefficient = Float(1 - 48 / rate)

    // What is left once the voices stop is the DC blocker's memory of the reed's DC (Offset
    // makes the bursts lopsided): it falls by the blocker's coefficient every sample, -4.2 dB in
    // 10 ms, and is under -120 dBFS ~110 ms after the controller. So the test asks for no voice
    // in the bus after 50 ms, which is exact, and for -120 dBFS after 150 ms.
    @Test("After All Sound Off or All Notes Off the voices are silent within 50 ms")
    func allOffFallsSilent() {
        for controller: Int32 in [120, 123] {
            let engine = makeEngine(Self.dry)
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, 36, 110, 0)
            fanfrnoch_midi(engine, 0x90, 43, 110, 0)
            #expect((render(engine, seconds: 0.2).map(abs).max() ?? 0) > 0.05)
            fanfrnoch_midi(engine, 0xB0, controller, 0, 0)
            _ = render(engine, seconds: 0.05)
            let tail = render(engine, seconds: 0.1)
            let onlyTheBlocker = zip(tail.dropFirst(), tail).allSatisfy { next, previous in
                previous == 0 ? next == 0 : abs(next / previous - Self.dcCoefficient) < 1e-5
            }
            #expect(onlyTheBlocker, "CC \(controller): a voice is still in the bus 50 ms after it")
            let peak = render(engine, seconds: 0.5).map(abs).max() ?? 0
            #expect(peak == 0 || 20 * log10(peak) < -120, "CC \(controller): \(20 * log10(peak)) dBFS after 150 ms")
        }
    }

    // The slot's gate is open while the reed rests, so Air and the breath used to go on at a
    // constant level until the voice retired, and the breath stopped as a step there. Since
    // 2026-11-16 both fade with the reed. The breath fades with the reed's level, not with its
    // decay since the hit: the voice retires on a level, so the softest hit, whose reed starts
    // 42 dB down, must not retire with its breath still on (it did, as a step at -34 dBFS).
    @Test("Air fades with the reed's tail, and the breath ends without a step at retire")
    func tailFades() throws {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, 36, 127, 0)
        let x = render(engine, seconds: 8)
        #expect(fanfrnoch_sounding_voices(engine) == 0, "the voice has not retired within 8 s")

        let early = rms(x[Self.frames(2.0)..<Self.frames(2.5)])
        let late = rms(x[Self.frames(3.0)..<Self.frames(3.5)])
        let fall = 20 * log10(late / early)
        #expect(fall < -12, "3.0-3.5 s is \(fall) dB re 2.0-2.5 s")

        let tail = x[Self.frames(4)...]
        let step = zip(tail.dropFirst(), tail).map { abs($0 - $1) }.max() ?? 0
        #expect(step < 1e-5, "largest sample-to-sample difference after 4 s: \(step)")

        // The softest hit with the most breath: the 50 ms either side of the block it retires in.
        let soft = makeEngine(Self.plain.merging(["velsens": 100, "breath": 100]) { $1 })
        defer { fanfrnoch_destroy(soft) }
        fanfrnoch_midi(soft, 0x90, 36, 1, 0)
        var y: [Float] = [], retired: Int?
        while y.count < Self.frames(8) {
            y += render(soft, frames: 128)
            if retired == nil && fanfrnoch_sounding_voices(soft) == 0 { retired = y.count }
        }
        let retire = try #require(retired, "the soft voice has not retired within 8 s")
        let around = y[(retire - Self.frames(0.05))..<(retire + Self.frames(0.05))]
        let softStep = zip(around.dropFirst(), around).map { abs($0 - $1) }.max() ?? 0
        #expect(20 * log10(softStep) < -90, "largest step around the soft voice's retire: \(20 * log10(softStep)) dBFS")
    }

    @Test("Silence is exact 20 s after the last hit")
    func silenceIsExact() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, 36, 127, 0)
        fanfrnoch_midi(engine, 0x90, 43, 90, 64)
        _ = render(engine, seconds: 20)
        #expect(fanfrnoch_sounding_voices(engine) == 0)
        let tail = render(engine, seconds: 1)
        #expect(tail.allSatisfy { $0 == 0 && $0.sign == .plus })
    }

    @Test("A requested reset silences at the next block")
    func requestedReset() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_post_midi(engine, 0x90, 36, 127, 0)
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

    // A block plays at most 256 events. Posted ones beyond that wait for the next block, so a
    // dense controller stream (a large offline block) does not lose the note-off at its end.
    @Test("MIDI posted beyond a block's 256 events plays in the next block")
    func postedMidiBeyondABlock() {
        let engine = makeEngine(Self.dry.merging(["keyup": 1]) { $1 })
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_post_midi(engine, 0x90, 36, 110, 0)
        for _ in 0..<298 { fanfrnoch_post_midi(engine, 0xB0, 1, 0, 0) }    // the mod wheel at rest
        fanfrnoch_post_midi(engine, 0x80, 36, 0, 0)                         // the 300th event
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_sounding_voices(engine) == 1, "the note did not start, or its note-off played in the first block")
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_sounding_voices(engine) == 0, "the note-off was lost")
    }

    @Test("MIDI at a sample offset starts the hit at that sample")
    func sampleOffset() {
        let engine = makeEngine(Self.plain)
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_midi(engine, 0x90, 36, 110, 37)
        let out = render(engine, frames: 128)
        #expect(out[..<37].allSatisfy { $0 == 0 })
        #expect(out[37...].contains { $0 != 0 })
    }

    @Test("Each set keeps its own knobs and program")
    func setsAreSeparate() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let ring = Self.index("ring")
        fanfrnoch_set_plain(engine, 5, ring, 1)
        fanfrnoch_set_program(engine, 3, 2)
        #expect(abs(fanfrnoch_get_plain(engine, Self.keyboard, ring) - 4) < 1e-5)   // stored normalised
        #expect(abs(fanfrnoch_get_plain(engine, 5, ring) - 1) < 1e-5)
        #expect(fanfrnoch_get_program(engine, 3) == 2 && fanfrnoch_get_program(engine, Self.keyboard) == 0)
        #expect(abs(fanfrnoch_get_plain(engine, 3, ring) - 8) < 1e-5)     // Khomus rings 8 s
        fanfrnoch_set_normalised(engine, 16, ring, 0.25)
        #expect(fanfrnoch_get_normalised(engine, 16, ring) == 0.25)
    }

    @Test("Recording a set's program changes no knob")
    func programIndexOnly() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let ring = Self.index("ring")
        fanfrnoch_set_plain(engine, 4, ring, 1)
        fanfrnoch_set_program_index(engine, 4, 2)
        #expect(fanfrnoch_get_program(engine, 4) == 2)
        #expect(abs(fanfrnoch_get_plain(engine, 4, ring) - 1) < 1e-5)
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
        let ring = Self.index("ring")
        for set: Int32 in [-1, 17] {
            fanfrnoch_set_plain(engine, set, ring, 1)
            fanfrnoch_set_normalised(engine, set, ring, 1)
            fanfrnoch_set_program(engine, set, 1)
            #expect(fanfrnoch_get_plain(engine, set, ring) == 0 && fanfrnoch_get_normalised(engine, set, ring) == 0)
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
        #expect(abs(fanfrnoch_get_plain(engine, Self.keyboard, ring) - 4) < 1e-5)

        // A null engine: every call returns quietly.
        var left = [Float](repeating: 1, count: 16)
        fanfrnoch_destroy(nil)
        fanfrnoch_prepare(nil, 48_000); fanfrnoch_reset(nil); fanfrnoch_request_reset(nil)
        fanfrnoch_set_plain(nil, 0, ring, 1); fanfrnoch_set_normalised(nil, 0, ring, 1); fanfrnoch_set_program(nil, 0, 1)
        fanfrnoch_set_mode(nil, 1); fanfrnoch_set_pad_note(nil, 0, 40); fanfrnoch_set_pad_group(nil, 0, 1)
        fanfrnoch_send_to_pad(nil, 0); fanfrnoch_load_default_kit(nil)
        fanfrnoch_post_midi(nil, 0x90, 36, 100, 0); fanfrnoch_midi(nil, 0x90, 36, 100, 0)
        left.withUnsafeMutableBufferPointer { fanfrnoch_process(nil, $0.baseAddress, nil, 16) }
        #expect(left.allSatisfy { $0 == 0 })
        #expect(fanfrnoch_get_plain(nil, 0, ring) == 0 && fanfrnoch_get_program(nil, 0) == 0 && fanfrnoch_get_mode(nil) == 0)
        #expect(fanfrnoch_latency(nil) == 0 && fanfrnoch_sounding_voices(nil) == 0 && fanfrnoch_last_note(nil) == -1)
        #expect(fanfrnoch_pad_note(nil, 0) == -1 && fanfrnoch_pad_group(nil, 0) == 0)

        var info = FanfrnochParamInfo()
        fanfrnoch_param_info(ring, &info)
        fanfrnoch_param_info(-1, &info)
        #expect(info.identifier == nil && info.kind == 0 && info.maxValue == 0)
    }
    // MARK: - Sample rates and oversampling

    /// The fundamental of `x` in Hz: the autocorrelation's highest peak from its first zero
    /// crossing up to 1.5 periods of `expected`, placed between samples by a parabola. The window
    /// keeps out an octave error (half or twice the period) without steering the answer.
    private func fundamental(_ x: [Float], rate: Double, expected: Double) -> Double {
        let maxLag = Int(1.5 * rate / expected)
        let length = x.count - maxLag
        var r = [Float](repeating: 0, count: maxLag + 1)
        x.withUnsafeBufferPointer { signal in
            vDSP_conv(signal.baseAddress!, 1, signal.baseAddress!, 1, &r, 1, vDSP_Length(maxLag + 1), vDSP_Length(length))
        }
        guard let firstNegative = r.firstIndex(where: { $0 < 0 }) else { return 0 }
        var best = firstNegative
        for lag in firstNegative..<maxLag where r[lag] > r[best] { best = lag }
        guard best > firstNegative && best < maxLag else { return rate / Double(best) }
        let a = Double(r[best - 1]), b = Double(r[best]), c = Double(r[best + 1])
        return rate / (Double(best) + 0.5 * (a - c) / (a - 2 * b + c))
    }

    /// Molln (its mouth held still) on note 57, A3, rendered by `engine` at `rate`: its fundamental
    /// from 0.3 s to 0.55 s.
    private func mollnPitch(_ engine: OpaquePointer, rate: Double) -> Double {
        fanfrnoch_midi(engine, 0x90, 57, 110, 0)
        let out = render(engine, seconds: 0.55, at: rate)
        return fundamental(Array(out[Self.frames(0.3, at: rate)...]), rate: rate, expected: 220)
    }

    private func mollnEngine(rate: Double) -> OpaquePointer {
        let engine = makeEngine(rate: rate)
        fanfrnoch_set_program(engine, Self.keyboard, 1)          // Molln: Sweep 0
        return engine
    }

    @Test("The pitch is right at every rate", arguments: [44_100.0, 48_000, 88_200, 96_000, 192_000])
    func pitchAtEveryRate(rate: Double) {
        let engine = mollnEngine(rate: rate)
        defer { fanfrnoch_destroy(engine) }
        let hz = mollnPitch(engine, rate: rate)
        #expect(abs(hz / 220 - 1) < 0.001, "\(rate) Hz: \(hz) Hz")
    }

    /// The share of the power below 20 kHz that lies more than 20 Hz from every harmonic of
    /// `f0`, in dB: what aliasing folds between the harmonics. A Blackman-Harris window over
    /// 0.68 s from 0.2 s into the hit, when Clang (20 ms) has died away.
    private func aliasDb(_ x: [Float], rate: Double, f0: Double) -> Double {
        let log2n = vDSP_Length(rate < 88_200 ? 15 : 16)
        let n = 1 << Int(log2n)
        let start = Self.frames(0.2, at: rate)
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

    // At 48 kHz the voices run at 96 kHz, as they do at a 96 kHz host, and the decimator keeps
    // what would fold back out of the band below 20 kHz.
    @Test("At 48 kHz the bright high note aliases no more than at 96 kHz")
    func aliasing() {
        let bright: [String: Float] = ["edge": 40, "vary": 0, "air": 0, "breath": 0, "puff": 0]
        let f0 = 440 * pow(2, (84 - 69) / 12.0)
        func alias(at rate: Double) -> Double {
            let engine = makeEngine(bright, rate: rate)
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, 84, 110, 0)
            return aliasDb(render(engine, seconds: 1, at: rate), rate: rate, f0: f0)
        }
        let at48 = alias(at: 48_000), at96 = alias(at: 96_000)
        #expect(at48 <= at96 + 3, "48 kHz: \(at48) dB, 96 kHz: \(at96) dB")
    }

    // Below 88.2 kHz the output is the voices at twice the rate, decimated: the same hit at the
    // doubled rate, taken every second sample, lags behind by the decimator's delay. The hit is
    // 37 frames into the block at the host rate and 74 at the doubled rate: the same instant.
    @Test("Latency is the decimator's delay")
    func latency() {
        for rate in [44_100.0, 48_000] {
            let host = makeEngine(Self.plain, rate: rate), doubled = makeEngine(Self.plain, rate: 2 * rate)
            defer { fanfrnoch_destroy(host); fanfrnoch_destroy(doubled) }
            #expect(fanfrnoch_latency(doubled) == 0)
            let latency = Int(fanfrnoch_latency(host))
            #expect(latency == 29, "\(rate) Hz: the 119-tap filter's centre is 59 samples, 29 pairs and one, in")
            fanfrnoch_midi(host, 0x90, 36, 110, 37)
            fanfrnoch_midi(doubled, 0x90, 36, 110, 74)
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

    // A rate change mid-ring starts from silence: the first block is exactly zero, and what is
    // played then is what a fresh engine at that rate plays, sample for sample.
    @Test("Re-preparing changes the rate cleanly")
    func rePrepareChangesRate() {
        let engine = mollnEngine(rate: 96_000)
        defer { fanfrnoch_destroy(engine) }
        #expect(abs(mollnPitch(engine, rate: 96_000) / 220 - 1) < 0.001)
        for rate in [44_100.0, 96_000] {
            fanfrnoch_prepare(engine, rate)                       // the last note still rings
            let first = render(engine, frames: 128)
            #expect(first.allSatisfy { $0 == 0 }, "\(rate) Hz: the first block after prepare")
            let hz = mollnPitch(engine, rate: rate)
            #expect(abs(hz / 220 - 1) < 0.001, "\(rate) Hz: \(hz) Hz")
            fanfrnoch_reset(engine)
            fanfrnoch_midi(engine, 0x90, 57, 110, 0)
            let again = render(engine, seconds: 0.5, at: rate)
            let fresh = mollnEngine(rate: rate)
            defer { fanfrnoch_destroy(fresh) }
            fanfrnoch_midi(fresh, 0x90, 57, 110, 0)
            #expect(again == render(fresh, seconds: 0.5, at: rate), "\(rate) Hz: differs from a fresh engine")
        }
    }

    // Every knob at its minimum, every knob at its maximum (Pan too: one channel is silent), and
    // the sharpest mouth swept to the top on a high note. Each is played from the lowest note to
    // the highest, hard and soft.
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
            ("Reso 40, Vowel 3300 Hz, Sweep +24 st",
             play({ self.setKnobs($0, ["reso": 40, "vowel": 3300, "sweep": 24]) }, notes: [96])),
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

    /// Plays `hits` (note, velocity) at every 32nd note at 120 BPM for 4 s, in `mode`, with Ring
    /// 15 s in every set and every pad's group Off, and checks the pool after every block.
    private func flood(rate: Double, mode: Int32, hits: (Int) -> [(note: Int32, velocity: Int32)]) {
        let engine = makeEngine(rate: rate)
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_set_mode(engine, mode)
        for set: Int32 in 0..<Int32(FANFRNOCH_NUM_SETS) { fanfrnoch_set_plain(engine, set, Self.index("ring"), 15) }
        for pad: Int32 in 0..<Int32(FANFRNOCH_NUM_PADS) { fanfrnoch_set_pad_group(engine, pad, 0) }
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
        // No voice is cut: the biggest step is what sixteen hits starting together make (0.18 at
        // 96 kHz, 0.39 at 44.1 kHz, where a sample is twice as long). Cutting the voices being
        // choked, as a pool of 20 slots must, makes it 0.68 and 0.56.
        let biggestStep = zip(out.dropFirst(), out).map { abs($0 - $1) }.max() ?? 0
        let bound: Float = rate < 88_200 ? 0.45 : 0.25
        #expect(biggestStep <= bound, "\(rate) Hz, \(name): a step of \(biggestStep)")
    }

    // All 16 pads of the default kit, in no group, on every 32nd note, each a little softer than
    // the one before it in turn: at every step sixteen voices start while the sixteen before them
    // are choked: 32 voices in the pool. And the keyboard running up 24 keys, a key per
    // 32nd note: 24 voices would ring.
    @Test("A flood of hits stays within 16 voices", arguments: [44_100.0, 96_000])
    func stealingStaysBounded(rate: Double) {
        flood(rate: rate, mode: Int32(FANFRNOCH_MODE_PADS)) { step in
            (0..<Int32(FANFRNOCH_NUM_PADS)).map { (Int32(FANFRNOCH_FIRST_PAD_NOTE) + $0, Int32(127 - 3 * ((Int($0) + step) % 16))) }
        }
        flood(rate: rate, mode: Int32(FANFRNOCH_MODE_KEYBOARD)) { step in [(Int32(36 + step % 24), Int32(127))] }
    }

    // Keys ring for 15 s while the pads are flooded: the pool of 16 is shared by both origins, so
    // the pads steal keyboard voices and one another, and never more than 16 sound.
    @Test("Pads flooded over ringing keys stay within 16 voices", arguments: [44_100.0, 96_000])
    func mixedFloodStaysBounded(rate: Double) {
        let engine = makeEngine(rate: rate)
        defer { fanfrnoch_destroy(engine) }
        for set: Int32 in 0..<Int32(FANFRNOCH_NUM_SETS) { fanfrnoch_set_plain(engine, set, Self.index("ring"), 15) }
        for pad: Int32 in 0..<Int32(FANFRNOCH_NUM_PADS) { fanfrnoch_set_pad_group(engine, pad, 0) }
        for key: Int32 in 0..<12 { fanfrnoch_midi(engine, 0x90, 48 + key, 100, 0) }       // twelve keys ring
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

    // Sixteen keys ring, the first one soft, and a 17th steals the soft key's voice: what is heard
    // is the soft key damped in 3 ms as the 17th is struck, the other fifteen ringing on.
    @Test("The quietest voice is stolen, with a 3 ms fade")
    func stealsTheQuietest() {
        func play(releasing: Bool) -> [Float] {
            let engine = makeEngine(Self.dry.merging(["ring": 15, "keyup": 1, "damp": 3, "volume": -24]) { $1 })
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, 40, 20, 0)
            for note: Int32 in 41..<56 { fanfrnoch_midi(engine, 0x90, note, 127, 0) }
            var out = render(engine, seconds: 0.2)
            #expect(fanfrnoch_sounding_voices(engine) == 16)
            if releasing { fanfrnoch_midi(engine, 0x80, 40, 0, 0) }
            fanfrnoch_midi(engine, 0x90, 60, 127, 0)
            out += render(engine, seconds: 0.3)
            #expect(fanfrnoch_sounding_voices(engine) == 16)
            return out
        }
        let r = residualDb(play(releasing: false), play(releasing: true))
        #expect(r < -100, "residual \(r) dB")
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

    // MARK: - MIDI controllers

    /// Every knob of every pad's set, normalised.
    private func padSets(_ engine: OpaquePointer) -> [[Float]] {
        (1...Int32(FANFRNOCH_NUM_PADS)).map { set in (0..<fanfrnoch_num_params()).map { fanfrnoch_get_normalised(engine, set, $0) } }
    }

    @Test("A controller moves its keyboard knob: 127 the top, 64 the middle of a bipolar knob; no pad moves")
    func controllerMovesKnob() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        fanfrnoch_set_mode(engine, Int32(FANFRNOCH_MODE_PADS))         // a controller moves the keyboard set in pad mode too
        let pads = padSets(engine)
        let vowel = Self.index("vowel"), pan = Self.index("pan")
        let before = fanfrnoch_changes(engine)

        fanfrnoch_midi(engine, 0xB0, 74, 127, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, vowel) == 1)
        #expect(abs(fanfrnoch_get_plain(engine, Self.keyboard, vowel) - 3300) < 0.5)
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
        func ringing() -> OpaquePointer {
            let engine = makeEngine(Self.plain)
            fanfrnoch_midi(engine, 0x90, 36, 120, 0)
            _ = render(engine, seconds: 0.1)
            return engine
        }
        let atOffset = ringing(), split = ringing(), atStart = ringing(), untouched = ringing()
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
        let stroke = Self.index("stroke")
        let engine = makeEngine(Self.plain)                        // Stroke Out
        defer { fanfrnoch_destroy(engine) }
        let cc = fanfrnoch_get_controller(engine, stroke)
        fanfrnoch_midi(engine, 0x90, 36, 110, 20)
        fanfrnoch_midi(engine, 0xB0, cc, 64, 10)                      // Stroke In, before the note
        let played = render(engine, frames: 4_096)

        let reference = makeEngine(Self.plain.merging(["stroke": 1]) { $1 })
        defer { fanfrnoch_destroy(reference) }
        fanfrnoch_midi(reference, 0x90, 36, 110, 20)
        #expect(played == render(reference, frames: 4_096))
    }

    @Test("A knob that learns takes the next controller that moves, and its value")
    func learnTakesNextCC() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let edge = Self.index("edge")
        let standard = fanfrnoch_standard_controller(edge)
        #expect(fanfrnoch_learning(engine) == -1)
        fanfrnoch_learn(engine, edge)
        #expect(fanfrnoch_learning(engine) == edge)
        let before = fanfrnoch_changes(engine)

        fanfrnoch_midi(engine, 0xB3, 40, 127, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_learning(engine) == -1)
        #expect(fanfrnoch_get_controller(engine, edge) == 40)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, edge) == 1)
        #expect(fanfrnoch_changes(engine) != before)

        fanfrnoch_midi(engine, 0xB0, standard, 0, 0)                 // the one it came with moves it no more
        fanfrnoch_midi(engine, 0xB0, 41, 0, 0)                       // nor does the next one: learning is over
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, edge) == 1)
        #expect(fanfrnoch_get_controller(engine, edge) == 40)

        fanfrnoch_learn(engine, edge)
        fanfrnoch_learn(engine, -1)                                   // called off
        fanfrnoch_midi(engine, 0xB0, 42, 0, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_controller(engine, edge) == 40)
        for param: Int32 in [Int32(fanfrnoch_lfo_amount(0, Self.index("vowel"))), fanfrnoch_num_params(), -2] {
            fanfrnoch_learn(engine, param)                            // an amount, or no parameter: nobody learns
            #expect(fanfrnoch_learning(engine) == -1)
        }
    }

    @Test("A reserved controller is not given to a knob, and does not end a learn")
    func reservedNotTaken() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let edge = Self.index("edge")
        let standard = fanfrnoch_standard_controller(edge)
        let reserved: [Int32] = [0, 1, 6, 32, 38, 64] + Array(96...101) + Array(120...127)
        for controller in reserved {
            #expect(fanfrnoch_controller_reserved(controller) == 1, "CC \(controller)")
            fanfrnoch_set_controller(engine, edge, controller)
            #expect(fanfrnoch_get_controller(engine, edge) == standard, "CC \(controller)")
        }
        #expect(fanfrnoch_controller_reserved(-1) == 1 && fanfrnoch_controller_reserved(128) == 1)
        fanfrnoch_set_controller(engine, edge, 128)
        #expect(fanfrnoch_get_controller(engine, edge) == standard)

        fanfrnoch_learn(engine, edge)
        for controller in reserved where ![120, 121, 123].contains(controller) { fanfrnoch_midi(engine, 0xB0, controller, 100, 0) }
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_learning(engine) == edge)
        #expect(fanfrnoch_get_controller(engine, edge) == standard)
    }

    @Test("One controller serves one knob")
    func oneControllerOneKnob() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        let edge = Self.index("edge"), vowel = Self.index("vowel")
        fanfrnoch_set_controller(engine, edge, 74)                    // Vowel's
        #expect(fanfrnoch_get_controller(engine, edge) == 74)
        #expect(fanfrnoch_get_controller(engine, vowel) == -1)
        let vowelBefore = fanfrnoch_get_normalised(engine, Self.keyboard, vowel)
        fanfrnoch_midi(engine, 0xB0, 74, 127, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, edge) == 1)
        #expect(fanfrnoch_get_normalised(engine, Self.keyboard, vowel) == vowelBefore)

        fanfrnoch_learn(engine, vowel)                                // learnt back
        fanfrnoch_midi(engine, 0xB0, 74, 0, 0)
        _ = render(engine, frames: 128)
        #expect(fanfrnoch_get_controller(engine, vowel) == 74 && fanfrnoch_get_controller(engine, edge) == -1)

        fanfrnoch_set_controller(engine, vowel, -1)
        #expect(fanfrnoch_get_controller(engine, vowel) == -1)
        fanfrnoch_reset_controllers(engine)
        for knob: Int32 in 0..<34 {
            #expect(fanfrnoch_get_controller(engine, knob) == fanfrnoch_standard_controller(knob))
        }
    }

    @Test("Controllers nobody listens to, a changed map and a learn called off leave the sound bit for bit")
    func sameSoundWithoutCC() {
        let score = PrototypeScores.phrase(note: 36)
        func play(_ engine: OpaquePointer, noise: Bool) -> [Float] {
            var out: [Float] = []
            var next = 0
            for block in 0..<Self.frames(3) / 128 {
                let start = block * 128
                while next < score.hits.count, Int(Double(score.hits[next].frame) / PrototypeScores.sampleRate * Self.rate) < start + 128 {
                    let hit = score.hits[next]
                    let offset = Int32(max(0, Int(Double(hit.frame) / PrototypeScores.sampleRate * Self.rate) - start))
                    fanfrnoch_midi(engine, hit.chokeOnly ? 0x80 : 0x90, Int32(hit.note), Int32(hit.chokeOnly ? 0 : hit.velocity), offset)
                    next += 1
                }
                if noise {
                    for controller: Int32 in [3, 40, 105, 119, 0, 6, 64, 127] { fanfrnoch_midi(engine, 0xB0, controller, Int32(block % 128), Int32(block % 128)) }
                }
                out += render(engine, frames: 128)
            }
            return out
        }
        let quiet = makeEngine()
        defer { fanfrnoch_destroy(quiet) }
        let busy = makeEngine()
        defer { fanfrnoch_destroy(busy) }
        fanfrnoch_set_controller(busy, Self.index("edge"), 74)
        fanfrnoch_set_controller(busy, Self.index("ring"), -1)
        fanfrnoch_reset_controllers(busy)
        fanfrnoch_learn(busy, Self.index("ring"))
        fanfrnoch_learn(busy, -1)
        let before = fanfrnoch_changes(busy)
        #expect(play(busy, noise: true) == play(quiet, noise: false))
        #expect(fanfrnoch_changes(busy) == before)
    }

    @Test("The controller calls tolerate a null engine and parameters out of range")
    func controllersOutOfRange() {
        let engine = makeEngine()
        defer { fanfrnoch_destroy(engine) }
        for param: Int32 in [-1, fanfrnoch_num_params(), Int32(fanfrnoch_vel_amount(Self.index("ring")))] {
            #expect(fanfrnoch_standard_controller(param) == -1)
            fanfrnoch_set_controller(engine, param, 40)
            #expect(fanfrnoch_get_controller(engine, param) == -1)
        }
        fanfrnoch_set_controller(nil, 0, 40); fanfrnoch_reset_controllers(nil); fanfrnoch_learn(nil, 0)
        #expect(fanfrnoch_get_controller(nil, 0) == -1 && fanfrnoch_learning(nil) == -1 && fanfrnoch_changes(nil) == 0)
    }
}
