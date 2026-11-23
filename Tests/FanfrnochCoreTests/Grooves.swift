/// One MIDI message of a score, `time` seconds after its start.
struct GrooveEvent {
    let time: Double
    let status: UInt8
    let data1: UInt8
    let data2: UInt8

    init(_ time: Double, _ status: UInt8, _ data1: UInt8, _ data2: UInt8) {
        self.time = time
        self.status = status
        self.data1 = data1
        self.data2 = data2
    }
}

/// Scores the tests and the listening renders share.
enum Grooves {

    /// The velocity byte of an accent (0...1).
    static func velocity(_ accent: Float) -> UInt8 { UInt8((accent * 127).rounded()) }

    /// The default kit, pads 1-8, 4 bars at 100 BPM: the prototype's kit score (pad 1 on beats 1
    /// and 3, pad 4 on the offbeat 8ths, pad 5 on beats 2 and 4, pad 3 as ghost 16ths) with pad 6
    /// on the last 16th of beat 4, pad 7 on the "and" of beat 2 and pad 8 on bar 4's first beat.
    /// A pad is hit by the note 36 + its index.
    static let defaultKit: [GrooveEvent] = {
        let beat = 60.0 / 100.0, eighth = beat / 2, sixteenth = beat / 4
        var events: [GrooveEvent] = []
        func hit(_ time: Double, pad: Int, _ accent: Float) {
            events.append(GrooveEvent(time, 0x90, UInt8(36 + pad), velocity(accent)))
        }
        for bar in 0..<4 {
            let start = 0.2 + Double(bar) * 4 * beat
            for b in [0, 2] { hit(start + Double(b) * beat, pad: 0, 1.0) }
            for b in 0..<4 { hit(start + Double(b) * beat + eighth, pad: 3, 0.6) }
            for b in [1, 3] { hit(start + Double(b) * beat, pad: 4, 0.9) }
            for i in 0..<16 where i % 4 == 3 { hit(start + Double(i) * sixteenth, pad: 2, 0.45) }
            hit(start + 3 * beat + 3 * sixteenth, pad: 5, 0.5)
            hit(start + beat + eighth, pad: 6, 0.7)
            if bar == 3 { hit(start, pad: 7, 0.8) }
        }
        return events.sorted { $0.time < $1.time }
    }()

    /// The kit's length: the last bar and a 2 s tail.
    static let defaultKitLength = 0.2 + 16 * 60.0 / 100 + 2.0
}
