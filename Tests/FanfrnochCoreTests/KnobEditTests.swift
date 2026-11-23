import Observation
import Testing
import FanfrnochCore
@testable import FanfrnochUI

/// A drag on a knob of the panel as the edit a host records.
@Suite("Knob edit")
@MainActor
struct KnobEditTests {

    /// Records what the panel asks of the model; positions live in a dictionary.
    @Observable
    final class Recorder: InstrumentModel {
        enum Call: Equatable {
            case begin(String, SoundSet), end(String, SoundSet), reset(String, SoundSet)
            case controller(String, Int?), learn(String?)
        }
        var calls: [Call] = []
        var positions: [String: Double] = [:]
        var mode: PlayMode = .keyboard
        var selectedPad = 0
        var shownSet: SoundSet { mode == .keyboard ? .keyboard : .pad(selectedPad) }

        func program(in set: SoundSet) -> Int { 0 }
        func loadProgram(_ index: Int, into set: SoundSet) {}
        func position(of parameter: Parameter, in set: SoundSet) -> Double { positions[parameter.identifier] ?? 0.5 }
        func setPosition(_ position: Double, of parameter: Parameter, in set: SoundSet) { positions[parameter.identifier] = position }
        func resetToDefault(_ parameter: Parameter, in set: SoundSet) { calls.append(.reset(parameter.identifier, set)) }
        func beginEditing(_ parameter: Parameter, in set: SoundSet) { calls.append(.begin(parameter.identifier, set)) }
        func endEditing(_ parameter: Parameter, in set: SoundSet) { calls.append(.end(parameter.identifier, set)) }
        func padNote(_ pad: Int) -> Int { 36 + pad }
        func setPadNote(_ note: Int, pad: Int) {}
        func padGroup(_ pad: Int) -> Int? { nil }
        func setPadGroup(_ group: Int?, pad: Int) {}
        func padName(_ pad: Int) -> String { "" }
        func padHits(_ pad: Int) -> Int { 0 }
        var lastNote: Int? { nil }
        func sendToPad(_ pad: Int) {}
        func hitPad(_ pad: Int, velocity: Int) {}
        func releasePad(_ pad: Int) {}
        func keyDown(_ note: Int, velocity: Int) {}
        func keyUp(_ note: Int) {}
        func refresh() {}
        var presets: [String] { [] }
        func presetInUse(in set: SoundSet) -> String? { nil }
        func loadPreset(_ name: String, into set: SoundSet) throws {}
        func savePreset(as name: String, from set: SoundSet) throws {}
        func deletePreset(_ name: String) throws {}
        func lookAtPresets() {}
        var kits: [String] { [] }
        func loadKit(_ name: String) throws {}
        func loadDefaultKit() {}
        func saveKit(as name: String) throws {}
        func deleteKit(_ name: String) throws {}
        func controller(of parameter: Parameter) -> Int? { nil }
        func setController(_ controller: Int?, of parameter: Parameter) { calls.append(.controller(parameter.identifier, controller)) }
        func resetControllers() {}
        var learning: Parameter?
        func learn(_ parameter: Parameter?) {
            learning = parameter
            calls.append(.learn(parameter?.identifier))
        }
        var lastError: String? { nil }
        var lastErrorTime: ContinuousClock.Instant? { nil }
    }

    private let release = Parameters.named("release")!
    private let amount = Parameters.named("lfo1stick")!

    @Test("A drag begins one edit and ends it, in the set it began in")
    func beginAndEndPair() {
        let model = Recorder()
        model.mode = .pads
        model.selectedPad = 3
        var edit = KnobEdit.begin(release, in: model.shownSet, isAmount: false, model: model)
        edit.move(to: 10, fine: false, model: model)
        model.selectedPad = 7                     // MIDI selects another pad mid-drag
        edit.move(to: 20, fine: false, model: model)
        edit.end(model: model)
        #expect(model.calls == [.begin("release", .pad(3)), .end("release", .pad(3))])
    }

    @Test("Up turns the knob up; 200 points turn it end to end, and no further")
    func travel() {
        let model = Recorder()
        var edit = KnobEdit.begin(release, in: .keyboard, isAmount: false, model: model)
        edit.move(to: -50, fine: false, model: model)
        #expect(model.positions["release"] == 0.75)
        edit.move(to: -500, fine: false, model: model)
        #expect(model.positions["release"] == 1)
        edit.move(to: -450, fine: false, model: model)
        #expect(model.positions["release"] == 0.75)
    }

    @Test("Shift pressed halfway makes the rest of the drag finer, without a jump")
    func shiftHalfway() {
        let model = Recorder()
        var edit = KnobEdit.begin(release, in: .keyboard, isAmount: false, model: model)
        edit.move(to: -50, fine: false, model: model)
        #expect(model.positions["release"] == 0.75)
        edit.move(to: -50, fine: true, model: model)
        #expect(model.positions["release"] == 0.75)
        edit.move(to: -100, fine: true, model: model)
        #expect(abs(model.positions["release"]! - 0.775) < 1e-12)
        edit.move(to: -100, fine: false, model: model)
        #expect(abs(model.positions["release"]! - 0.775) < 1e-12)
    }

