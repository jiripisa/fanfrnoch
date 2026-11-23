import Foundation
import Synchronization
import Testing
@testable import FanfrnochCore

/// The engine's thread rules: the audio thread renders while any other thread changes knobs,
/// programs, the mode, the pads and the controllers, learns, and posts MIDI (controllers that
/// move the knobs among it). Run under `swift test --sanitize=thread`.
@Suite("Threads")
struct ThreadTests {

    private final class Control: Sendable {
        let stop = Mutex(false)
        let operations = Atomic<Int>(0)
        let finished = DispatchSemaphore(value: 0)
    }

    /// A small deterministic generator: the control thread's choices repeat from run to run.
    private struct Lcg {
        var state: UInt64
        mutating func next(_ bound: Int) -> Int {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 33) % UInt64(bound))
        }
    }

    @Test("Rendering stays finite while another thread plays with everything")
    func controlWhileRendering() {
        let rate = 48_000.0, block = 128
        let synth = Synth(sampleRate: rate)
        let control = Control()
        let programs = Programs.names.count, parameters = Parameters.all

        let thread = Thread {
            var random = Lcg(state: 0x5EED)
            while !control.stop.withLock({ $0 }) {
                let set: SoundSet = random.next(3) == 0 ? .keyboard : .pad(random.next(16))
                switch random.next(12) {
                case 0, 1, 2:
                    synth.setNormalisedValue(Float(random.next(1001)) / 1000, of: parameters[random.next(parameters.count)], in: set)
                case 3: synth.loadProgram(random.next(programs), into: set)
                case 4: synth.mode = random.next(2) == 0 ? .keyboard : .pads
                case 5: synth.setPadNote(random.next(128), pad: random.next(16))
                case 6: synth.setPadGroup(random.next(5) == 0 ? nil : 1 + random.next(16), pad: random.next(16))
                case 7: synth.sendToPad(random.next(16))
                case 8: synth.postMIDI(status: 0xB0, data1: UInt8(random.next(128)), data2: UInt8(random.next(128)))
                case 9: synth.setController(random.next(4) == 0 ? nil : random.next(128), of: parameters[random.next(parameters.count)])
                case 10:
                    switch random.next(3) {
                    case 0: synth.learn(parameters[random.next(parameters.count)])
                    case 1: synth.learn(nil)
                    default: synth.resetControllers()
                    }
                default:
                    let note = random.next(2) == 0 ? 36 + random.next(16) : random.next(128)
                    if random.next(3) == 0 { synth.noteOff(note) } else { synth.noteOn(note, velocity: 1 + random.next(127)) }
                }
                control.operations.add(1, ordering: .relaxed)
            }
            control.finished.signal()
        }
        thread.start()
        while control.operations.load(ordering: .relaxed) < 50 { Thread.sleep(forTimeInterval: 0.001) }
        let before = control.operations.load(ordering: .relaxed)

        var left = [Float](repeating: 0, count: block), right = [Float](repeating: 0, count: block)
        var finite = true, loud = false
        for _ in 0..<Int(1 * rate) / block {
            left.withUnsafeMutableBufferPointer { l in
                right.withUnsafeMutableBufferPointer { r in
                    synth.render(left: l.baseAddress!, right: r.baseAddress!, frames: block)
                }
            }
            finite = finite && left.allSatisfy { $0.isFinite } && right.allSatisfy { $0.isFinite }
            loud = loud || left.contains { $0 != 0 }
        }
        let during = control.operations.load(ordering: .relaxed) - before
        control.stop.withLock { $0 = true }
        control.finished.wait()                 // the control thread has ended
        #expect(finite, "NaN or Inf while the controls changed")
        #expect(loud, "the test heard nothing")
        #expect(during >= 50, "the control thread made only \(during) changes while audio rendered")
    }
}
