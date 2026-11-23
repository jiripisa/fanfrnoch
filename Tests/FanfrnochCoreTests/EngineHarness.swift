import Accelerate
import Foundation
import FanfrnochDSP
@testable import FanfrnochCore

/// What the engine's test suites share: a fresh engine (at 96 kHz unless a test names another
/// rate), renders in blocks of 128 frames, and the measures they compare renders with. A suite
/// conforms to use them.
protocol EngineHarness {}

extension EngineHarness {

    static var rate: Double { 96_000 }
    static var keyboard: Int32 { Int32(FANFRNOCH_KEYBOARD_SET) }

    /// The engine's output scale (`kLevel` in FanfrnochEngine.cpp) against the prototype's units.
    static var level: Double { 0.32 }

    /// No randomness: no Vary, Wobble, Shimmer, Rub or Scrape.
    static var plain: [String: Float] { ["vary": 0, "wobble": 0, "shimmer": 0, "rub": -40, "scrape": 0] }

    /// A steady stroke: no randomness, no Drift, a hand that rubs for 2 s.
    static var steady: [String: Float] { plain.merging(["drift": 0, "length": 2000]) { $1 } }

    static func index(_ identifier: String) -> Int32 {
        guard let parameter = Parameters.named(identifier) else { preconditionFailure("unknown knob \(identifier)") }
        return Int32(parameter.index)
    }

    static func frames(_ seconds: Double, at rate: Double = rate) -> Int { Int((seconds * rate).rounded()) }

    /// Puts `knobs` (plain values) into `set`.
    func setKnobs(_ engine: OpaquePointer, _ knobs: [String: Float], set: Int32 = Int32(FANFRNOCH_KEYBOARD_SET)) {
        for (key, value) in knobs { fanfrnoch_set_plain(engine, set, Self.index(key), value) }
    }

    /// A fresh engine at `rate` in keyboard mode, with `knobs` (plain values) in the keyboard set.
    func makeEngine(_ knobs: [String: Float] = [:], rate: Double = Self.rate) -> OpaquePointer {
        let engine = fanfrnoch_create()!
        fanfrnoch_prepare(engine, rate)
        fanfrnoch_reset(engine)
        fanfrnoch_set_mode(engine, Int32(FANFRNOCH_MODE_KEYBOARD))
        setKnobs(engine, knobs)
        return engine
    }

    /// Renders `frames` of the left channel in blocks of 128 frames.
    func render(_ engine: OpaquePointer, frames: Int) -> [Float] {
        var out = [Float](repeating: 0, count: frames)
        var start = 0
        out.withUnsafeMutableBufferPointer { buffer in
            while start < frames {
                let count = min(128, frames - start)
                fanfrnoch_process(engine, buffer.baseAddress! + start, nil, Int32(count))
                start += count
            }
        }
        return out
    }

    func render(_ engine: OpaquePointer, seconds: Double, at rate: Double = Self.rate) -> [Float] {
        render(engine, frames: Self.frames(seconds, at: rate))
    }

    /// Renders `frames` of both channels in blocks of 128 frames.
    func renderStereo(_ engine: OpaquePointer, frames: Int) -> (left: [Float], right: [Float]) {
        var left = [Float](repeating: 0, count: frames), right = [Float](repeating: 0, count: frames)
        var start = 0
        left.withUnsafeMutableBufferPointer { l in
            right.withUnsafeMutableBufferPointer { r in
                while start < frames {
                    let count = min(128, frames - start)
                    fanfrnoch_process(engine, l.baseAddress! + start, r.baseAddress! + start, Int32(count))
                    start += count
                }
            }
        }
        return (left, right)
    }

    func rms<C: Collection>(_ x: C) -> Double where C.Element == Float {
        (x.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(max(x.count, 1))).squareRoot()
    }

    /// dB of (a - b) re b.
    func residualDb<A: Collection, B: Collection>(_ a: A, _ b: B) -> Double where A.Element == Float, B.Element == Float {
        var difference = 0.0, signal = 0.0
        for (x, y) in zip(a, b) { difference += Double(x - y) * Double(x - y); signal += Double(y) * Double(y) }
        return 10 * log10(difference / signal)
    }

    /// The fundamental of `x` in Hz: the autocorrelation's highest peak from its first zero
    /// crossing up to 1.5 periods of `expected`, placed between samples by a parabola. The window
    /// keeps out an octave error (half or twice the period) without steering the answer.
    func fundamental(_ x: [Float], rate: Double, expected: Double) -> Double {
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
}
