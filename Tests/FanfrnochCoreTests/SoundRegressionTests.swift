import Testing
@testable import FanfrnochCore

/// Guards the sound itself: the references below were taken from the engine, so a change in
/// `FanfrnochDSP` that alters a single sample fails here.
///
/// Each reference holds two things: a fingerprint of every sample, and the level of each second.
/// They tell two cases apart:
/// - levels differ: the sound really changed;
/// - only fingerprints differ, for every score at once and without a change in the engine: a new
///   compiler or macOS rounds differently.
///
/// When a change of the sound is deliberate, say so in the CHANGELOG, run the suite and copy the
/// lines it prints over `references`.
@Suite("Sound")
struct SoundRegressionTests {

    private struct Case {
        let name: String
        let mode: PlayMode
        let setup: @Sendable (Synth) -> Void
        let events: [GrooveEvent]
        let duration: Double
    }

    private static func spike(_ name: String, as title: String) -> Case {
        let render = PrototypeScores.render(named: name)
        return Case(name: title, mode: render.isPads ? .pads : .keyboard, setup: { PrototypeScores.setUp(render, in: $0) },
                    events: PrototypeScores.midiEvents(render), duration: render.seconds)
    }

    private static func set(_ values: [String: Float]) -> @Sendable (Synth) -> Void {
        { synth in for (id, value) in values { synth.setValue(value, of: Parameters.named(id)!) } }
    }

    /// Sixteenths at 120 BPM on pads 1 and 2 in turn, one group: two hands on one drum.
    private static let fastGroup: [GrooveEvent] = (0..<32).map { (i: Int) -> GrooveEvent in
        let accent: Float = i % 4 == 0 ? 1.0 : 0.7
        return GrooveEvent(0.3 + Double(i) * 0.125, 0x90, UInt8(36 + i % 2), PrototypeScores.velocity(accent))
    }

    /// The groove on B2, and a fifth above it a 16th later: two drums with Drum Many.
    private static let twoNotes: [GrooveEvent] = PrototypeScores.groove(PrototypeScores.B2).flatMap { (s: SpikeStroke) -> [GrooveEvent] in
        let low = GrooveEvent(s.time, 0x90, PrototypeScores.B2, PrototypeScores.velocity(s.accent))
        let high = GrooveEvent(s.time + 0.136, 0x90, PrototypeScores.B2 + 7, PrototypeScores.velocity(s.accent * 0.7))
        return [low, high]
    }

    private static let grooveLength = PrototypeScores.render(named: "01b_fanfrnoch_default_groove").seconds

    /// The spike's scores (instrument design §8), and a fast alternating group, a jump on every
    /// stroke, Drum Many, the default kit and the modulation amounts.
    private static let scores: [Case] = [
        spike("01a_fanfrnoch_default_pulls", as: "default pulls"),
        spike("01b_fanfrnoch_default_groove", as: "default groove"),
        spike("01c_fanfrnoch_group_like_the_recording", as: "group of three drums"),
        spike("02d_keyup_stop_note_lengths", as: "held notes, Key Up Stop"),
        spike("09c_hands_alt6_tune10", as: "two hands"),
        spike("11a_creak_40", as: "creak"),
        spike("11b_split_50", as: "split"),
        spike("12b_cuica_whoop_6.6st_80ms", as: "scoop"),
        spike("12c_cuica_samba", as: "cuica samba"),
        spike("P02_zambomba", as: "zambomba"),
        spike("P06_creak", as: "creak program"),
        spike("P07_flick", as: "flick"),
        spike("P09_kit_fanfrnoch_low_high_cuica", as: "small kit"),
        Case(name: "fast alternating group", mode: .pads,
             setup: { synth in for pad in [0, 1] { synth.setPadNote(47, pad: pad); synth.setPadGroup(1, pad: pad) } },
             events: fastGroup, duration: 5.8),
        Case(name: "jump on every stroke", mode: .keyboard,
             setup: { synth in synth.loadProgram(3, into: .keyboard); synth.setValue(100, of: Parameters.named("jump")!) },
             events: PrototypeScores.midiEvents(PrototypeScores.render(named: "P02_zambomba")), duration: grooveLength),
        Case(name: "drum many", mode: .keyboard, setup: set(["drum": 1]), events: twoNotes, duration: grooveLength),
        Case(name: "default kit groove", mode: .pads, setup: { _ in },
             events: Grooves.defaultKit, duration: Grooves.defaultKitLength),
        Case(name: "lfo and vel", mode: .keyboard, setup: set(["lfo1stick": 40, "lfo1rate": 3, "velrelease": 50]),
             events: PrototypeScores.midiEvents(PrototypeScores.render(named: "01b_fanfrnoch_default_groove")),
             duration: grooveLength),
    ]
    private static let rates = [44_100.0, 48_000.0, 96_000.0]
    private static let blockSize = 128

