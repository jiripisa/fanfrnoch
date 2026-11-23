import Testing
import FanfrnochDSP
import FanfrnochReference
@testable import FanfrnochCore

@Suite("Parameter table")
struct ParameterTableTests {

    /// The knobs in the permanent order: the instrument design's table (§6), section by section.
    static let knobs = ["attack", "length", "release", "damp", "keyup", "velsens", "vary",
                        "alternate", "alttune",
                        "scoop", "scooptime", "drift", "drop", "wobble", "jump", "jumpratio", "velpitch",
                        "stick", "stickvel", "split", "creak", "creakrate", "creakring",
                        "pot", "potq", "potlevel", "skin", "skinq", "skinlevel", "track",
                        "rub", "scrape", "shimmer",
                        "volume", "pan", "tune", "octave", "bendup", "benddown", "drum", "lfostart",
                        "lfo1rate", "lfo1shape", "lfo2rate", "lfo2shape"]

    @Test("103 parameters in the permanent order")
    func order() {
        #expect(Parameters.all.count == 103)
        #expect(Set(Parameters.all.map(\.identifier)).count == 103)          // the knobs and the amounts never share a name
        #expect(Parameters.all.prefix(45).map(\.identifier) == Self.knobs)
        #expect(Parameters.all[45].identifier == "lfo1tune" && Parameters.all[66].identifier == "lfo2pan")
        #expect(Parameters.all[67].identifier == "velattack" && Parameters.all[102].identifier == "vellfo2rate")
        #expect(Parameters.named("velvolume")?.name == "VEL>Volume")
        #expect(Parameters.named("lfo2stick")?.name == "LFO 2>Stick")
        #expect(Parameters.named("velpitch")?.name == "Vel>Pitch" && Parameters.named("velvelpitch")?.name == "VEL>Vel>Pitch")
    }

    @Test("Defaults are the prototype's")
    func defaults() {
        let expected: [String: Float] = [
            "attack": 42, "length": 230, "release": 0.30, "damp": 0, "keyup": 0, "velsens": 70, "vary": 20,
            "alternate": 2, "alttune": 10,
            "scoop": 0, "scooptime": 80, "drift": -0.8, "drop": 0, "wobble": 20, "jump": 0, "jumpratio": 1.40, "velpitch": 0,
            "stick": 0.88, "stickvel": 0.03, "split": 0, "creak": 0, "creakrate": 14, "creakring": 40,
            "pot": 500, "potq": 4, "potlevel": -40, "skin": 306, "skinq": 10, "skinlevel": -40, "track": 0,
            "rub": -10, "scrape": 10, "shimmer": 0.7,
            "volume": 0, "pan": 0, "tune": 0, "octave": 0, "bendup": 12, "benddown": 2, "drum": 0, "lfostart": 0,
            "lfo1rate": 6, "lfo1shape": 0, "lfo2rate": 2, "lfo2shape": 0,
        ]
        #expect(expected.count == 45)
        for (id, value) in expected {
            #expect(Parameters.named(id)?.defaultValue == value, "\(id)")
        }
        #expect(Parameters.all.suffix(58).allSatisfy { $0.defaultValue == 0 && $0.range == -100...100 })
    }

    // The engine's defaults, as its knobs hold them, are what the reference copy of the prototype
    // starts with, in the prototype's units (its off levels are the bottoms of the knobs). Every
    // field of the C struct is four bytes: a float, or Key Up's int (0 in both).
    @Test("The engine's defaults are the reference's")
    func defaultsMatchTheReference() {
        var ours = PrototypeScores.referenceParams([:]), theirs = FanfrnochRefParams()
        fanfrnoch_ref_default_params(&theirs)
        let a = withUnsafeBytes(of: &ours) { Array($0.bindMemory(to: Float.self)) }
        let b = withUnsafeBytes(of: &theirs) { Array($0.bindMemory(to: Float.self)) }
        #expect(a.count == 33)
        for (field, (x, y)) in zip(a, b).enumerated() {
            #expect(abs(x - y) <= 1e-6 * max(1, abs(y)), "field \(field): \(x), the prototype's \(y)")
        }
    }

