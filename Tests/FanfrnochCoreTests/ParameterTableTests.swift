import Testing
import FanfrnochDSP
@testable import FanfrnochCore

@Suite("Parameter table")
struct ParameterTableTests {

    static let knobs = ["ring","edge","offset","body","buzz","clang","velsens","stroke","damp","keyup","vary","vowel","sweep","sweeptime","curve","reso","throat","throattune","open","close","breath","puff","pufftime","air","volume","pan","tune","octave","bendvowel","lfostart","lfo1rate","lfo1shape","lfo2rate","lfo2shape"]

    /// The panel's order: the sections one after the other.
    static let panelOrder = ["ring","edge","offset","body","buzz","clang",
                             "velsens","stroke","damp","keyup","vary",
                             "vowel","sweep","sweeptime","curve","reso","throat","throattune","open","close",
                             "breath","puff","pufftime","air",
                             "volume","pan","tune","octave","bendvowel","lfostart","lfo1rate","lfo1shape","lfo2rate","lfo2shape"]

    @Test("81 parameters in the permanent order")
    func order() {
        #expect(Parameters.all.count == 81)
        #expect(Parameters.all.prefix(34).map(\.identifier) == Self.knobs)
        #expect(Parameters.all[34].identifier == "lfo1vowel" && Parameters.all[55].identifier == "lfo2offset")
        #expect(Parameters.all[56].identifier == "velring" && Parameters.all[80].identifier == "vellfo2rate")
        #expect(Parameters.named("velvolume")?.name == "VEL>Volume")
        #expect(Parameters.named("lfo2edge")?.name == "LFO 2>Edge")
    }

    @Test("Defaults are the prototype's")
    func defaults() {
        let expected: [String: Float] = [
            "ring": 4, "edge": 18, "offset": 0.2, "body": -24, "buzz": 40, "clang": 10, "velsens": 70,
            "stroke": 2, "damp": 10, "keyup": 0, "vary": 20, "vowel": 800, "sweep": 14, "sweeptime": 160,
            "curve": 0, "reso": 15, "throat": -10, "throattune": 430, "open": 30, "close": 0,
            "breath": 30, "puff": 30, "pufftime": 120, "air": 10, "volume": 0, "pan": 0, "tune": 0,
            "octave": 0, "bendvowel": 12, "lfostart": 0, "lfo1rate": 6, "lfo1shape": 0,
            "lfo2rate": 2, "lfo2shape": 0,
        ]
        #expect(expected.count == 34)
        for (id, value) in expected {
            #expect(Parameters.named(id)?.defaultValue == value, "\(id)")
        }
        #expect(Parameters.all.suffix(47).allSatisfy { $0.defaultValue == 0 && $0.range == -100...100 })
    }

    @Test("Ranges, choices and travel")
    func ranges() {
        let ring = Parameters.named("ring")!
        #expect(ring.range == 0.3...15 && ring.unit == "s")
        #expect(Parameters.named("sweep")!.range == -24...24)
        #expect(Parameters.named("breath")!.range == -100...100)
        #expect(Parameters.named("octave")!.kind == .integer)
        #expect(Parameters.named("stroke")!.kind == .choice(["Out", "In", "Alternate"]))
        #expect(Parameters.named("curve")!.kind == .choice(["Glide", "Line", "There and Back", "Step"]))
        #expect(Parameters.named("lfo2shape")!.kind == .choice(["Sine", "Triangle", "Ramp Up", "Ramp Down", "Square", "Steps", "Wander"]))
        // A logarithmic knob's middle is the geometric mean.
        #expect(abs(ring.plain(0.5) - (0.3 * 15).squareRoot()) < 1e-4)
    }

    @Test("Sections hold every knob once, in the panel's order")
    func sections() {
        #expect(ParameterSection.all.map(\.title) == ["Reed", "Stroke", "Mouth", "Breath", "Master"])
        #expect(ParameterSection.all.flatMap(\.parameters).map(\.identifier) == Self.panelOrder)
        #expect(Set(Self.panelOrder) == Set(Self.knobs))
        var info = FanfrnochParamInfo()
        fanfrnoch_param_info(34, &info)
        #expect(info.section == -1)
    }

    @Test("LFO and VEL amounts point at their targets")
    func amounts() {
        let vowel = Parameters.named("vowel")!, stroke = Parameters.named("stroke")!
        #expect(LFOs.amount(of: vowel, lfo: 1)?.identifier == "lfo2vowel")
        #expect(LFOs.amount(of: vowel, lfo: 0)?.identifier == "lfo1vowel")
        #expect(Velocity.amount(of: Parameters.named("ring")!)?.identifier == "velring")
        #expect(Velocity.amount(of: Parameters.named("lfo2rate")!)?.identifier == "vellfo2rate")
        #expect(Velocity.amount(of: stroke) == nil && LFOs.amount(of: Parameters.named("ring")!, lfo: 0) == nil)
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

    @Test("Programs are the prototype's and leave Octave alone")
    func programs() {
        #expect(Programs.names == ["Fanfrnoch","Molln","Khomus","Morsing","Đàn Môi","Bamboo","Genggong"])
        #expect(Programs.value(program: 2, parameter: Parameters.named("curve")!) == 2)
        #expect(Programs.value(program: 4, parameter: Parameters.named("air")!) == 30)
        #expect(Programs.value(program: 0, parameter: Parameters.named("ring")!) == 4)
        #expect(Programs.value(program: 1, parameter: Parameters.named("vowel")!) == 1050)
        #expect(Programs.value(program: 6, parameter: Parameters.named("open")!) == 100)
        #expect(fanfrnoch_program_sets(Int32(Parameters.named("octave")!.index)) == 0)
        #expect(fanfrnoch_program_sets(Int32(Parameters.named("ring")!.index)) == 1)
    }

    @Test("Values round-trip and display")
    func display() {
        let ring = Parameters.named("ring")!
        #expect(abs(ring.plain(ring.normalised(4)) - 4) < 1e-5)
        #expect(ring.label(4) == "4.00 s")
        #expect(Parameters.named("stroke")!.label(2) == "Alternate")
        #expect(Parameters.named("vowel")!.label(800) == "800 Hz")
        #expect(Parameters.named("lfo1rate")!.label(6) == "6.00 Hz")
        #expect(Parameters.named("edge")!.label(18) == "18.0")
        #expect(Parameters.named("offset")!.label(0.2) == "0.20")
        #expect(Parameters.named("body")!.label(-24) == "-24.0 dB")
        #expect(Parameters.named("damp")!.label(10) == "10 ms")
        #expect(Parameters.named("octave")!.label(1) == "+1")
        #expect(Parameters.named("sweep")!.label(-0.2) == "0 st")
    }
}
