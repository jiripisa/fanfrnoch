import Foundation
import Testing
@testable import FanfrnochCore

/// MIDI controllers on the keyboard set's knobs: each knob comes with one, a control change moves
/// the knob, and a knob can be taught another.
@Suite("Controllers")
struct ControllerTests {

    private func knob(_ identifier: String) throws -> Parameter { try #require(Parameters.named(identifier)) }

    /// The 45 knobs, in table order.
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
        #expect(Self.knobs.count == 45)
        let controllers = Self.knobs.compactMap { Controllers.standard(for: $0) }
        #expect(controllers.count == Self.knobs.count)
        #expect(Set(controllers).count == controllers.count)
        #expect(controllers.allSatisfy { (0...127).contains($0) && !Controllers.isReserved($0) })
    }

    @Test("Where MIDI names a controller for the thing, the knob has it")
    func generalMidi() throws {
        let expected = ["volume": 7, "pan": 10, "stick": 74, "potq": 71, "release": 72, "rub": 2, "attack": 73]
        for (identifier, controller) in expected {
            #expect(Controllers.standard(for: try knob(identifier)) == controller, "\(identifier)")
            #expect(Synth().controller(of: try knob(identifier)) == controller, "\(identifier) on a new synth")
        }
    }

    @Test("The other knobs take MIDI's undefined controllers, in table order")
    func undefinedInTableOrder() {
        let named: Set<String> = ["volume", "pan", "stick", "potq", "release", "rub", "attack"]
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
        let stick = try knob("stick"), release = try knob("release")
        let ringBefore = synth.value(of: release)
        send(synth, controller: 74, value: 127)
        #expect(synth.normalisedValue(of: stick) == 1)
        send(synth, controller: 74, value: 0, channel: 9)
        #expect(synth.normalisedValue(of: stick) == 0)
        send(synth, controller: 74, value: 100, channel: 15)
        #expect(abs(synth.normalisedValue(of: stick) - 100.0 / 127) < 1e-6)
        #expect(synth.value(of: release) == ringBefore)                              // nobody else moved
    }

    @Test("A choice takes the step nearest to the controller's value")
    func controllerOnAChoice() throws {
        let synth = Synth()
        let shape = try knob("lfo1shape")                     // Sine ... Wander, seven steps
        let cc = try #require(synth.controller(of: shape))
        send(synth, controller: cc, value: 0)
        #expect(shape.text(synth.value(of: shape)) == "Sine")
        send(synth, controller: cc, value: 64)
        #expect(shape.text(synth.value(of: shape)) == "Ramp Down")
        send(synth, controller: cc, value: 127)
        #expect(shape.text(synth.value(of: shape)) == "Wander")
    }

