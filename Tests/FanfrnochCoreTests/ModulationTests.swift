import Accelerate
import Foundation
import Testing
import FanfrnochDSP
@testable import FanfrnochCore

/// What moves the knobs while the instrument plays: the velocity's amounts, the two LFOs, the
/// knobs themselves turned while a key rings, and the wheels.
@Suite("Modulation")
struct ModulationTests: EngineHarness {

    /// A fresh engine with `plain` and then `knobs` in the keyboard set: every render here starts
    /// from Out and no randomness unless the test says otherwise.
    private func plainEngine(_ knobs: [String: Float] = [:]) -> OpaquePointer {
        makeEngine(Self.plain.merging(knobs) { $1 })
    }

    /// One hit of C2 at `velocity` on a fresh engine with `knobs`; `before` runs just before the
    /// note-on (for MIDI that sets the wheels).
    private func hit(_ knobs: [String: Float] = [:], velocity: Int32 = 110, seconds: Double = 1.5,
                     before: (OpaquePointer) -> Void = { _ in }) -> [Float] {
        let engine = plainEngine(knobs)
        defer { fanfrnoch_destroy(engine) }
        before(engine)
        fanfrnoch_midi(engine, 0x90, 36, velocity, 0)
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

    @Test("A VEL amount moves a soft hit exactly as far as turning the knob down would")
    func velMatchesKnob() {
        let n0: Float = 0.6                                  // Vowel's position at a full hit
        let vowel = Self.index("vowel")
        let moved = hit(["velvowel": 60], velocity: 64) { fanfrnoch_set_normalised($0, Self.keyboard, vowel, n0) }
        let turned = hit(velocity: 64) {
            fanfrnoch_set_normalised($0, Self.keyboard, vowel, n0 - 0.6 * (1 - 64.0 / 127.0))
        }
        let unmoved = hit(velocity: 64) { fanfrnoch_set_normalised($0, Self.keyboard, vowel, n0) }
        let r = residualDb(moved, turned)
        #expect(r < -100, "residual \(r) dB")
        #expect(residualDb(moved, unmoved) > -40)            // and the amount did move it
    }

    @Test("A full-velocity hit ignores its VEL amounts")
    func velAtFull() {
        #expect(hit(["velring": 100], velocity: 127) == hit(velocity: 127))
    }

    @Test("VEL>Volume scales the level")
    func velVolume() {
        let soft = hit(["velsens": 0, "velvolume": 100], velocity: 64)
        let full = hit(["velsens": 0, "velvolume": 100], velocity: 127)
        let scaled = full.map { $0 * (64.0 / 127.0) }
        let r = residualDb(soft, scaled)
        #expect(r < -100, "residual \(r) dB")
    }

    // MARK: - LFOs

    /// Two hits `gap` seconds apart, each heard for the first second. Ring 0.3 s and the bus
    /// silent again (exactly 0) before the second hit, so that nothing of the first is left in it.
    /// LFO 1 moves the Vowel (a sine), LFO 2 the Close (Steps, which draws random levels).
    private func twoHits(start: Float, gap: Double) -> (first: ArraySlice<Float>, second: ArraySlice<Float>) {
        let engine = plainEngine(["ring": 0.3, "lfostart": start,
                                 "lfo1rate": 3, "lfo1vowel": 40,
                                 "lfo2rate": 5, "lfo2shape": 5, "lfo2close": 50])
        defer { fanfrnoch_destroy(engine) }
        let second = Self.frames(gap)
        fanfrnoch_midi(engine, 0x90, 36, 110, 0)
        var out = render(engine, frames: second)
        #expect(out[(second - 128)...].allSatisfy { $0 == 0 }, "the first hit is not silent yet")
        fanfrnoch_midi(engine, 0x90, 36, 110, 0)
        out += render(engine, seconds: 1)
        let one = Self.frames(1)
        return (out[0..<one], out[second..<(second + one)])
    }

    // 2.1 s and not 2 s apart: at 3 Hz, 2 s is a whole number of cycles, so a free-running LFO
    // would come round to the same phase and the two tests could not tell Hit from Free.
    @Test("With LFO Start = Hit every hit repeats exactly")
    func lfoHitRepeats() {
        let hits = twoHits(start: 0, gap: 2.1)
        #expect(Array(hits.first) == Array(hits.second))
    }

    @Test("With LFO Start = Free hits differ")
    func lfoFree() {
        let hits = twoHits(start: 1, gap: 2.1)
        let r = residualDb(hits.second, hits.first)
        #expect(r > -30, "residual \(r) dB")
    }

    @Test("An LFO amount moves the sound; amount 0 leaves it alone")
    func lfoAmount() {
        let still = hit()
        let moving = hit(["lfo1rate": 3, "lfo1vowel": 40])
        #expect(residualDb(moving, still) > -30)
        // Rates, shapes and the start do nothing while every amount is 0.
        let idle = hit(["lfo1rate": 20, "lfo1shape": 4, "lfo2rate": 0.1, "lfo2shape": 6, "lfostart": 1])
        #expect(idle == still)
    }

    // MARK: - Live knobs and wheels

    // With the vowel held still and the throat and the buzz turned down, the vowel resonance
    // carries the sound, which Close shuts. With the defaults it carries little of it 0.5 s into
    // a hit: the vowel has swept up to 1.8 kHz, and closing it then takes 0.3 dB off.
    @Test("A keyboard voice follows the knobs while it rings")
    func liveKnobs() {
        func play(closeAtHalf: Bool) -> [Float] {
            let engine = plainEngine(["sweep": 0, "throat": -30, "buzz": 0])
            defer { fanfrnoch_destroy(engine) }
            fanfrnoch_midi(engine, 0x90, 36, 110, 0)
            var out = render(engine, seconds: 0.5)
            if closeAtHalf { fanfrnoch_set_plain(engine, Self.keyboard, Self.index("close"), 100) }
            out += render(engine, seconds: 0.5)
            return out
        }
        let half = Self.frames(0.5)
        let open = play(closeAtHalf: false), closed = play(closeAtHalf: true)
        #expect(open[..<half] == closed[..<half])
        let drop = 20 * log10(rms(closed[half...]) / rms(open[half...]))
        #expect(drop < -6, "the next 0.5 s changed by \(drop) dB")
    }

    @Test("Pitch bend moves the vowel up")
    func bendMovesVowel() {
        let window = Self.frames(0.2)..<Self.frames(1.0)
        let level = hit(["sweep": 0])
        let bent = hit(["sweep": 0]) { fanfrnoch_midi($0, 0xE0, 0x7F, 0x7F, 0) }   // full up: +1
        let flat = spectralCentroid(level[window]), up = spectralCentroid(bent[window])
        #expect(up > flat * 1.1, "centroid \(flat) Hz -> \(up) Hz")
    }

    @Test("The mod wheel closes the mouth and aftertouch adds breath")
    func wheels() {
        // The mod wheel at the top adds the whole travel of Close: as Close at 100 %.
        let wheel = hit { fanfrnoch_midi($0, 0xB0, 1, 127, 0) }
        #expect(wheel == hit(["close": 100]))
        #expect(wheel != hit())
        // Full pressure adds +100 % of Breath: from 0 % to 100 %.
        let pressed = hit(["breath": 0]) { fanfrnoch_midi($0, 0xD0, 127, 0, 0) }
        #expect(pressed == hit(["breath": 100]))
        #expect(pressed != hit(["breath": 0]))
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
