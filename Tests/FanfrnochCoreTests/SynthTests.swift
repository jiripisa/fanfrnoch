import Testing
import FanfrnochDSP
@testable import FanfrnochCore

/// The Swift wrapper only forwards to the engine: what is set is what is read back, on the right set.
@Suite("Synth")
struct SynthTests {

    private func render(_ synth: Synth, frames: Int = 4_096) -> [Float] {
        var out = [Float](repeating: 0, count: frames)
        out.withUnsafeMutableBufferPointer { synth.render(left: $0.baseAddress!, right: nil, frames: frames) }
        return out
    }

    @Test("A value round-trips, plain and normalised, in the keyboard set and in a pad")
    func valuesRoundTrip() throws {
        let synth = Synth(sampleRate: 48_000)
        let pot = try #require(Parameters.named("pot"))
        for set in [SoundSet.keyboard, .pad(0), .pad(15)] {
            synth.setValue(900, of: pot, in: set)
            #expect(abs(synth.value(of: pot, in: set) - 900) < 0.5)
            synth.setNormalisedValue(0.25, of: pot, in: set)
            #expect(abs(synth.normalisedValue(of: pot, in: set) - 0.25) < 1e-5)
        }
        synth.setValue(pot.range.lowerBound, of: pot, in: .pad(3))
        #expect(synth.value(of: pot, in: .keyboard) != synth.value(of: pot, in: .pad(3)))
        #expect(SoundSet.keyboard.index == 0 && SoundSet.pad(0).index == 1 && SoundSet.pad(15).index == 16)
    }

    /// Every knob of every set (the keyboard, then pads 0...15), normalised, with each set's
    /// program, and every pad's note and group.
    private func everything(_ synth: Synth) -> (knobs: [[Float]], programs: [Int], notes: [Int?], groups: [Int?]) {
        let sets = [SoundSet.keyboard] + (0..<16).map { SoundSet.pad($0) }
        return (sets.map { set in Parameters.all.map { synth.normalisedValue(of: $0, in: set) } },
                sets.map { synth.program(in: $0) },
                (0..<16).map { synth.padNote($0) },
                (0..<16).map { synth.padGroup($0) })
    }

    @Test("Writing one pad's set leaves the other pads and the keyboard set as they were")
    func padSetsApart() throws {
        let synth = Synth()
        let pot = try #require(Parameters.named("pot"))
        let before = everything(synth)
        synth.loadProgram(before.programs[6] == 3 ? 4 : 3, into: .pad(5))
        synth.setValue(pot.range.upperBound, of: pot, in: .pad(5))
        let after = everything(synth)
        for set in after.knobs.indices where set != 6 {
            #expect(after.knobs[set] == before.knobs[set], "set \(set) changed")
            #expect(after.programs[set] == before.programs[set], "the program of set \(set) changed")
        }
        #expect(after.knobs[6] != before.knobs[6] && after.programs[6] != before.programs[6])
        #expect(after.notes == before.notes && after.groups == before.groups)
    }

    @Test("A pad outside 0...15 is ignored: nothing is written, and reading it gives defaults and nil")
    func padsOutOfRange() throws {
        let synth = Synth()
        let pot = try #require(Parameters.named("pot"))
        synth.noteOn(52)                        // what Send to pad would copy
        _ = render(synth)
        let before = everything(synth)
        for pad in [-1, 16, 20] {
            #expect(SoundSet.pad(pad).index == -1)
            synth.setValue(pot.range.lowerBound, of: pot, in: .pad(pad))
            synth.setNormalisedValue(1, of: pot, in: .pad(pad))
            synth.loadProgram(3, into: .pad(pad))
            synth.setPadNote(70, pad: pad)
            synth.setPadGroup(5, pad: pad)
            synth.sendToPad(pad)
            #expect(synth.value(of: pot, in: .pad(pad)) == pot.defaultValue)
            #expect(synth.normalisedValue(of: pot, in: .pad(pad)) == pot.normalised(pot.defaultValue))
            #expect(synth.program(in: .pad(pad)) == 0)
            #expect(synth.padNote(pad) == nil && synth.padGroup(pad) == nil)
        }
        let after = everything(synth)
        #expect(after.knobs == before.knobs && after.programs == before.programs)
        #expect(after.notes == before.notes && after.groups == before.groups)
    }

    @Test("A program loads into its own set")
    func programs() {
        let synth = Synth()
        synth.loadProgram(2, into: .pad(4))
        synth.loadProgram(1)
        #expect(synth.program(in: .pad(4)) == 2)
        #expect(synth.program(in: .keyboard) == 1)
    }

    @Test("The mode, a pad's note and its group round-trip; Off reads back as nil")
    func modeAndPads() {
        let synth = Synth()
        #expect(synth.mode == .keyboard)
        synth.mode = .pads
        #expect(synth.mode == .pads)
        synth.setPadNote(50, pad: 7)
        #expect(synth.padNote(7) == 50)
        synth.setPadGroup(3, pad: 7)
        #expect(synth.padGroup(7) == 3)
        synth.setPadGroup(nil, pad: 7)
        #expect(synth.padGroup(7) == nil)
    }

    @Test("Send to pad copies the last note; the kit loads on demand")
    func sendToPad() {
        let synth = Synth()
        #expect(synth.lastNote == nil)
        synth.noteOn(52)
        _ = render(synth)
        #expect(synth.lastNote == 52)
        synth.sendToPad(9)
        #expect(synth.padNote(9) == 52)
        synth.loadDefaultKit()
        #expect(synth.padNote(9) != 52)
    }

    @Test("Notes above 127 clamp; velocity 0 sounds as velocity 1")
    func clamping() {
        let high = Synth()
        high.noteOn(200)
        _ = render(high)
        #expect(high.lastNote == 127)

        func hit(velocity: Int) -> [Float] {
            let synth = Synth()
            synth.noteOn(60, velocity: velocity)
            return render(synth)
        }
        let silent = hit(velocity: 0)
        #expect(silent == hit(velocity: 1))
        #expect(silent.contains { $0 != 0 })
    }

    @Test("Voices count while sounding and stop after all notes off; the latency is the engine's")
    func voicesAndLatency() throws {
        let synth = Synth(sampleRate: 48_000)
        #expect(synth.latency == Int(fanfrnoch_latency(synth.engine)) && synth.latency > 0)
        synth.setValue(1, of: try #require(Parameters.named("drum")))        // Many: two notes, two drums
        synth.noteOn(48)
        synth.noteOn(55)
        _ = render(synth, frames: 512)
        #expect(synth.soundingVoices == 2)
        synth.allNotesOff()
        _ = render(synth, frames: 512)
        #expect(synth.soundingVoices == 0)
        synth.prepare(sampleRate: 96_000)
        #expect(synth.latency == 0)
    }
}
