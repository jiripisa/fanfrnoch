import Foundation
import Testing
@testable import FanfrnochCore

/// Renders for the author to judge by ear, written as 24-bit stereo WAV files into the directory
/// named by `FANFRNOCH_LISTEN_DIR`. Skipped when it is not set. The files carry the engine's real
/// output level (nothing is normalised); a file whose peak is above -0.5 dBFS fails the test.
@Suite("Listening renders")
struct ListeningRenders {

    private static let directory = ProcessInfo.processInfo.environment["FANFRNOCH_LISTEN_DIR"]
    private static let blockSize = 128
    private static let peakLimitDb = -0.5

    /// Something that happens `time` seconds in: a MIDI message, a knob turned.
    private struct Cue {
        let time: Double
        let action: @Sendable (Synth) -> Void
    }

    private struct Render {
        let name: String
        let sampleRate: Double
        let seconds: Double
        let mode: PlayMode
        let cues: [Cue]
    }

    private struct Rendered {
        let left: [Float]
        let right: [Float]
        var peakDb: Double {
            let peak = max(left.map { abs($0) }.max() ?? 0, right.map { abs($0) }.max() ?? 0)
            return 20 * log10(Double(peak))
        }
    }

    // MARK: Building scores

    private static func midi(_ time: Double, _ status: UInt8, _ data1: UInt8, _ data2: UInt8) -> Cue {
        Cue(time: time) { $0.postMIDI(status: status, data1: data1, data2: data2) }
    }

    private static func set(_ time: Double, _ identifier: String, _ value: Float, in set: SoundSet = .keyboard) -> Cue {
        guard let parameter = Parameters.named(identifier) else { preconditionFailure("unknown knob \(identifier)") }
        return Cue(time: time) { $0.setValue(value, of: parameter, in: set) }
    }

    private static func cues(_ events: [GrooveEvent]) -> [Cue] {
        events.map { midi($0.time, $0.status, $0.data1, $0.data2) }
    }

    /// The prototype's 112 BPM phrase on C2 as events: one hit at 0.2 s, then 16 (`sub` 2) or 32
    /// (`sub` 4) accented hits from 2.7 s. Returns the events and the groove's start and step.
    private static func phrase(sub: Int) -> (events: [GrooveEvent], start: Double, step: Double) {
        let score = PrototypeScores.phrase(note: 36, sub: sub)
        let events = score.hits.map {
            GrooveEvent(Double($0.frame) / PrototypeScores.sampleRate, 0x90, $0.note, $0.velocity)
        }
        return (events, 2.7, 60.0 / 112.0 / Double(sub))
    }

    /// `count` messages from `from` to `to` seconds, each carrying `value(progress)`, progress 0...1.
    private static func ramp(from: Double, to: Double, every interval: Double = 0.02,
                             _ make: (Double, Double) -> Cue) -> [Cue] {
        let count = Int(((to - from) / interval).rounded())
        return (0...count).map { make(from + Double($0) * interval, Double($0) / Double(count)) }
    }

    private static func bend(_ time: Double, _ position: Int) -> Cue {
        midi(time, 0xE0, UInt8(position & 0x7F), UInt8((position >> 7) & 0x7F))
    }

    // MARK: The renders