    private struct Reference {
        let score: String
        let sampleRate: Double
        /// FNV-1a over the bits of every sample.
        let fingerprint: UInt64
        /// RMS of each second (the last one is shorter).
        let levels: [Double]

        /// This reference as a line of `references`.
        var sourceLine: String {
            let levelList = levels.map { "\(($0 * 1_000_000).rounded() / 1_000_000)" }.joined(separator: ", ")
            return "Reference(score: \"\(score)\", sampleRate: \(Int(sampleRate)), "
                + "fingerprint: 0x\(String(fingerprint, radix: 16, uppercase: true)), levels: [\(levelList)]),"
        }
    }

    /// Taken on 2026-11-23 from the engine of phase 02 (the friction drum). A debug build and a
    /// release build rendered the same samples.
    private static let references: [Reference] = [
        Reference(score: "default pulls", sampleRate: 44100, fingerprint: 0x152AE6394B9F562A, levels: [0.13174, 0.1326, 0.112041, 0.123441, 0.114176, 2.2e-05]),
        Reference(score: "default pulls", sampleRate: 48000, fingerprint: 0xB727F199BCF59FA1, levels: [0.129423, 0.128191, 0.127741, 0.126735, 0.112354, 2.7e-05]),
        Reference(score: "default pulls", sampleRate: 96000, fingerprint: 0xB93F6D2B58F94E63, levels: [0.132249, 0.129405, 0.132786, 0.117014, 0.121111, 2.8e-05]),
        Reference(score: "default groove", sampleRate: 44100, fingerprint: 0x9A192D01E82EF1E, levels: [0.124163, 0.135569, 0.155873, 0.160743, 0.144479, 0.134239, 0.151063, 0.136355, 0.132488, 2.1e-05]),
        Reference(score: "default groove", sampleRate: 48000, fingerprint: 0x6C4E86DDBC8E892C, levels: [0.122188, 0.123393, 0.151459, 0.150315, 0.143789, 0.132726, 0.133211, 0.124532, 0.127916, 3.6e-05]),
        Reference(score: "default groove", sampleRate: 96000, fingerprint: 0x2B20D27920F0236D, levels: [0.122436, 0.128214, 0.141615, 0.154633, 0.147982, 0.131922, 0.133703, 0.123402, 0.129289, 4.2e-05]),
        Reference(score: "group of three drums", sampleRate: 44100, fingerprint: 0x6E359EACD0D6D6C3, levels: [0.126326, 0.099455, 0.118705, 0.092515, 0.128317, 0.107019, 0.127597, 0.110817, 0.1021, 0.053091, 0.0]),
        Reference(score: "group of three drums", sampleRate: 48000, fingerprint: 0xDE5D248AE10290E, levels: [0.125741, 0.099534, 0.1196, 0.092476, 0.126793, 0.098797, 0.124448, 0.123834, 0.110743, 0.055991, 0.0]),
        Reference(score: "group of three drums", sampleRate: 96000, fingerprint: 0x186B49BE794D1030, levels: [0.125749, 0.099595, 0.132003, 0.090212, 0.124756, 0.100895, 0.129842, 0.129111, 0.109516, 0.054913, 0.0]),
        Reference(score: "held notes, Key Up Stop", sampleRate: 44100, fingerprint: 0xBB0CD4A78C8DCC60, levels: [0.082957, 0.109674, 0.168366, 0.001359, 0.0]),
        Reference(score: "held notes, Key Up Stop", sampleRate: 48000, fingerprint: 0xF98978D0782E5FF3, levels: [0.088232, 0.107547, 0.153813, 0.001321, 0.0]),
        Reference(score: "held notes, Key Up Stop", sampleRate: 96000, fingerprint: 0x9CDFC7A1660B0DAF, levels: [0.091301, 0.107398, 0.156024, 0.00127, 0.0]),
        Reference(score: "two hands", sampleRate: 44100, fingerprint: 0x422E0DD13663B872, levels: [0.077924, 0.089204, 0.08227, 0.078734, 0.034749, 0.0]),
        Reference(score: "two hands", sampleRate: 48000, fingerprint: 0x4BA1E7A54F4B6D7E, levels: [0.079355, 0.082704, 0.089126, 0.083025, 0.0396, 0.0]),
        Reference(score: "two hands", sampleRate: 96000, fingerprint: 0x6E17701531166E0D, levels: [0.076159, 0.086933, 0.087974, 0.085026, 0.043826, 0.0]),
        Reference(score: "creak", sampleRate: 44100, fingerprint: 0x7280B01ECCD34627, levels: [0.086477, 0.077781, 0.075531, 0.076021, 0.082763, 3.4e-05]),
        Reference(score: "creak", sampleRate: 48000, fingerprint: 0x4388992D16E58365, levels: [0.082997, 0.079747, 0.071556, 0.074004, 0.073977, 1.2e-05]),
        Reference(score: "creak", sampleRate: 96000, fingerprint: 0xEE19E97C688B9787, levels: [0.084872, 0.081185, 0.071152, 0.082896, 0.069854, 1.3e-05]),
        Reference(score: "split", sampleRate: 44100, fingerprint: 0x822BC99A9053FED4, levels: [0.138649, 0.13577, 0.116753, 0.127086, 0.116986, 2.3e-05]),
        Reference(score: "split", sampleRate: 48000, fingerprint: 0xC21F6C6BC0C54FBA, levels: [0.134109, 0.13413, 0.131112, 0.132214, 0.117985, 2.8e-05]),
        Reference(score: "split", sampleRate: 96000, fingerprint: 0x63C73675C5095A24, levels: [0.136987, 0.13139, 0.134443, 0.120838, 0.124263, 2.8e-05]),
        Reference(score: "scoop", sampleRate: 44100, fingerprint: 0x5E594A8608082542, levels: [0.035026, 0.042399, 0.029917, 0.041171, 0.000557, 0.0]),
        Reference(score: "scoop", sampleRate: 48000, fingerprint: 0x34FAC64726230185, levels: [0.0361, 0.044652, 0.035769, 0.041559, 0.000491, 0.0]),
        Reference(score: "scoop", sampleRate: 96000, fingerprint: 0x9FAECB28B6085A71, levels: [0.036102, 0.046764, 0.03079, 0.040556, 0.000462, 0.0]),
        Reference(score: "cuica samba", sampleRate: 44100, fingerprint: 0x88EF2E710A99082, levels: [0.102403, 0.101718, 0.108039, 0.10772, 0.105518, 0.104167, 0.115895, 0.065596, 0.0]),
        Reference(score: "cuica samba", sampleRate: 48000, fingerprint: 0xAFB45F06892C6E8E, levels: [0.10616, 0.103515, 0.115665, 0.114728, 0.097529, 0.104734, 0.117563, 0.056303, 0.0]),
        Reference(score: "cuica samba", sampleRate: 96000, fingerprint: 0xBC404756A1317A85, levels: [0.106196, 0.103035, 0.119003, 0.114037, 0.095893, 0.103981, 0.11599, 0.060574, 0.0]),
        Reference(score: "zambomba", sampleRate: 44100, fingerprint: 0x11CD360C719B1C69, levels: [0.077418, 0.077968, 0.085918, 0.094659, 0.084137, 0.082107, 0.102564, 0.079021, 0.075089, 0.0]),
        Reference(score: "zambomba", sampleRate: 48000, fingerprint: 0x16664C172CD46856, levels: [0.08117, 0.066785, 0.080843, 0.084691, 0.076675, 0.083881, 0.0894, 0.070919, 0.082128, 0.0]),
        Reference(score: "zambomba", sampleRate: 96000, fingerprint: 0xB4092CFC80189DC7, levels: [0.08118, 0.076921, 0.07648, 0.0888, 0.079515, 0.081989, 0.094207, 0.066053, 0.083184, 0.0]),
        Reference(score: "creak program", sampleRate: 44100, fingerprint: 0xA3FD79D9CFDA1A3A, levels: [0.043565, 0.03675, 0.026188, 0.04635, 1e-06]),
        Reference(score: "creak program", sampleRate: 48000, fingerprint: 0x33278245985BE0DE, levels: [0.043373, 0.033263, 0.02363, 0.043268, 1e-06]),
        Reference(score: "creak program", sampleRate: 96000, fingerprint: 0x9619507A4BC11DBC, levels: [0.043434, 0.033553, 0.026514, 0.044244, 1e-06]),
        Reference(score: "flick", sampleRate: 44100, fingerprint: 0x19E584C6D4905126, levels: [0.005464, 0.007656, 0.004692, 0.005142, 0.0]),
        Reference(score: "flick", sampleRate: 48000, fingerprint: 0xB8D14A831122B2DA, levels: [0.005515, 0.006711, 0.005786, 0.005719, 0.0]),
        Reference(score: "flick", sampleRate: 96000, fingerprint: 0x6E3422DAB097E1D3, levels: [0.005574, 0.007191, 0.005889, 0.005774, 0.0]),
        Reference(score: "small kit", sampleRate: 44100, fingerprint: 0x7EFB335E8D026E6A, levels: [0.135281, 0.136281, 0.167707, 0.163468, 0.151265, 0.140437, 0.166412, 0.144175, 0.142088, 2.1e-05, 0.0]),
        Reference(score: "small kit", sampleRate: 48000, fingerprint: 0xEDA4191C2131AA7D, levels: [0.131593, 0.125059, 0.160957, 0.157706, 0.150398, 0.140421, 0.148083, 0.129803, 0.136416, 3.6e-05, 0.0]),
        Reference(score: "small kit", sampleRate: 96000, fingerprint: 0xCBF3CC6C6BB456A9, levels: [0.131857, 0.130113, 0.153057, 0.161707, 0.154269, 0.137747, 0.144301, 0.130771, 0.138178, 4.2e-05, 0.0]),
        Reference(score: "fast alternating group", sampleRate: 44100, fingerprint: 0xA5ED6E5D9A608FB8, levels: [0.150311, 0.186883, 0.178798, 0.175413, 0.097549, 0.0]),
        Reference(score: "fast alternating group", sampleRate: 48000, fingerprint: 0x194B1AFFF350FE36, levels: [0.149296, 0.183307, 0.179241, 0.177824, 0.104203, 0.0]),
        Reference(score: "fast alternating group", sampleRate: 96000, fingerprint: 0x8EBE19A8FF86B937, levels: [0.148971, 0.182018, 0.178795, 0.178642, 0.111411, 0.0]),
        Reference(score: "jump on every stroke", sampleRate: 44100, fingerprint: 0xEA787FD91243A3CB, levels: [0.091282, 0.090404, 0.105736, 0.113556, 0.094127, 0.092268, 0.113416, 0.08519, 0.08559, 0.0]),
        Reference(score: "jump on every stroke", sampleRate: 48000, fingerprint: 0xD36D8B8904D60177, levels: [0.097122, 0.077073, 0.098909, 0.103747, 0.093066, 0.094074, 0.098284, 0.077495, 0.085154, 0.0]),
        Reference(score: "jump on every stroke", sampleRate: 96000, fingerprint: 0x953C0F5924B01437, levels: [0.097137, 0.080216, 0.094692, 0.107247, 0.096902, 0.093936, 0.099753, 0.078015, 0.085831, 0.0]),
        Reference(score: "drum many", sampleRate: 44100, fingerprint: 0x242FFA290A1B2FAA, levels: [0.150064, 0.17627, 0.199959, 0.20094, 0.182954, 0.167295, 0.18416, 0.176045, 0.174973, 0.000951]),
        Reference(score: "drum many", sampleRate: 48000, fingerprint: 0x17170047C2768FD1, levels: [0.145934, 0.16332, 0.194798, 0.185249, 0.184344, 0.17203, 0.166777, 0.168096, 0.170211, 0.00105]),
        Reference(score: "drum many", sampleRate: 96000, fingerprint: 0xE69B84A00381FD1A, levels: [0.146107, 0.169783, 0.189634, 0.190383, 0.182836, 0.171151, 0.169737, 0.170101, 0.171798, 0.001041]),
        Reference(score: "default kit groove", sampleRate: 44100, fingerprint: 0x2FF1EBDEB466731D, levels: [0.146083, 0.128788, 0.168829, 0.137712, 0.134369, 0.13524, 0.13322, 0.151059, 0.143889, 0.109947, 5e-06, 0.0]),
        Reference(score: "default kit groove", sampleRate: 48000, fingerprint: 0xF56D75D144BA10A4, levels: [0.146408, 0.124874, 0.160807, 0.125797, 0.125733, 0.136057, 0.133383, 0.138022, 0.144678, 0.113718, 7e-06, 0.0]),
        Reference(score: "default kit groove", sampleRate: 96000, fingerprint: 0xEB3CEB0F3CF0FDB3, levels: [0.146185, 0.124821, 0.160632, 0.125852, 0.124852, 0.136332, 0.133409, 0.138393, 0.148678, 0.121454, 7e-06, 0.0]),
        Reference(score: "lfo and vel", sampleRate: 44100, fingerprint: 0x7EFB87B31876FC08, levels: [0.12445, 0.131799, 0.151524, 0.157658, 0.141488, 0.130426, 0.146756, 0.133796, 0.12971, 9e-06]),
        Reference(score: "lfo and vel", sampleRate: 48000, fingerprint: 0x4807798C9CF33203, levels: [0.121809, 0.120226, 0.147022, 0.147545, 0.141849, 0.130116, 0.129338, 0.121818, 0.124899, 1.6e-05]),
        Reference(score: "lfo and vel", sampleRate: 96000, fingerprint: 0xBF21335E025A1F74, levels: [0.122001, 0.125276, 0.138337, 0.150663, 0.144804, 0.128048, 0.130387, 0.120812, 0.126602, 1.9e-05]),
    ]