    @Test("Ranges, choices and travel")
    func ranges() {
        let release = Parameters.named("release")!
        #expect(release.range == 0.03...3 && release.unit == "s")
        #expect(Parameters.named("attack")!.range == 5...400 && Parameters.named("length")!.range == 0...2000)
        #expect(Parameters.named("alttune")!.range == -100...100 && Parameters.named("drift")!.range == -3...3)
        #expect(Parameters.named("stick")!.range == 0.5...0.95 && Parameters.named("stickvel")!.range == 0...0.1)
        #expect(Parameters.named("potlevel")!.range == -40...18 && Parameters.named("skinlevel")!.range == -40...6)
        #expect(Parameters.named("rub")!.range == -40...0 && Parameters.named("shimmer")!.range == 0...3)
        #expect(Parameters.named("bendup")!.range == 0...24 && Parameters.named("benddown")!.range == 0...12)
        #expect(Parameters.named("octave")!.kind == .integer && Parameters.named("bendup")!.kind == .integer)
        #expect(Parameters.named("keyup")!.kind == .choice(["Ignore", "Stop"]))
        #expect(Parameters.named("drum")!.kind == .choice(["One", "Many"]))
        #expect(Parameters.named("lfostart")!.kind == .choice(["Hit", "Free"]))
        #expect(Parameters.named("lfo2shape")!.kind == .choice(["Sine", "Triangle", "Ramp Up", "Ramp Down", "Square", "Steps", "Wander"]))
        // A logarithmic knob's middle is the geometric mean.
        #expect(abs(release.plain(0.5) - (0.03 * 3 as Float).squareRoot()) < 1e-5)
        for id in ["attack", "release", "scooptime", "creakrate", "creakring", "pot", "potq", "skin", "skinq", "lfo1rate"] {
            var info = FanfrnochParamInfo()
            fanfrnoch_param_info(Int32(Parameters.named(id)!.index), &info)
            #expect(info.logarithmic == 1, "\(id)")
        }
    }

    @Test("Sections hold every knob once, in the design's order")
    func sections() {
        #expect(ParameterSection.all.map(\.title) == ["Stroke", "Hands", "Pitch", "Friction", "Body", "Noise", "Master"])
        #expect(ParameterSection.all.flatMap(\.parameters).map(\.identifier) == Self.knobs)
        var info = FanfrnochParamInfo()
        fanfrnoch_param_info(45, &info)
        #expect(info.section == -1)
    }