    private static var renders: [Render] {
        let phrase16 = phrase(sub: 4), phrase8 = phrase(sub: 2)
        let length = PrototypeScores.phraseLength
        var all: [Render] = []

        // 01: the default kit, pads 1-8, 4 bars at 100 BPM.
        all.append(Render(name: "01_default_kit_groove", sampleRate: 48_000, seconds: Grooves.defaultKitLength,
                          mode: .pads, cues: cues(Grooves.defaultKit)))

        // 02: Glide for the first bar of the 8ths, Step for the second.
        let bar8 = 8 * phrase8.step
        all.append(Render(name: "02_curve_step", sampleRate: 48_000, seconds: length, mode: .keyboard,
                          cues: cues(phrase8.events) + [set(phrase8.start + bar8 - 0.05, "curve", 3)]))

        // 03: the 16ths with a key release halfway between the hits; Key Up = Ring, then Damp.
        var keyUp = cues(phrase16.events)
        let times = phrase16.events.map(\.time)
        for (i, time) in times.enumerated() {
            let next = i + 1 < times.count ? times[i + 1] : time + 2 * phrase16.step
            keyUp.append(midi((time + next) / 2, 0x80, 36, 0))
        }
        keyUp[0] = midi(times[0], 0x90, 36, phrase16.events[0].data2)
        keyUp.append(midi(times[0] + 1.0, 0x80, 36, 0))
        keyUp.append(set(phrase16.start + 16 * phrase16.step - 0.05, "keyup", 1))
        all.append(Render(name: "03_keyup_damp", sampleRate: 48_000, seconds: length, mode: .keyboard, cues: keyUp))

        // 04: the 16ths with the mod wheel at 0, then rising to 127 over 2.5 s.
        let wheelStart = phrase16.start + 16 * phrase16.step
        all.append(Render(name: "04_close_by_modwheel", sampleRate: 48_000, seconds: length, mode: .keyboard,
                          cues: cues(phrase16.events) + [midi(0.1, 0xB0, 1, 0)]
                              + ramp(from: wheelStart, to: wheelStart + 2.5) { time, p in
                                  midi(time, 0xB0, 1, UInt8((p * 127).rounded()))
                              }))

        // 05: LFO 1 > Vowel at 3 Hz on long rings: off for the first hit, on from 3.2 s.
        let held: [GrooveEvent] = [GrooveEvent(0.2, 0x90, 36, 110), GrooveEvent(4.2, 0x90, 43, 100),
                                   GrooveEvent(6.6, 0x90, 36, 90)]
        all.append(Render(name: "05_lfo1_vowel_3Hz", sampleRate: 48_000, seconds: 10.5, mode: .keyboard,
                          cues: [set(0, "ring", 4), set(0, "lfo1rate", 3)] + cues(held) + [set(3.2, "lfo1vowel", 50)]))

        // 06: the kit, the first 2 bars all centre, then spread hard left, hard right and centre.
        let bar = 4 * 60.0 / 100
        let spread: [(pad: Int, pan: Float)] = [(0, 0), (2, -100), (3, 100), (4, -100), (5, 100), (6, 0), (7, 0)]
        all.append(Render(name: "06_pan_across_pads", sampleRate: 48_000, seconds: Grooves.defaultKitLength,
                          mode: .pads,
                          cues: cues(Grooves.defaultKit) + spread.map { set(0.2 + 2 * bar - 0.05, "pan", $0.pan, in: .pad($0.pad)) }))

        // 07: the 8ths ringing while the bend goes down, up and back; Bend>Vowel at its default.
        let bendStart = 3.0
        all.append(Render(name: "07_pitchbend_vowel", sampleRate: 48_000, seconds: length, mode: .keyboard,
                          cues: cues(phrase8.events)
                              + ramp(from: bendStart, to: bendStart + 1.5) { t, p in bend(t, 8192 - Int(p * 8192)) }
                              + ramp(from: bendStart + 1.5, to: bendStart + 3.0) { t, p in bend(t, Int(p * 16383)) }
                              + ramp(from: bendStart + 3.0, to: bendStart + 4.0) { t, p in bend(t, 16383 - Int(p * 8191)) }))

        // 08: the 16ths with aftertouch rising from 0 to 127 over 3.5 s.
        all.append(Render(name: "08_aftertouch_breath", sampleRate: 48_000, seconds: length, mode: .keyboard,
                          cues: cues(phrase16.events) + [midi(0.1, 0xD0, 0, 0)]
                              + ramp(from: 3.5, to: 7.0) { t, p in midi(t, 0xD0, UInt8((p * 127).rounded()), 0) }))

        // 09: the 16ths, first without velocity modulation, then VEL>Ring 60 % and VEL>Vowel 40 %.
        all.append(Render(name: "09_vel_ring_and_vowel", sampleRate: 48_000, seconds: length, mode: .keyboard,
                          cues: cues(phrase16.events)
                              + [set(phrase16.start + 16 * phrase16.step - 0.05, "velring", 60),
                                 set(phrase16.start + 16 * phrase16.step - 0.05, "velvowel", 40)]))

        // 10: one default hit at 44.1 kHz and the same at 96 kHz.
        let hit = [GrooveEvent(0.2, 0x90, 36, 110)]
        for (suffix, rate) in [("44k1", 44_100.0), ("96k", 96_000.0)] {
            all.append(Render(name: "10_default_hit_44k1_vs_96k_\(suffix)", sampleRate: rate, seconds: 6,
                              mode: .keyboard, cues: cues(hit)))
        }
        return all
    }

