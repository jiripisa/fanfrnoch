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

    /// The prototype's phrase, in seconds, as MIDI events (a stop of the ringing reed is a note-off).
    private static func phrase(_ score: Score) -> [GrooveEvent] {
        score.hits.map {
            GrooveEvent(Double($0.frame) / PrototypeScores.sampleRate, $0.chokeOnly ? 0x80 : 0x90, $0.note,
                        $0.chokeOnly ? 0 : $0.velocity)
        }
    }

    private static let phraseLength = PrototypeScores.phraseLength

    /// Two pads on one pitch, hit in turn.
    private static let pairEvents: [GrooveEvent] = [
        GrooveEvent(0.2, 0x90, 36, 110), GrooveEvent(0.7, 0x90, 37, 100),
        GrooveEvent(1.2, 0x90, 36, 110), GrooveEvent(1.7, 0x90, 37, 100),
    ]

    private static func setUpPair(group: Int?) -> @Sendable (Synth) -> Void {
        { synth in
            for pad in [0, 1] { synth.setPadNote(40, pad: pad); synth.setPadGroup(group, pad: pad) }
        }
    }

    private static func set(_ identifier: String, _ value: Float) -> @Sendable (Synth) -> Void {
        { synth in synth.setValue(value, of: Parameters.named(identifier)!) }
    }

    private static let scores: [Case] = [
        Case(name: "default phrase", mode: .keyboard, setup: { _ in },
              events: phrase(PrototypeScores.phrase(note: 36)), duration: phraseLength),
        Case(name: "damped phrase", mode: .keyboard, setup: { _ in },
              events: phrase(PrototypeScores.phrase(note: 36, sub: 4, chokeAhead: 0.040)), duration: phraseLength),
        Case(name: "stroke in", mode: .keyboard, setup: set("stroke", 1),
              events: phrase(PrototypeScores.phrase(note: 36)), duration: phraseLength),
        Case(name: "stroke out", mode: .keyboard, setup: set("stroke", 0),
              events: phrase(PrototypeScores.phrase(note: 36)), duration: phraseLength),
        Case(name: "default kit groove", mode: .pads, setup: { _ in },
              events: Grooves.defaultKit, duration: Grooves.defaultKitLength),
        Case(name: "pads, group off", mode: .pads, setup: setUpPair(group: nil),
              events: pairEvents, duration: 3.5),
        Case(name: "pads, one group", mode: .pads, setup: setUpPair(group: 1),
              events: pairEvents, duration: 3.5),
        Case(name: "lfo and vel", mode: .keyboard,
              setup: { synth in
                  synth.setValue(40, of: Parameters.named("lfo1vowel")!)
                  synth.setValue(50, of: Parameters.named("velring")!)
              },
              events: phrase(PrototypeScores.phrase(note: 36, sub: 4)), duration: phraseLength),
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

    /// Taken on 2026-11-16 from the engine of phase 02 (the sound engine), and taken again the same
    /// day when Air and the breath were made to fade with the reed (the tails had hissed), and once
    /// more when the breath was made to fade with the reed's level, so that a soft hit no longer
    /// clicks as it retires. A debug build and a release build rendered the same samples.
    private static let references: [Reference] = [
        Reference(score: "default phrase", sampleRate: 44100, fingerprint: 0x8D7BB69EB2AB6FB5, levels: [0.035967, 0.003146, 0.039353, 0.051399, 0.054575, 0.050981, 0.045167, 0.009028, 0.001015]),
        Reference(score: "default phrase", sampleRate: 48000, fingerprint: 0x474423ED9BA3210B, levels: [0.03597, 0.003141, 0.039421, 0.051433, 0.054635, 0.050981, 0.045127, 0.009037, 0.001024]),
        Reference(score: "default phrase", sampleRate: 96000, fingerprint: 0xA675746D576EF96B, levels: [0.03597, 0.003141, 0.03943, 0.051293, 0.054472, 0.050941, 0.04507, 0.009031, 0.001009]),
        Reference(score: "damped phrase", sampleRate: 44100, fingerprint: 0x8A14D1F922839DCA, levels: [0.035967, 0.003146, 0.040314, 0.060049, 0.065369, 0.06083, 0.058064, 0.012099, 0.001222]),
        Reference(score: "damped phrase", sampleRate: 48000, fingerprint: 0x12C326D3A4E7A248, levels: [0.03597, 0.003141, 0.040247, 0.05982, 0.065328, 0.060658, 0.058019, 0.012099, 0.001222]),
        Reference(score: "damped phrase", sampleRate: 96000, fingerprint: 0x562EB723EEA058F3, levels: [0.03597, 0.003141, 0.040249, 0.059869, 0.065186, 0.060681, 0.057918, 0.012098, 0.001225]),
        Reference(score: "stroke in", sampleRate: 44100, fingerprint: 0x1B903BFFF4B2A51E, levels: [0.037461, 0.00316, 0.039789, 0.052069, 0.055279, 0.051787, 0.046172, 0.009002, 0.001021]),
        Reference(score: "stroke in", sampleRate: 48000, fingerprint: 0x91BD4C50B7BAF453, levels: [0.037457, 0.003155, 0.039826, 0.052094, 0.055295, 0.051806, 0.046147, 0.009085, 0.001023]),
        Reference(score: "stroke in", sampleRate: 96000, fingerprint: 0xCE244B106BE33DC2, levels: [0.03746, 0.003117, 0.039828, 0.0522, 0.055434, 0.051945, 0.046295, 0.008918, 0.001025]),
        Reference(score: "stroke out", sampleRate: 44100, fingerprint: 0x290F4661111A80F, levels: [0.035967, 0.003146, 0.037855, 0.049122, 0.053069, 0.048573, 0.044552, 0.009028, 0.001015]),
        Reference(score: "stroke out", sampleRate: 48000, fingerprint: 0x95F1D51E803230D3, levels: [0.03597, 0.003141, 0.037903, 0.049047, 0.053053, 0.048569, 0.044547, 0.009037, 0.001024]),
        Reference(score: "stroke out", sampleRate: 96000, fingerprint: 0x6A983E44CD7F8D45, levels: [0.03597, 0.003141, 0.037911, 0.049162, 0.053023, 0.048592, 0.044575, 0.009031, 0.001009]),
        Reference(score: "default kit groove", sampleRate: 44100, fingerprint: 0x58C7D94ED5A465B6, levels: [0.074332, 0.09562, 0.087408, 0.08776, 0.078233, 0.083478, 0.089181, 0.08949, 0.077373, 0.058052, 0.034587, 0.009063]),
        Reference(score: "default kit groove", sampleRate: 48000, fingerprint: 0xD5CD3CE73AF00A22, levels: [0.07542, 0.095425, 0.087716, 0.088332, 0.078876, 0.084316, 0.089649, 0.088959, 0.07794, 0.058509, 0.033539, 0.009065]),
        Reference(score: "default kit groove", sampleRate: 96000, fingerprint: 0x9A3C94345AC82A52, levels: [0.074551, 0.095356, 0.087481, 0.088059, 0.078132, 0.084046, 0.088937, 0.089095, 0.078392, 0.057825, 0.034063, 0.009505]),
        Reference(score: "pads, group off", sampleRate: 44100, fingerprint: 0xC80669C3C916E772, levels: [0.043397, 0.04482, 0.003988, 0.000543]),
        Reference(score: "pads, group off", sampleRate: 48000, fingerprint: 0xD73B6C97ED47A717, levels: [0.043623, 0.044719, 0.00398, 0.000536]),
        Reference(score: "pads, group off", sampleRate: 96000, fingerprint: 0xA400BE3AB4335F4A, levels: [0.04348, 0.04463, 0.003986, 0.000536]),
        Reference(score: "pads, one group", sampleRate: 44100, fingerprint: 0xAF28ED4B9ACBD211, levels: [0.043737, 0.042389, 0.00015, 0.0]),
        Reference(score: "pads, one group", sampleRate: 48000, fingerprint: 0xBB9C9CA5C3D50A2E, levels: [0.043745, 0.042372, 0.000149, 0.0]),
        Reference(score: "pads, one group", sampleRate: 96000, fingerprint: 0x4831A442D8CDBF25, levels: [0.043741, 0.042369, 0.000148, 0.0]),
        Reference(score: "lfo and vel", sampleRate: 44100, fingerprint: 0xD64377777A787F02, levels: [0.029848, 0.001314, 0.03455, 0.047542, 0.053236, 0.045798, 0.046034, 0.004956, 8e-05]),
        Reference(score: "lfo and vel", sampleRate: 48000, fingerprint: 0xE870B23662EF01D1, levels: [0.029846, 0.001312, 0.034555, 0.047562, 0.053373, 0.045805, 0.046073, 0.004952, 8e-05]),
        Reference(score: "lfo and vel", sampleRate: 96000, fingerprint: 0x4E79D9AC94232445, levels: [0.029846, 0.001313, 0.034555, 0.047627, 0.052811, 0.045735, 0.045902, 0.004951, 8.1e-05]),
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