    @Test("LFO and VEL amounts point at their targets")
    func amounts() {
        let lfoTargets = ["tune", "stick", "rub", "pot", "potlevel", "skinlevel", "wobble", "creak", "split", "volume", "pan"]
        for knob in Parameters.all.prefix(45) {
            #expect((LFOs.amount(of: knob, lfo: 0) != nil) == lfoTargets.contains(knob.identifier), "\(knob.identifier)")
            #expect(LFOs.amount(of: knob, lfo: 1)?.identifier == (lfoTargets.contains(knob.identifier) ? "lfo2\(knob.identifier)" : nil))
        }
        // VEL moves every continuous knob of the sound but Vel Sens, and Volume, Pan, Tune and the
        // LFOs' rates; no switch, no Octave, no bend range.
        let notVel: Set<String> = ["keyup", "velsens", "octave", "bendup", "benddown", "drum", "lfostart", "lfo1shape", "lfo2shape"]
        for knob in Parameters.all.prefix(45) {
            #expect((Velocity.amount(of: knob)?.identifier == "vel\(knob.identifier)") == !notVel.contains(knob.identifier),
                    "\(knob.identifier)")
        }
        #expect(LFOs.count == 2)
        #expect(LFOs.label(amount: -30) == "−30 %" && LFOs.snapped(amount: 0.5) == 0)
    }

    @Test("The arcs a knob shows: an LFO sweeps both ways, a softer hit moves one way")
    func arcs() {
        #expect(LFOs.arc(position: 0.5, amount: 25) == 0.25...0.75)
        #expect(LFOs.arc(position: 0.875, amount: -25) == 0.625...1)
        // The knob is where the hardest hit stands; a positive amount means a softer hit is lower.
        #expect(Velocity.arc(position: 0.5, amount: 25) == 0.25...0.5)
        #expect(Velocity.arc(position: 0.5, amount: -25) == 0.5...0.75)
        #expect(Velocity.arc(position: 0.125, amount: 50) == 0...0.125)
        #expect(Velocity.arc(position: 0.875, amount: -50) == 0.875...1)
        #expect(Velocity.arc(position: 0.375, amount: 0) == 0.375...0.375)
    }

    // Each program is the defaults with the spike's program function's values (PrototypeScores) and,
    // for the loudest, a Volume that brings its peak down to the default's.
    @Test("Programs are the prototype's and leave Octave alone")
    func programs() {
        #expect(Programs.names == ["Fanfrnoch", "Fanfrnoch High", "Brummtopf", "Zambomba", "Zambomba Grave", "Putipù",
                                   "Cuíca", "Cuíca Whoop", "Furruco", "Creak", "Flick", "Buhai"])
        let trims: [Int: Float] = [2: -5.5, 4: -8, 8: -3.5, 11: -9]
        for program in Programs.names.indices {
            let values = PrototypeScores.spikePrograms[program]!.merging(["volume": trims[program] ?? 0]) { $1 }
            for parameter in Parameters.all {
                let want = values[parameter.identifier] ?? parameter.defaultValue
                #expect(Programs.value(program: program, parameter: parameter) == want, "\(Programs.names[program]): \(parameter.identifier)")
            }
        }
        #expect(fanfrnoch_program_sets(Int32(Parameters.named("octave")!.index)) == 0)
        #expect(fanfrnoch_program_sets(Int32(Parameters.named("release")!.index)) == 1)
    }

    @Test("Values round-trip and display")
    func display() {
        let release = Parameters.named("release")!
        #expect(abs(release.plain(release.normalised(0.3)) - 0.3) < 1e-6)
        #expect(release.label(0.3) == "0.30 s")
        #expect(Parameters.named("attack")!.label(42) == "42 ms")
        #expect(Parameters.named("keyup")!.label(1) == "Stop")
        #expect(Parameters.named("drum")!.label(1) == "Many")
        #expect(Parameters.named("pot")!.label(500) == "500 Hz")
        #expect(Parameters.named("creakrate")!.label(4) == "4.00 Hz")
        #expect(Parameters.named("stick")!.label(0.88) == "0.88")
        #expect(Parameters.named("stickvel")!.label(0.03) == "0.030")
        #expect(Parameters.named("jumpratio")!.label(1.4) == "1.40")
        #expect(Parameters.named("drift")!.label(-0.8) == "-0.80 st")
        #expect(Parameters.named("alttune")!.label(10) == "10 ct")
        #expect(Parameters.named("damp")!.label(50) == "50 %")
        #expect(Parameters.named("octave")!.label(1) == "+1")
        #expect(Parameters.named("bendup")!.label(12) == "12 st")
        // A level at the bottom of its knob is off.
        #expect(Parameters.named("potlevel")!.label(-40) == "Off" && Parameters.named("potlevel")!.label(6) == "6.0 dB")
        #expect(Parameters.named("rub")!.label(-40) == "Off" && Parameters.named("rub")!.label(-10) == "-10.0 dB")
        #expect(Parameters.named("skinlevel")!.label(-39.5) == "-39.5 dB")
        #expect(Parameters.named("drop")!.label(-0.001) == "0.00 st")
    }
}
