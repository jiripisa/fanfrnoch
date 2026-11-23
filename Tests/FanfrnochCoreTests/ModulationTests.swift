import Accelerate
import Foundation
import Testing
import FanfrnochDSP
@testable import FanfrnochCore

/// What moves the knobs while the instrument plays: the velocity's amounts, the two LFOs, the
/// knobs themselves turned while a stroke sounds, and the wheels.
@Suite("Modulation")
struct ModulationTests: EngineHarness {

    /// A fresh engine with `plain` and then `knobs` in the keyboard set: every render here starts
    /// from no randomness unless the test says otherwise.
    private func plainEngine(_ knobs: [String: Float] = [:]) -> OpaquePointer {
        makeEngine(Self.plain.merging(knobs) { $1 })
    }

    /// One stroke of B2 at `velocity` on a fresh engine with `knobs`; `before` runs just before the
    /// note-on (for MIDI that sets the wheels).
    private func hit(_ knobs: [String: Float] = [:], velocity: Int32 = 110, seconds: Double = 1.5,
                     before: (OpaquePointer) -> Void = { _ in }) -> [Float] {
        let engine = plainEngine(knobs)
        defer { fanfrnoch_destroy(engine) }
        before(engine)
        fanfrnoch_midi(engine, 0x90, 47, velocity, 0)
        return render(engine, seconds: seconds)
    }