    @Test("A knob with a middle stands on it at 64")
    func middle() throws {
        let synth = Synth()
        for identifier in ["pan", "alttune", "drift", "tune", "octave"] {
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
        let stick = try knob("stick")
        let pads = (0..<16).map { synth.normalisedValue(of: stick, in: .pad($0)) }
        send(synth, controller: 74, value: 127)
        #expect(synth.normalisedValue(of: stick) == 1)
        #expect((0..<16).map { synth.normalisedValue(of: stick, in: .pad($0)) } == pads)
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
        let split = try knob("split")
        let standard = try #require(Controllers.standard(for: split))
        #expect(synth.learning == nil)
        synth.learn(split)
        #expect(synth.learning == split)
        let before = synth.changes
        send(synth, controller: 40, value: 127)
        #expect(synth.learning == nil)
        #expect(synth.changes != before)
        #expect(synth.controller(of: split) == 40)
        #expect(synth.normalisedValue(of: split) == 1)
        send(synth, controller: standard, value: 0)           // the controller it came with
        #expect(synth.normalisedValue(of: split) == 1)         // no longer moves it
    }

    @Test("Learning can be called off, and a reserved controller does not end it")
    func learnIgnoresReserved() throws {
        let synth = Synth()
        let split = try knob("split")
        let standard = Controllers.standard(for: split)
        synth.learn(split)
        send(synth, controller: 1, value: 90)                 // the mod wheel
        send(synth, controller: 64, value: 127)
        #expect(synth.learning == split)
        #expect(synth.controller(of: split) == standard)
        synth.learn(nil)
        #expect(synth.learning == nil)
        send(synth, controller: 40, value: 127)
        #expect(synth.controller(of: split) == standard)
    }

    @Test("An amount cannot learn")
    func amountsDoNotLearn() throws {
        let synth = Synth()
        synth.learn(try knob("lfo1stick"))
        #expect(synth.learning == nil)
        synth.setController(40, of: try knob("lfo1stick"))
        #expect(synth.controller(of: try knob("lfo1stick")) == nil)
    }

    @Test("A controller serves one knob: given to another, the first knob has none")
    func oneKnobPerController() throws {
        let synth = Synth()
        let split = try knob("split"), stick = try knob("stick")
        synth.learn(split)
        send(synth, controller: 74, value: 10)                // Stick's controller
        #expect(synth.controller(of: split) == 74)
        #expect(synth.controller(of: stick) == nil)
        let stickBefore = synth.value(of: stick)
        send(synth, controller: 74, value: 120)
        #expect(synth.value(of: stick) == stickBefore)
    }

    @Test("A knob's controller can be taken away, given by hand, and all put back")
    func setAndReset() throws {
        let synth = Synth()
        let split = try knob("split"), stick = try knob("stick")
        synth.setController(nil, of: stick)
        #expect(synth.controller(of: stick) == nil)
        synth.setController(74, of: split)
        #expect(synth.controller(of: split) == 74)
        synth.setController(64, of: stick)                    // reserved: not taken
        #expect(synth.controller(of: stick) == nil)
        synth.setController(128, of: stick)                   // not a controller
        #expect(synth.controller(of: stick) == nil)
        synth.resetControllers()
        #expect(Self.knobs.allSatisfy { synth.controller(of: $0) == Controllers.standard(for: $0) })
    }

    @Test("Programs and sent pads leave the controllers alone")
    func soundsKeepControllers() throws {
        let synth = Synth()
        let split = try knob("split")
        synth.setController(40, of: split)
        synth.loadProgram(3)
        synth.sendToPad(2)
        synth.loadDefaultKit()
        #expect(synth.controller(of: split) == 40)
    }

    // MARK: Storing

    @Test("The controllers round-trip through the form they are stored in, a knob without one included")
    func mapSurvivesStorage() throws {
        let synth = Synth()
        synth.setController(40, of: try knob("split"))
        synth.setController(nil, of: try knob("stick"))
        let map = ControllerMap(capturing: synth)
        #expect(Set(map.controllers.keys) == Set(Self.knobs.map(\.identifier)))
        let stored = try JSONEncoder().encode(map)

        let other = Synth()
        try JSONDecoder().decode(ControllerMap.self, from: stored).apply(to: other)
        #expect(other.controller(of: try knob("split")) == 40)
        #expect(other.controller(of: try knob("stick")) == nil)
        #expect(other.controller(of: try knob("volume")) == 7)
        #expect(ControllerMap(capturing: other) == map)
    }

    @Test("A stored map from another version: a knob it lacks keeps its standard, a name it has that this version lacks is ignored")
    func tolerantMap() throws {
        let json = Data(#"{"controllers": {"split": 40, "from-the-future": 50, "stick": -1}, "unknown": true}"#.utf8)
        let map = try JSONDecoder().decode(ControllerMap.self, from: json)
        let synth = Synth()
        synth.setController(nil, of: try knob("release"))
        map.apply(to: synth)
        #expect(synth.controller(of: try knob("split")) == 40)
        #expect(synth.controller(of: try knob("stick")) == nil)
        #expect(synth.controller(of: try knob("release")) == 72)
        #expect(synth.controller(of: try knob("volume")) == 7)

        let empty = try JSONDecoder().decode(ControllerMap.self, from: Data("{}".utf8))
        #expect(empty.controllers.isEmpty)
    }

    @Test("A stored map that gives one controller to two knobs leaves it with one")
    func mapWithAClash() throws {
        let synth = Synth()
        ControllerMap(controllers: ["split": 40, "skin": 40]).apply(to: synth)
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
        #expect(!Controllers.canLearn(try knob("lfo1stick"), in: .keyboard))
        #expect(!Controllers.canLearn(try knob("velrelease"), in: .keyboard))
    }

    @Test("In MIDI mode a control shows its controller, a dash without one, and asks for a control while it listens")
    func captions() throws {
        let stick = try knob("stick"), release = try knob("release")
        #expect(Controllers.caption(of: stick, in: .keyboard, controller: 74, learning: nil) == "CC 74")
        #expect(Controllers.caption(of: stick, in: .keyboard, controller: nil, learning: nil) == "—")
        #expect(Controllers.caption(of: stick, in: .keyboard, controller: 74, learning: stick) == "move a control")
        #expect(Controllers.caption(of: stick, in: .keyboard, controller: 74, learning: release) == "CC 74")
        // A pad's set and an amount have no controllers, whatever the keyboard's knob has.
        #expect(Controllers.caption(of: stick, in: .pad(0), controller: 74, learning: stick) == "—")
        #expect(Controllers.caption(of: try knob("lfo1stick"), in: .keyboard, controller: nil, learning: nil) == "—")
    }
}