    private static func render(_ score: Case, sampleRate: Double) -> [Float] {
        let synth = Synth(sampleRate: sampleRate)
        synth.mode = score.mode
        score.setup(synth)
        let blocks = Int(score.duration * sampleRate) / blockSize
        var samples: [Float] = []
        samples.reserveCapacity(blocks * blockSize)
        var left = [Float](repeating: 0, count: blockSize)
        var right = [Float](repeating: 0, count: blockSize)
        var next = 0
        for block in 0..<blocks {
            let time = Double(block * blockSize) / sampleRate
            while next < score.events.count, score.events[next].time <= time {
                let event = score.events[next]
                synth.postMIDI(status: event.status, data1: event.data1, data2: event.data2)
                next += 1
            }
            left.withUnsafeMutableBufferPointer { l in
                right.withUnsafeMutableBufferPointer { r in
                    synth.render(left: l.baseAddress!, right: r.baseAddress!, frames: blockSize)
                }
            }
            samples.append(contentsOf: left)
        }
        return samples
    }

    private static func fingerprint(of samples: [Float]) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for sample in samples {
            var bits = sample.bitPattern
            for _ in 0..<4 {
                hash = (hash ^ UInt64(bits & 0xFF)) &* 0x0000_0100_0000_01B3
                bits >>= 8
            }
        }
        return hash
    }

    private static func levels(of samples: [Float], sampleRate: Double) -> [Double] {
        let second = Int(sampleRate)
        return stride(from: 0, to: samples.count, by: second).map { start in
            let window = samples[start..<min(start + second, samples.count)]
            let energy = window.reduce(0.0) { $0 + Double($1) * Double($1) }
            return (energy / Double(window.count)).squareRoot()
        }
    }

    @Test("Every score sounds as it did when its reference was taken",
          arguments: SoundRegressionTests.scores.map(\.name), SoundRegressionTests.rates)
    func unchanged(name: String, sampleRate: Double) throws {
        let score = try #require(Self.scores.first { $0.name == name })
        let samples = Self.render(score, sampleRate: sampleRate)
        #expect(samples.allSatisfy { $0.isFinite })
        let actual = Reference(score: name, sampleRate: sampleRate,
                               fingerprint: Self.fingerprint(of: samples),
                               levels: Self.levels(of: samples, sampleRate: sampleRate))
        let expected = try #require(Self.references.first { $0.score == name && $0.sampleRate == sampleRate },
                                    "no reference yet; add: \(actual.sourceLine)")

        try #require(actual.levels.count == expected.levels.count)
        for (second, (level, reference)) in zip(actual.levels, expected.levels).enumerated() {
            #expect(abs(level - reference) <= max(reference * 0.001, 0.000_001),
                    "\(name) at \(Int(sampleRate)) Hz: the level of second \(second) changed from \(reference) to \(level)")
        }
        #expect(actual.fingerprint == expected.fingerprint,
                "\(name) at \(Int(sampleRate)) Hz no longer renders the same samples; now: \(actual.sourceLine)")
    }
}