    @Test("An amount close to nothing is nothing, and the drag goes on past it")
    func amountSnaps() {
        let model = Recorder()
        var edit = KnobEdit.begin(amount, in: .keyboard, isAmount: true, model: model)   // at 0 %
        edit.move(to: -1, fine: false, model: model)                                      // +1 % ...
        edit.move(to: -0.5, fine: false, model: model)                                    // ... back to +0.5 %
        #expect(model.positions["lfo1stick"] == Double(amount.normalised(0)))
        edit.move(to: -3, fine: false, model: model)                                      // +3 %
        #expect(abs(Double(amount.plain(Float(model.positions["lfo1stick"]!))) - 3) < 1e-3)
    }

    @Test("A double click puts the value back as an edit of its own")
    func resetIsAnEdit() {
        let model = Recorder()
        KnobEdit.reset(release, in: .pad(2), model: model)
        #expect(model.calls == [.begin("release", .pad(2)), .reset("release", .pad(2)), .end("release", .pad(2))])
    }

    // MARK: VoiceOver

    @Test("VoiceOver turns a knob a twentieth of its travel a step, as an edit of its own, and no further than its end")
    func adjustContinuous() {
        let model = Recorder()
        KnobEdit.adjust(release, in: .pad(1), isAmount: false, up: true, model: model)
        #expect(abs(model.positions["release"]! - 0.55) < 1e-12)
        #expect(model.calls == [.begin("release", .pad(1)), .end("release", .pad(1))])
        model.positions["release"] = 0.98
        KnobEdit.adjust(release, in: .keyboard, isAmount: false, up: true, model: model)
        #expect(model.positions["release"] == 1)
        model.positions["release"] = 0.01
        KnobEdit.adjust(release, in: .keyboard, isAmount: false, up: false, model: model)
        #expect(model.positions["release"] == 0)
    }

    @Test("A knob of whole steps moves one step")
    func adjustInteger() throws {
        let octave = try #require(Parameters.named("octave"))
        let model = Recorder()
        model.positions["octave"] = Double(octave.normalised(0))
        KnobEdit.adjust(octave, in: .keyboard, isAmount: false, up: true, model: model)
        #expect(octave.plain(Float(model.positions["octave"]!)) == 1)
        KnobEdit.adjust(octave, in: .keyboard, isAmount: false, up: false, model: model)
        KnobEdit.adjust(octave, in: .keyboard, isAmount: false, up: false, model: model)
        #expect(octave.plain(Float(model.positions["octave"]!)) == -1)
    }

    @Test("An amount stepped by VoiceOver snaps to nothing near nothing, as a drag does")
    func adjustAmount() {
        let model = Recorder()
        model.positions["lfo1stick"] = Double(amount.normalised(0)) - 0.051     // a step below nothing, by a hair
        KnobEdit.adjust(amount, in: .keyboard, isAmount: true, up: true, model: model)
        #expect(model.positions["lfo1stick"] == Double(amount.normalised(0)))
    }

    // MARK: MIDI mode

    @Test("A double click in MIDI mode gives the standard controller back and calls off the control's own listening")
    func doubleClickInMIDIMode() throws {
        let stick = try #require(Parameters.named("stick"))
        let model = Recorder()
        model.learning = stick                                    // the first click made it listen
        ControllerHandling.backToStandard(stick, model: model)
        #expect(model.calls == [.learn(nil), .controller("stick", 74)])
        #expect(model.learning == nil)

        model.calls = []
        model.learning = release                                     // another control listens: it goes on
        ControllerHandling.backToStandard(stick, model: model)
        #expect(model.calls == [.controller("stick", 74)])
        #expect(model.learning == release)
    }

    @Test("In MIDI mode the keyboard's controls stay in play and a pad's step back; nothing sets an amount")
    func controllerMode() throws {
        let stick = try #require(Parameters.named("stick"))
        let keyup = try #require(Parameters.named("keyup"))
        #expect(KnobEditing.controller.amount(of: stick) == nil)
        #expect(!KnobEditing.controller.stepsBack(stick, in: .keyboard))
        #expect(!KnobEditing.controller.stepsBack(keyup, in: .keyboard))
        #expect(KnobEditing.controller.stepsBack(stick, in: .pad(2)))
        // The other modes are as they were, in either set.
        #expect(!KnobEditing.value.stepsBack(stick, in: .pad(2)))
        #expect(!KnobEditing.amount(lfo: 0).stepsBack(stick, in: .keyboard))
        #expect(KnobEditing.velocity.stepsBack(keyup, in: .keyboard))
    }
}