    /// The magnitude-weighted mean frequency of `x`, in Hz: Hann-windowed frames of 8192 samples.
    private func spectralCentroid(_ x: ArraySlice<Float>) -> Double {
        let log2n: vDSP_Length = 13
        let n = 1 << Int(log2n)
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { preconditionFailure("no FFT") }
        defer { vDSP_destroy_fftsetup(setup) }
        var window = [Float](repeating: 0, count: n)
        vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_NORM))
        var weighted = 0.0, total = 0.0
        var start = x.startIndex
        while start + n <= x.endIndex {
            let frame = zip(x[start..<(start + n)], window).map { $0 * $1 }
            var real = [Float](repeating: 0, count: n / 2), imag = [Float](repeating: 0, count: n / 2)
            var magnitudes = [Float](repeating: 0, count: n / 2)
            real.withUnsafeMutableBufferPointer { r in
                imag.withUnsafeMutableBufferPointer { i in
                    var split = DSPSplitComplex(realp: r.baseAddress!, imagp: i.baseAddress!)
                    frame.withUnsafeBytes { bytes in
                        vDSP_ctoz(bytes.bindMemory(to: DSPComplex.self).baseAddress!, 2, &split, 1, vDSP_Length(n / 2))
                    }
                    vDSP_fft_zrip(setup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                    magnitudes.withUnsafeMutableBufferPointer { m in
                        vDSP_zvabs(&split, 1, m.baseAddress!, 1, vDSP_Length(n / 2))
                    }
                }
            }
            for bin in 1..<(n / 2) {
                let hz = Double(bin) * Self.rate / Double(n)
                weighted += hz * Double(magnitudes[bin]); total += Double(magnitudes[bin])
            }
            start += n
        }
        return weighted / total
    }

    // MARK: - Velocity

    @Test("A VEL amount moves a soft stroke exactly as far as turning the knob down would")
    func velMatchesKnob() {
        let n0: Float = 0.6                                  // Stick's position at a full stroke
        let stick = Self.index("stick")
        let moved = hit(["velstick": 60], velocity: 64) { fanfrnoch_set_normalised($0, Self.keyboard, stick, n0) }
        let turned = hit(velocity: 64) {
            fanfrnoch_set_normalised($0, Self.keyboard, stick, n0 - 0.6 * (1 - 64.0 / 127.0))
        }
        let unmoved = hit(velocity: 64) { fanfrnoch_set_normalised($0, Self.keyboard, stick, n0) }
        let r = residualDb(moved, turned)
        #expect(r < -100, "residual \(r) dB")
        #expect(residualDb(moved, unmoved) > -40)            // and the amount did move it
    }

    @Test("A full-velocity stroke ignores its VEL amounts")
    func velAtFull() {
        #expect(hit(["velrelease": 100, "velstick": 100], velocity: 127) == hit(velocity: 127))
    }

    @Test("VEL>Volume scales the level")
    func velVolume() {
        // No other way for the velocity into the sound: Vel Sens 0, no darkening with the level.
        let soft = hit(["velsens": 0, "stickvel": 0, "velvolume": 100], velocity: 64)
        let full = hit(["velsens": 0, "stickvel": 0, "velvolume": 100], velocity: 127)
        let scaled = full.map { $0 * (64.0 / 127.0) }
        let r = residualDb(soft, scaled)
        #expect(r < -100, "residual \(r) dB")
    }

    // MARK: - LFOs

    /// Two strokes `gap` seconds apart, each heard for the first second. A short stroke, and the
    /// bus silent again (exactly 0: the voice has retired) before the second, so that nothing of
    /// the first is left in it; no Alternate, so that the second hand plays as the first. LFO 1
    /// moves Stick (a sine), LFO 2 Split (Steps, which draws random levels).
    private func twoHits(start: Float, gap: Double) -> (first: ArraySlice<Float>, second: ArraySlice<Float>) {
        let engine = plainEngine(["length": 100, "release": 0.1, "alternate": 0, "alttune": 0, "lfostart": start,
                                 "lfo1rate": 3, "lfo1stick": 40,
                                 "lfo2rate": 5, "lfo2shape": 5, "lfo2split": 50])
        defer { fanfrnoch_destroy(engine) }
        let second = Self.frames(gap)
        fanfrnoch_midi(engine, 0x90, 47, 110, 0)
        var out = render(engine, frames: second)
        #expect(out[(second - 128)...].allSatisfy { $0 == 0 }, "the first stroke is not silent yet")
        fanfrnoch_midi(engine, 0x90, 47, 110, 0)
        out += render(engine, seconds: 1)
        let one = Self.frames(1)
        return (out[0..<one], out[second..<(second + one)])
    }

    // 2.1 s and not 2 s apart: at 3 Hz, 2 s is a whole number of cycles, so a free-running LFO
    // would come round to the same phase and the two tests could not tell Hit from Free.
    @Test("With LFO Start = Hit every stroke repeats exactly")
    func lfoHitRepeats() {
        let hits = twoHits(start: 0, gap: 2.1)
        #expect(Array(hits.first) == Array(hits.second))
    }

    @Test("With LFO Start = Free strokes differ")
    func lfoFree() {
        let hits = twoHits(start: 1, gap: 2.1)
        let r = residualDb(hits.second, hits.first)
        #expect(r > -30, "residual \(r) dB")
    }

    @Test("An LFO amount moves the sound; amount 0 leaves it alone")
    func lfoAmount() {
        let still = hit()
        let moving = hit(["lfo1rate": 3, "lfo1stick": 40])
        #expect(residualDb(moving, still) > -30)
        // Rates, shapes and the start do nothing while every amount is 0.
        let idle = hit(["lfo1rate": 20, "lfo1shape": 4, "lfo2rate": 0.1, "lfo2shape": 6, "lfostart": 1])
        #expect(idle == still)
    }

    @Test("An LFO on Tune moves the pitch by its share of Tune's travel")
    func lfoOnTune() {
        // LFO 1 a square (+1 for the first half of its cycle) at 0.1 Hz: for the first 5 s it holds
        // Tune 25 % of its 200 cents up, +50 cents.
        let x = hit(Self.steady.merging(["lfo1shape": 4, "lfo1rate": 0.1, "lfo1tune": 25]) { $1 }, seconds: 0.6)
        let hz = fundamental(Array(x[Self.frames(0.3)...]), rate: Self.rate, expected: 127)
        let expected = 440 * pow(2, (47 + 0.5 - 69) / 12)
        #expect(abs(hz / expected - 1) < 0.001, "\(hz) Hz, expected \(expected) Hz")
    }

    // MARK: - Live knobs and wheels

    // Stick turned from 0.88 to 0.5 (a sine) halfway into a long stroke takes the upper harmonics
    // away from there on: the spectrum's centroid falls.
    @Test("A keyboard voice follows the knobs while it sounds")
    func liveKnobs() {
        func play(turnAtHalf: Bool) -> [Float] {
            let engine = plainEngine(["length": 2000])
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, 47, 110, 0)
            var out = render(engine, seconds: 0.5)
            if turnAtHalf { fanfrnoch_set_plain(engine, Self.keyboard, Self.index("stick"), 0.5) }
            out += render(engine, seconds: 0.5)
            return out
        }
        let half = Self.frames(0.5)
        let still = play(turnAtHalf: false), turned = play(turnAtHalf: true)
        #expect(still[..<half] == turned[..<half])
        let before = spectralCentroid(still[half...]), after = spectralCentroid(turned[half...])
        #expect(after < 0.8 * before, "centroid \(before) Hz -> \(after) Hz")
    }

    @Test("Pitch bend bends the drum up by Bend Up and down by Bend Down")
    func bend() {
        let b2 = 440 * pow(2, (47 - 69) / 12.0)
        func pitch(_ lsb: Int32, _ msb: Int32, expected: Double) -> Double {
            let x = hit(Self.steady, seconds: 0.6) { fanfrnoch_midi($0, 0xE0, lsb, msb, 0) }
            return fundamental(Array(x[Self.frames(0.3)...]), rate: Self.rate, expected: expected)
        }
        let up = 2 * b2, down = b2 * pow(2, -2 / 12.0)              // Bend Up 12 st, Bend Down 2 st
        let bentUp = pitch(0x7F, 0x7F, expected: up), bentDown = pitch(0, 0, expected: down)
        #expect(abs(bentUp / up - 1) < 0.001, "full up: \(bentUp) Hz")
        #expect(abs(bentDown / down - 1) < 0.001, "full down: \(bentDown) Hz")
    }

    @Test("The mod wheel adds Rub and aftertouch adds Stick")
    func wheels() {
        // The mod wheel at the top adds half of Rub's travel, 20 dB: from Off (the bottom) to -20 dB.
        let wheel = hit { fanfrnoch_midi($0, 0xB0, 1, 127, 0) }
        #expect(wheel == hit(["rub": -20]))
        #expect(wheel != hit())
        // Full pressure adds 0.07 of Stick: from 0.80 to 0.87.
        let pressed = hit(["stick": 0.80]) { fanfrnoch_midi($0, 0xD0, 127, 0, 0) }
        let r = residualDb(pressed, hit(["stick": 0.87]))
        #expect(r < -100, "residual \(r) dB")
        #expect(pressed != hit(["stick": 0.80]))
    }

    @Test("Reset All Controllers puts the wheels back at rest")
    func resetAllControllers() {
        let reset = hit { engine in
            fanfrnoch_midi(engine, 0xB0, 1, 127, 0)
            fanfrnoch_midi(engine, 0xD0, 127, 0, 0)
            fanfrnoch_midi(engine, 0xE0, 0x7F, 0x7F, 0)
            fanfrnoch_midi(engine, 0xB0, 121, 0, 0)
        }
        #expect(reset == hit())
    }
}