    // MARK: Rendering and writing

    private static func render(_ spec: Render) -> Rendered {
        let synth = Synth(sampleRate: spec.sampleRate)
        synth.mode = spec.mode
        let cues = spec.cues.sorted { $0.time < $1.time }
        let blocks = Int((spec.seconds * spec.sampleRate).rounded(.up)) / blockSize + 1
        var left = [Float](repeating: 0, count: blocks * blockSize)
        var right = left
        var next = 0
        for block in 0..<blocks {
            let time = Double(block * blockSize) / spec.sampleRate
            while next < cues.count, cues[next].time <= time {
                cues[next].action(synth)
                next += 1
            }
            left.withUnsafeMutableBufferPointer { l in
                right.withUnsafeMutableBufferPointer { r in
                    synth.render(left: l.baseAddress! + block * blockSize, right: r.baseAddress! + block * blockSize,
                                 frames: blockSize)
                }
            }
        }
        return Rendered(left: left, right: right)
    }

    /// A 24-bit PCM stereo WAV file, little-endian.
    private static func wav(_ audio: Rendered, sampleRate: Int) -> Data {
        let frames = audio.left.count
        let dataSize = frames * 6
        var data = Data()
        func append32(_ v: Int) { withUnsafeBytes(of: UInt32(v).littleEndian) { data.append(contentsOf: $0) } }
        func append16(_ v: Int) { withUnsafeBytes(of: UInt16(v).littleEndian) { data.append(contentsOf: $0) } }
        data.append(contentsOf: Array("RIFF".utf8)); append32(36 + dataSize)
        data.append(contentsOf: Array("WAVE".utf8)); data.append(contentsOf: Array("fmt ".utf8))
        append32(16); append16(1); append16(2); append32(sampleRate); append32(sampleRate * 6); append16(6); append16(24)
        data.append(contentsOf: Array("data".utf8)); append32(dataSize)
        data.reserveCapacity(44 + dataSize)
        for i in 0..<frames {
            for sample in [audio.left[i], audio.right[i]] {
                let value = Int32((min(max(sample, -1), 1) * 8_388_607).rounded())
                data.append(UInt8(truncatingIfNeeded: value))
                data.append(UInt8(truncatingIfNeeded: value >> 8))
                data.append(UInt8(truncatingIfNeeded: value >> 16))
            }
        }
        return data
    }

    @Test("Writes the listening renders", .enabled(if: ListeningRenders.directory != nil))
    func writeRenders() throws {
        let directory = URL(fileURLWithPath: try #require(Self.directory), isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let specs = Self.renders
        #expect(specs.count == 11)
        for spec in specs {
            let audio = Self.render(spec)
            let url = directory.appendingPathComponent(spec.name + ".wav")
            try Self.wav(audio, sampleRate: Int(spec.sampleRate)).write(to: url)
            print(String(format: "%@  %.1f s  peak %.2f dBFS", spec.name, Double(audio.left.count) / spec.sampleRate, audio.peakDb))
            #expect(audio.peakDb <= Self.peakLimitDb, "\(spec.name) peaks at \(audio.peakDb) dBFS")
        }
    }
}
