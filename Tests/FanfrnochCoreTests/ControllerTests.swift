import Foundation
import Testing
@testable import FanfrnochCore

/// MIDI controllers on the keyboard set's knobs: each knob comes with one, a control change moves
/// the knob, and a knob can be taught another.
@Suite("Controllers")
struct ControllerTests {

    private func knob(_ identifier: String) throws -> Parameter { try #require(Parameters.named(identifier)) }

    /// The 34 knobs, in table order.
    private static let knobs = ParameterSection.all.flatMap(\.parameters).sorted { $0.index < $1.index }

    /// Lets the engine take in what was posted: MIDI is read at the start of a block.
    private func run(_ synth: Synth) {
        var block = [Float](repeating: 0, count: 64)
        block.withUnsafeMutableBufferPointer { synth.render(left: $0.baseAddress!, right: nil, frames: 64) }
    }

    private func send(_ synth: Synth, controller: Int, value: Int, channel: UInt8 = 0) {
        synth.postMIDI(status: 0xB0 | channel, data1: UInt8(controller), data2: UInt8(value))
        run(synth)
    }

    // MARK: What the knobs come with

    @Test("Every knob comes with a controller of its own, and none that MIDI reserves")
    func standardControllers() {
        #expect(Self.knobs.count == 34)
        let controllers = Self.knobs.compactMap { Controllers.standard(for: $0) }
        #expect(controllers.count == Self.knobs.count)
        #expect(Set(controllers).count == controllers.count)
        #expect(controllers.allSatisfy { (0...127).contains($0) && !Controllers.isReserved($0) })
    }

    @Test("Where MIDI names a controller for the thing, the knob has it")
    func generalMidi() throws {
        let expected = ["volume": 7, "pan": 10, "vowel": 74, "reso": 71, "ring": 72, "breath": 2, "velsens": 73]
        for (identifier, controller) in expected {
            #expect(Controllers.standard(for: try knob(identifier)) == controller, "\(identifier)")
            #expect(Synth().controller(of: try knob(identifier)) == controller, "\(identifier) on a new synth")
        }
    }

    @Test("The other knobs take MIDI's undefined controllers, in table order")
    func undefinedInTableOrder() {
        let named: Set<String> = ["volume", "pan", "vowel", "reso", "ring", "breath", "velsens"]
        let undefined = Array(14...31) + Array(85...90) + Array(102...119)
        let others = Self.knobs.filter { !named.contains($0.identifier) }
        #expect(others.map { Controllers.standard(for: $0) } == undefined.prefix(others.count).map { Optional($0) })
    }

    @Test("MIDI's own controllers and the mod wheel are reserved; an amount has no controller")
    func reserved() {
        let reserved = [0, 1, 6, 32, 38, 64] + Array(96...101) + Array(120...127)
        for controller in 0...127 {
            #expect(Controllers.isReserved(controller) == reserved.contains(controller), "CC \(controller)")
        }
        #expect(Controllers.isReserved(-1) && Controllers.isReserved(128))
        let synth = Synth()
        for amount in Parameters.all where amount.index >= Self.knobs.count {
            #expect(Controllers.standard(for: amount) == nil, "\(amount.identifier)")
            #expect(synth.controller(of: amount) == nil, "\(amount.identifier) on a new synth")
        }
    }

    // MARK: Moving a knob

    @Test("A controller puts its knob where its value says, on any channel")
    func controllerMovesItsKnob() throws {
        let synth = Synth()
        let vowel = try knob("vowel"), ring = try knob("ring")
        let ringBefore = synth.value(of: ring)
        send(synth, controller: 74, value: 127)
        #expect(synth.normalisedValue(of: vowel) == 1)
        send(synth, controller: 74, value: 0, channel: 9)
        #expect(synth.normalisedValue(of: vowel) == 0)
        send(synth, controller: 74, value: 100, channel: 15)
        #expect(abs(synth.normalisedValue(of: vowel) - 100.0 / 127) < 1e-6)
        #expect(synth.value(of: ring) == ringBefore)                              // nobody else moved
    }

    @Test("A choice takes the step nearest to the controller's value")
    func controllerOnAChoice() throws {
        let synth = Synth()
        let stroke = try knob("stroke")                       // Out, In, Alternate
        let cc = try #require(synth.controller(of: stroke))
        send(synth, controller: cc, value: 0)
        #expect(stroke.text(synth.value(of: stroke)) == "Out")
        send(synth, controller: cc, value: 64)
        #expect(stroke.text(synth.value(of: stroke)) == "In")
        send(synth, controller: cc, value: 127)
        #expect(stroke.text(synth.value(of: stroke)) == "Alternate")
    }

    @Test("A knob with a middle stands on it at 64")
    func middle() throws {
        let synth = Synth()
        for identifier in ["pan", "breath", "offset", "sweep", "tune", "octave"] {
            let bipolar = try knob(identifier)
            #expect(bipolar.isBipolar, "\(identifier)")
            let cc = try #require(synth.controller(of: bipolar))
            send(synth, controller: cc, value: 64)
            #expect(synth.normalisedValue(of: bipolar) == 0.5, "\(identifier)")
            #expect(abs(synth.value(of: bipolar)) < 1e-4, "\(identifier)")
            send(synth, controller: cc, value: 63)
            #expect(synth.normalisedValue(of: bipolar) < 0.5, "\(identifier)")
        }
        let volume = try knob("volume")                       // -40 ... 6 dB has no middle
        send(synth, controller: 7, value: 64)
        #expect(abs(synth.normalisedValue(of: volume) - 64.0 / 127) < 1e-6)
    }

    @Test("In pad mode a controller still moves the keyboard set, and no pad")
    func padModeMovesTheKeyboard() throws {
        let synth = Synth()
        synth.mode = .pads
        let vowel = try knob("vowel")
        let pads = (0..<16).map { synth.normalisedValue(of: vowel, in: .pad($0)) }
        send(synth, controller: 74, value: 127)
        #expect(synth.normalisedValue(of: vowel) == 1)
        #expect((0..<16).map { synth.normalisedValue(of: vowel, in: .pad($0)) } == pads)
    }

    @Test("The engine counts what MIDI changed, so that a window knows when to look")
    func changesAreCounted() {
        let synth = Synth()
        let before = synth.changes
        synth.noteOn(48)
        run(synth)
        #expect(synth.changes == before)                      // a note changes no knob
        send(synth, controller: 74, value: 100)
        #expect(synth.changes != before)
        let moved = synth.changes
        send(synth, controller: 119, value: 100)              // nobody listens to 119
        send(synth, controller: 1, value: 100)                // the mod wheel moves no knob
        #expect(synth.changes == moved)
    }

    @Test("The mod wheel, Reset All Controllers and All Notes Off move no knob")
    func midisOwnControllers() {
        let synth = Synth()
        let values = Parameters.all.map { synth.normalisedValue(of: $0) }
        for controller in [1, 121, 123, 120, 64, 0] { send(synth, controller: controller, value: 127) }
        #expect(Parameters.all.map { synth.normalisedValue(of: $0) } == values)
    }

    // MARK: Learn

    @Test("A knob that is learning takes the next controller that moves, and that controller's value")
    func learn() throws {
        let synth = Synth()
        let edge = try knob("edge")
        let standard = try #require(Controllers.standard(for: edge))
        #expect(synth.learning == nil)
        synth.learn(edge)
        #expect(synth.learning == edge)
        let before = synth.changes
        send(synth, controller: 40, value: 127)
        #expect(synth.learning == nil)
        #expect(synth.changes != before)
        #expect(synth.controller(of: edge) == 40)
        #expect(synth.normalisedValue(of: edge) == 1)
        send(synth, controller: standard, value: 0)           // the controller it came with
        #expect(synth.normalisedValue(of: edge) == 1)         // no longer moves it
    }

    @Test("Learning can be called off, and a reserved controller does not end it")
    func learnIgnoresReserved() throws {
        let synth = Synth()
        let edge = try knob("edge")
        let standard = Controllers.standard(for: edge)
        synth.learn(edge)
        send(synth, controller: 1, value: 90)                 // the mod wheel
        send(synth, controller: 64, value: 127)
        #expect(synth.learning == edge)
        #expect(synth.controller(of: edge) == standard)
        synth.learn(nil)
        #expect(synth.learning == nil)
        send(synth, controller: 40, value: 127)
        #expect(synth.controller(of: edge) == standard)
    }

    @Test("An amount cannot learn")
    func amountsDoNotLearn() throws {
        let synth = Synth()
        synth.learn(try knob("lfo1vowel"))
        #expect(synth.learning == nil)
        synth.setController(40, of: try knob("lfo1vowel"))
        #expect(synth.controller(of: try knob("lfo1vowel")) == nil)
    }

    @Test("A controller serves one knob: given to another, the first knob has none")
    func oneKnobPerController() throws {
        let synth = Synth()
        let edge = try knob("edge"), vowel = try knob("vowel")
        synth.learn(edge)
        send(synth, controller: 74, value: 10)                // Vowel's controller
        #expect(synth.controller(of: edge) == 74)
        #expect(synth.controller(of: vowel) == nil)
        let vowelBefore = synth.value(of: vowel)
        send(synth, controller: 74, value: 120)
        #expect(synth.value(of: vowel) == vowelBefore)
    }

    @Test("A knob's controller can be taken away, given by hand, and all put back")
    func setAndReset() throws {
        let synth = Synth()
        let edge = try knob("edge"), vowel = try knob("vowel")
        synth.setController(nil, of: vowel)
        #expect(synth.controller(of: vowel) == nil)
        synth.setController(74, of: edge)
        #expect(synth.controller(of: edge) == 74)
        synth.setController(64, of: vowel)                    // reserved: not taken
        #expect(synth.controller(of: vowel) == nil)
        synth.setController(128, of: vowel)                   // not a controller
        #expect(synth.controller(of: vowel) == nil)
        synth.resetControllers()
        #expect(Self.knobs.allSatisfy { synth.controller(of: $0) == Controllers.standard(for: $0) })
    }

    @Test("Programs and sent pads leave the controllers alone")
    func soundsKeepControllers() throws {
        let synth = Synth()
        let edge = try knob("edge")
        synth.setController(40, of: edge)
        synth.loadProgram(3)
        synth.sendToPad(2)
        synth.loadDefaultKit()
        #expect(synth.controller(of: edge) == 40)
    }

    // MARK: Storing

    @Test("The controllers round-trip through the form they are stored in, a knob without one included")
    func mapSurvivesStorage() throws {
        let synth = Synth()
        synth.setController(40, of: try knob("edge"))
        synth.setController(nil, of: try knob("vowel"))
        let map = ControllerMap(capturing: synth)
        #expect(Set(map.controllers.keys) == Set(Self.knobs.map(\.identifier)))
        let stored = try JSONEncoder().encode(map)

        let other = Synth()
        try JSONDecoder().decode(ControllerMap.self, from: stored).apply(to: other)
        #expect(other.controller(of: try knob("edge")) == 40)
        #expect(other.controller(of: try knob("vowel")) == nil)
        #expect(other.controller(of: try knob("volume")) == 7)
        #expect(ControllerMap(capturing: other) == map)
    }

    @Test("A stored map from another version: a knob it lacks keeps its standard, a name it has that this version lacks is ignored")
    func tolerantMap() throws {
        let json = Data(#"{"controllers": {"edge": 40, "from-the-future": 50, "vowel": -1}, "unknown": true}"#.utf8)
        let map = try JSONDecoder().decode(ControllerMap.self, from: json)
        let synth = Synth()
        synth.setController(nil, of: try knob("ring"))
        map.apply(to: synth)
        #expect(synth.controller(of: try knob("edge")) == 40)
        #expect(synth.controller(of: try knob("vowel")) == nil)
        #expect(synth.controller(of: try knob("ring")) == 72)
        #expect(synth.controller(of: try knob("volume")) == 7)

        let empty = try JSONDecoder().decode(ControllerMap.self, from: Data("{}".utf8))
        #expect(empty.controllers.isEmpty)
    }

    @Test("A stored map that gives one controller to two knobs leaves it with one")
    func mapWithAClash() throws {
        let synth = Synth()
        ControllerMap(controllers: ["edge": 40, "body": 40]).apply(to: synth)
        let holders = Self.knobs.filter { synth.controller(of: $0) == 40 }
        #expect(holders.count == 1)
    }

    // MARK: What the panel shows

    @Test("A controller reads as CC and its number; none as a dash")
    func labels() {
        #expect(Controllers.label(74) == "CC 74")
        #expect(Controllers.label(nil) == "—")
    }

    @Test("Every control on the panel can learn in the keyboard set; a pad's controls and the amounts cannot")
    func whoLearns() throws {
        #expect(Self.knobs.allSatisfy { Controllers.canLearn($0, in: .keyboard) })
        #expect(!Self.knobs.contains { Controllers.canLearn($0, in: .pad(3)) })
        #expect(!Controllers.canLearn(try knob("lfo1vowel"), in: .keyboard))
        #expect(!Controllers.canLearn(try knob("velring"), in: .keyboard))
    }

    @Test("In MIDI mode a control shows its controller, a dash without one, and asks for a control while it listens")
    func captions() throws {
        let vowel = try knob("vowel"), ring = try knob("ring")
        #expect(Controllers.caption(of: vowel, in: .keyboard, controller: 74, learning: nil) == "CC 74")
        #expect(Controllers.caption(of: vowel, in: .keyboard, controller: nil, learning: nil) == "—")
        #expect(Controllers.caption(of: vowel, in: .keyboard, controller: 74, learning: vowel) == "move a control")
        #expect(Controllers.caption(of: vowel, in: .keyboard, controller: 74, learning: ring) == "CC 74")
        // A pad's set and an amount have no controllers, whatever the keyboard's knob has.
        #expect(Controllers.caption(of: vowel, in: .pad(0), controller: 74, learning: vowel) == "—")
        #expect(Controllers.caption(of: try knob("lfo1vowel"), in: .keyboard, controller: nil, learning: nil) == "—")
    }
}
