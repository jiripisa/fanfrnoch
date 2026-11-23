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

    /// Out, no randomness.
    static var plain: [String: Float] { ["stroke": 0, "vary": 0, "air": 0] }

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
}
