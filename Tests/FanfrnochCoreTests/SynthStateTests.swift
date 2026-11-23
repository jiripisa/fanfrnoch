import Foundation
import Testing
@testable import FanfrnochCore

/// What is saved of a Fanfrnoch: read back whole, written back whole, or in part.
@Suite("Synth state")
struct SynthStateTests {

    private func vowel() throws -> Parameter { try #require(Parameters.named("vowel")) }
    private func ring() throws -> Parameter { try #require(Parameters.named("ring")) }

    @Test("A state goes through JSON and into a fresh synth unchanged")
    func roundTrip() throws {
        let source = Synth(sampleRate: 48_000)
        let vowel = try vowel(), ring = try ring()
        source.setValue(700, of: vowel)
        source.setValue(3.5, of: ring)
        source.loadProgram(2, into: .pad(7))
        for (pad, hz) in [(0, 500.0), (7, 1_100), (15, 1_900)] {
            source.setValue(Float(hz), of: vowel, in: .pad(pad))
            source.setValue(Float(pad) / 4, of: ring, in: .pad(pad))
        }
        source.setPadNote(50, pad: 0)
        source.setPadNote(73, pad: 7)
        source.setPadNote(12, pad: 15)
        source.setPadGroup(nil, pad: 0)
        source.setPadGroup(9, pad: 7)
        source.setPadGroup(16, pad: 15)
        source.mode = .pads

        let saved = source.state
        let data = try JSONEncoder().encode(saved)
        let loaded = try JSONDecoder().decode(SynthState.self, from: data)
        #expect(loaded == saved)

        let target = Synth(sampleRate: 48_000)
        target.apply(loaded)
        #expect(target.state == saved)
        #expect(target.mode == .pads)
        #expect(target.padNote(7) == 73 && target.padGroup(7) == 9 && target.padGroup(0) == nil)
        #expect(abs(target.value(of: vowel, in: .pad(7)) - 1_100) < 1)
        #expect(target.program(in: .pad(7)) == 2)
    }

    @Test("The state holds the keyboard, sixteen pads and every knob by its identifier")
    func shape() {
        let state = Synth().state
        #expect(state.pads.count == 16)
        #expect(Set(state.keyboard.values.keys) == Set(Parameters.all.map(\.identifier)))
        #expect(state.pads.allSatisfy { $0.set.values.count == Parameters.all.count })
    }

    @Test("A name this version does not know is ignored; a knob the state lacks takes its program's value")
    func unknownAndMissingKeys() throws {
        let synth = Synth(sampleRate: 48_000)
        let vowel = try vowel(), ring = try ring()
        synth.setValue(900, of: vowel)
        synth.setValue(4, of: ring)
        var state = synth.state
        state.keyboard.values["from-the-future"] = 1
        state.keyboard.values["vowel"] = 600
        state.keyboard.values["ring"] = nil
        state.pads[3].set.values["from-the-future"] = 1

        synth.apply(state)
        #expect(abs(synth.value(of: vowel) - 600) < 1)
        let programRing = Programs.value(program: state.keyboard.program, parameter: ring)
        #expect(abs(synth.value(of: ring) - programRing) < 1e-4)

        // The same when the state's program differs: the missing knob is that program's.
        synth.setValue(4, of: ring)
        state.keyboard.program = (synth.program() + 1) % 3
        synth.apply(state)
        #expect(synth.program() == state.keyboard.program)
        #expect(abs(synth.value(of: ring) - Programs.value(program: state.keyboard.program, parameter: ring)) < 1e-4)
    }

    @Test("A state of 30 knobs takes the program's values for the other four, the octave included")
    func thirtyKnobState() throws {
        let synth = Synth(sampleRate: 48_000)
        let program = 3
        let kept = Set(Parameters.all.prefix(30).map(\.identifier))
        #expect(kept.count == 30 && Parameters.all.count > 30)
        var set = SetState(program: program, values: [:])
        for parameter in Parameters.all.prefix(30) { set.values[parameter.identifier] = parameter.defaultValue }
        for parameter in Parameters.all { synth.setValue(parameter.range.upperBound, of: parameter) }

        synth.apply(set, to: .keyboard)
        for parameter in Parameters.all {
            let expected = kept.contains(parameter.identifier)
                ? parameter.defaultValue : Programs.value(program: program, parameter: parameter)
            #expect(abs(synth.value(of: parameter) - expected) < 1e-3, "\(parameter.identifier)")
        }
    }

    @Test("A set's preset name survives JSON, and a set saved without one reads as none")
    func presetName() throws {
        let set = SetState(program: 2, values: ["vowel": 600], preset: "Mine")
        let data = try JSONEncoder().encode(set)
        #expect(try JSONDecoder().decode(SetState.self, from: data) == set)
        #expect(try JSONDecoder().decode(SetState.self, from: Data(#"{"program":2}"#.utf8)).preset == nil)
    }

    @Test("Fewer than sixteen pads leave the rest alone")
    func fewerPads() throws {
        let synth = Synth(sampleRate: 48_000)
        synth.setPadNote(70, pad: 12)
        synth.setPadGroup(5, pad: 12)
        let before = synth.state
        var state = before
        state.pads = Array(state.pads.prefix(2))
        state.pads[1].note = 99
        state.mode = .pads

        synth.apply(state)
        #expect(synth.padNote(1) == 99)
        #expect(synth.padNote(12) == 70 && synth.padGroup(12) == 5)
        #expect(synth.state.pads[2...] == before.pads[2...])
        synth.apply(SynthState(mode: .keyboard, keyboard: before.keyboard, pads: []))
        #expect(synth.mode == .keyboard && synth.padNote(1) == 99)
    }

    /// A state as saved JSON, changed by hand the way an older or a newer version would have
    /// written it, and read back.
    private func decode(_ state: SynthState, changing change: (inout [String: Any]) throws -> Void) throws -> SynthState {
        var object = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        try change(&object)
        return try JSONDecoder().decode(SynthState.self, from: JSONSerialization.data(withJSONObject: object))
    }

    @Test("A saved state without the mode reads as keyboard mode and keeps the rest")
    func decodesWithoutMode() throws {
        let synth = Synth(sampleRate: 48_000)
        synth.mode = .pads
        synth.setPadNote(70, pad: 4)
        let saved = synth.state

        let loaded = try decode(saved) { $0["mode"] = nil }
        #expect(loaded.mode == .keyboard)
        #expect(loaded.keyboard == saved.keyboard)
        #expect(loaded.pads == saved.pads)
    }

    @Test("A field this version does not know is ignored, at every level")
    func decodesWithUnknownFields() throws {
        let saved = Synth(sampleRate: 48_000).state
        let loaded = try decode(saved) { object in
            object["kitName"] = "From the future"
            var keyboard = try #require(object["keyboard"] as? [String: Any])
            keyboard["midiMappings"] = [1, 2, 3]
            object["keyboard"] = keyboard
            var pads = try #require(object["pads"] as? [[String: Any]])
            pads[2]["colour"] = "aurora"
            object["pads"] = pads
        }
        #expect(loaded == saved)
    }

    @Test("A pad saved without its group reads as Off and keeps its note and sound")
    func decodesPadWithoutGroup() throws {
        let synth = Synth(sampleRate: 48_000)
        synth.setPadGroup(5, pad: 3)
        let saved = synth.state

        let loaded = try decode(saved) { object in
            var pads = try #require(object["pads"] as? [[String: Any]])
            pads[3]["group"] = nil
            object["pads"] = pads
        }
        #expect(loaded.pads[3].group == nil)
        #expect(loaded.pads[3].note == saved.pads[3].note)
        #expect(loaded.pads[3].set == saved.pads[3].set)
        #expect(loaded.pads[4] == saved.pads[4])
    }

    @Test("Every field may be missing: each gets its default")
    func decodesEmptyParts() throws {
        let empty = try JSONDecoder().decode(SynthState.self, from: Data(#"{"pads": [{"set": {}}, {}]}"#.utf8))
        let noSet = SetState(program: 0, values: [:])
        #expect(empty == SynthState(mode: .keyboard, keyboard: noSet,
                                    pads: [PadState(note: 36, group: nil, set: noSet),
                                           PadState(note: 36, group: nil, set: noSet)]))
    }

    @Test("The mode is saved as its number")
    func modeIsItsRawValue() throws {
        #expect(String(data: try JSONEncoder().encode([PlayMode.pads]), encoding: .utf8) == "[1]")
        #expect(try JSONDecoder().decode([PlayMode].self, from: Data("[0]".utf8)) == [.keyboard])
    }

    @Test("A synth that borrows an engine plays through it and leaves it alive")
    func borrowing() {
        let owner = Synth(sampleRate: 48_000)
        do {
            let borrower = Synth(borrowing: owner.engine)
            borrower.mode = .pads
            borrower.noteOn(36)
        }
        #expect(owner.mode == .pads)
        var out = [Float](repeating: 0, count: 256)
        out.withUnsafeMutableBufferPointer { owner.render(left: $0.baseAddress!, right: nil, frames: 256) }
        #expect(owner.padHits(0) == 1)
    }
}
